import 'package:flutter/material.dart';

class UserPlatformData {
  final String platformName;
  final String username;
  final int solvedCount;
  final int? rating;
  final String? ranking;
  final bool isConnected;
  final IconData icon;
  final Color color;
  final String? profileUrl;

  UserPlatformData({
    required this.platformName,
    required this.username,
    required this.solvedCount,
    this.rating,
    this.ranking,
    required this.isConnected,
    required this.icon,
    required this.color,
    this.profileUrl,
  });

  factory UserPlatformData.empty(String platform, IconData icon, Color color) {
    return UserPlatformData(
      platformName: platform,
      username: 'Not Connected',
      solvedCount: 0,
      isConnected: false,
      icon: icon,
      color: color,
    );
  }
}
