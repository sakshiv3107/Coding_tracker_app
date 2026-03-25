import 'package:coding_tracker_app/screens/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'home/home_screen.dart';
import '../providers/profile_provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _profileLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    // Trigger profile load when user logs in (only once per session)
    if (auth.user != null && !_profileLoaded && !profile.isLoading) {
      _profileLoaded = true;
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) profile.initializeProfile();
      });
    }

    // Reset when user logs out
    if (auth.user == null && _profileLoaded) {
      _profileLoaded = false;
      // Also clear profile data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) profile.clearProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();

    // Show loading screen while profile is being loaded
    if (auth.user != null && profile.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4E8B7C)),
              SizedBox(height: 24),
              Text(
                'Initializing CodeSphere...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Navigation logic
    if (auth.user == null) {
      return const LoginScreen();
    }

    if (!profile.isProfileCompleted) {
      return const ProfileSetupScreen();
    }

    return const HomeScreen();
  }
}
