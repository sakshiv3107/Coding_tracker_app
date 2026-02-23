import 'package:coding_tracker_app/screens/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'home/home_screen.dart';
import '../providers/profile_provider.dart';

// import 'package:coding_tracker_app/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();

    if (auth.user == null) {
      return const LoginScreen();
    }
    if (!profile.isProfileCompleted) {
      return const ProfileSetupScreen();
    }
    return const HomeScreen();
  }
}
