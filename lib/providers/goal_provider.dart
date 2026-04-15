import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';

class GoalProvider with ChangeNotifier {
  static const String _kGoalsKey = 'user_dynamic_goals';
  List<Goal> _goals = [];
  bool _isInit = false;
  StreamSubscription? _authSubscription;

  List<Goal> get goals => _goals;
  bool get isInit => _isInit;

  void init() {
    // Initial local load to ensure UI paints quickly
    _loadFromDisk().then((_) {
       // After disk load, start listening to auth state to load from cloud
       _setupAuthListener();
    });
  }

  void _setupAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // Logged in, pull from firestore
        _syncFromFirestore(user.uid);
      } else {
        // Logged out, clear goals
        _goals.clear();
        _saveToDisk(); // clear cached data
        notifyListeners();
      }
    });
  }

  Future<void> _syncFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('goals')) {
          final List rawGoals = data['goals'];
          _goals = rawGoals.map((g) => Goal.fromJson(Map<String, dynamic>.from(g))).toList();
          _saveToDisk(); // Backup locally
          _isInit = true;
          notifyListeners();
          return;
        }
      }
      
      // ── No goals in Firestore ──────────────────────────────────────────────
      // Maybe we have local goals from a previous session that should be synced up.
      if (_goals.isNotEmpty) {
        _syncToFirestore(); // Push existing local goals to cloud.
      } else {
        // Brand-new user: ensure any stale SharedPreferences data is wiped
        // so a previous account's cached goals never appear for this user.
        _goals = [];
        await _saveToDisk(); // Write empty list to disk.
      }
      _isInit = true;
      notifyListeners();
      
    } catch (e) {
      debugPrint("GoalProvider firestore sync exception: $e");
    }
  }

  Future<void> _syncToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final list = _goals.map((g) => g.toJson()).toList();
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'goals': list,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("GoalProvider firestore save exception: $e");
    }
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_kGoalsKey);
      if (str != null) {
        final List list = jsonDecode(str);
        _goals = list.map((e) => Goal.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("GoalProvider load exception: $e");
    }
    _isInit = true;
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _goals.map((g) => g.toJson()).toList();
      await prefs.setString(_kGoalsKey, jsonEncode(list));
    } catch (e) {
       debugPrint("GoalProvider save exception: $e");
    }
  }

  void addGoal(Goal goal) {
    _goals.add(goal);
    _saveToDisk();
    _syncToFirestore();
    notifyListeners();
  }

  void updateGoal(Goal updatedGoal) {
    final index = _goals.indexWhere((g) => g.id == updatedGoal.id);
    if (index != -1) {
      _goals[index] = updatedGoal;
      _saveToDisk();
      _syncToFirestore();
      notifyListeners();
    }
  }

  void checkProgressAndNotifyCompletion(StatsProvider stats, GithubProvider github) {
    // Notification logic removed
  }

  final Set<String> _completedNotified = {};

  void deleteGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
    _completedNotified.remove(id);
    _saveToDisk();
    _syncToFirestore();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}


