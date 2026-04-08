// lib/services/topic_classifier_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';

class TopicClassifierService {
  static const String _storageKey = 'topic_classification_cache';
  
  // Option A: Prefilled mapping for common problems to ensure accuracy
  static const Map<String, List<String>> _manualMapping = {
    // DP
    'House Robber': ['Dynamic Programming', 'Array'],
    'House Robber II': ['Dynamic Programming', 'Array'],
    'Word Break': ['Dynamic Programming', 'Trie'],
    'Climbing Stairs': ['Dynamic Programming', 'Math'],
    'Coin Change': ['Dynamic Programming', 'Greedy'],
    'Longest Increasing Subsequence': ['Dynamic Programming', 'Array'],
    'Edit Distance': ['Dynamic Programming', 'String'],
    'Unique Paths': ['Dynamic Programming', 'Matrix'],
    'Decode Ways': ['Dynamic Programming', 'String'],
    
    // Arrays & Hashing
    'Two Sum': ['Array', 'Hash Table'],
    'Two Sum II': ['Array', 'Two Pointers'],
    'Contains Duplicate': ['Array', 'Hash Table'],
    'Valid Anagram': ['String', 'Hash Table'],
    'Group Anagrams': ['Array', 'Hash Table', 'String'],
    'Top K Frequent Elements': ['Array', 'Hash Table', 'Heap'],
    'Product of Array Except Self': ['Array'],
    
    // Two Pointers & Sliding Window
    'Valid Palindrome': ['String', 'Two Pointers'],
    '3Sum': ['Array', 'Two Pointers'],
    'Container With Most Water': ['Array', 'Two Pointers'],
    'Longest Substring Without Repeating Characters': ['String', 'Sliding Window'],
    'Minimum Window Substring': ['String', 'Sliding Window'],
    
    // Graphs
    'Course Schedule': ['Graph', 'Topological Sort'],
    'Course Schedule II': ['Graph', 'Topological Sort'],
    'Number of Islands': ['Graph', 'BFS/DFS'],
    'Pacific Atlantic Water Flow': ['Graph', 'BFS/DFS'],
    'Clone Graph': ['Graph', 'BFS/DFS'],
    'Network Delay Time': ['Graph', 'Dijkstra'],
    
    // Trees
    'Lowest Common Ancestor': ['Tree', 'Recursion'],
    'Binary Tree Level Order Traversal': ['Tree', 'BFS'],
    'Invert Binary Tree': ['Tree', 'Recursion'],
    'Maximum Depth of Binary Tree': ['Tree', 'Recursion'],
    'Serialize and Deserialize Binary Tree': ['Tree', 'Design'],
    
    // Lists
    'Reverse Linked List': ['Linked List'],
    'Merge Two Sorted Lists': ['Linked List'],
    'Linked List Cycle': ['Linked List', 'Two Pointers'],
    'Merge K Sorted Lists': ['Sorting', 'Heap', 'Linked List'],
    'Copy List with Random Pointer': ['Linked List', 'Hash Table'],
  };

  static Map<String, List<String>> _cache = {};

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        _cache = decoded.map((k, v) => MapEntry(k, List<String>.from(v)));
      }
    } catch (e) {
      debugPrint('[TopicClassifier] Init error: $e');
    }
  }

  static Future<List<String>> classify(String problemTitle) async {
    // 1. Check manual mapping (highest priority)
    if (_manualMapping.containsKey(problemTitle)) {
      return _manualMapping[problemTitle]!;
    }

    // 2. Check cache
    if (_cache.containsKey(problemTitle)) {
      return _cache[problemTitle]!;
    }

    // 3. AI Fallback (Option B)
    try {
      final topics = await AIService.classifyProblem(problemTitle);
      _cache[problemTitle] = topics;
      await _saveCache();
      return topics;
    } catch (e) {
      return ['General'];
    }
  }

  static Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_cache));
    } catch (e) {
      debugPrint('[TopicClassifier] Save error: $e');
    }
  }
}
