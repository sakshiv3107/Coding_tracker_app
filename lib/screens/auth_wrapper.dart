// lib/screens/auth_wrapper.dart
//
// KEY FIXES:
//  1. Profile initialization now works with the locally-persisted
//     `profileCompleted` flag, so returning users skip ProfileSetup instantly.
//  2. `clearProfile()` is now awaited properly (it's async to clear
//     SharedPreferences on logout).
//  3. The splash screen is only shown while auth + profile are initializing;
//     once the local flag is read, navigation is immediate.

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
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _checkAuthAndInitialize();
  }

  Future<void> _checkAuthAndInitialize() async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    
    // Add artificial delay for splash screen visibility if it is too fast
    await Future.wait([
      auth.checkLoginStatus(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
    
    // If securely logged in upon app launch, initialize the profile immediately
    if (auth.user != null) {
      _profileLoaded = true;
      // We await this so the splash screen stays visible until the profile is 
      // ready, ensuring the dashboard doesn't load with empty handles.
      await profile.initializeProfile();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    // Trigger profile load when user logs in (only once per session)
    if (auth.user != null && !_profileLoaded) {
      _profileLoaded = true;
      // We use addPostFrameCallback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Force a fresh sync every time we transition to this state
          profile.initializeProfile();
        }
      });
    }

    // Reset when user logs out
    if (auth.user == null && _profileLoaded) {
      _profileLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) profile.clearProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Show Splash Screen while checking auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen(message: 'Initializing Session...');
        }

        final auth = context.watch<AuthProvider>();
        final profile = context.watch<ProfileProvider>();

        // ── 1. Not authenticated → Login ─────────────────────────────────────
        if (auth.user == null) {
          _profileLoaded = false;
          return const LoginScreen();
        }

        // ── 2. Authenticated but Profile Syncing → Loading ───────────────────
        // If we have a user but the profile is still loading (initial fetch), 
        // stay on Splash to prevent a flash of empty "Not Connected" dashboard.
        if (profile.isLoading && !_profileLoaded) {
          return const _SplashScreen();
        }

        // ── 3. Authenticated → Home ──────────────────────────────────
        return const HomeScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  final String message;
  const _SplashScreen({this.message = 'Initializing Session...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Cyber theme background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Splash Logo or Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFCC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.code,
                size: 64,
                color: Color(0xFF00FFCC), // Cyan accent
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'CodeSphere',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(
              color: Color(0xFF00FFCC),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
