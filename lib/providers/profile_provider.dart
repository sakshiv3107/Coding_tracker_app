import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, String>? profile;

  bool get isProfileCompleted => profile != null;

  void saveProfile({
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
  }) {
    profile = {
      "leetcode": leetcode,
      "codechef": codechef,
      "codeforces": codeforces,
      "github": github,
    };
    notifyListeners();
  }

  void clearProfile() {
    profile = null;
    notifyListeners();
  }
}
