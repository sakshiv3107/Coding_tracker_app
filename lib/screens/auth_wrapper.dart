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
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();

    // If user is authenticated and profile hasn't been loaded yet, load it
    if (auth.user != null && !_profileLoaded && !profile.isLoading) {
      _profileLoaded = true;
      Future.microtask(() {
        profile.initializeProfile();
      });
    }

    // Reset profile loaded flag when user logs out
    if (auth.user == null && _profileLoaded) {
      _profileLoaded = false;
      profile.clearProfile();
    }

    // Show loading screen while profile is being loaded
    if (auth.user != null && profile.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading your profile...',
                style: Theme.of(context).textTheme.bodyMedium,
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
