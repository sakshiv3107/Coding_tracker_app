import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'home/home_screen.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';

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
    
    // Add artificial delay for splash screen visibility to ensure "Wow" factor
    await Future.wait([
      auth.checkLoginStatus(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);
    
    if (auth.user != null) {
      _profileLoaded = true;
      await profile.initializeProfile();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    if (auth.user != null && !_profileLoaded) {
      _profileLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) profile.initializeProfile();
      });
    }

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen(message: 'Connecting to terminal...');
        }

        final auth = context.watch<AuthProvider>();
        final profile = context.watch<ProfileProvider>();

        if (auth.user == null) {
          _profileLoaded = false;
          return const LoginScreen();
        }

        if (profile.isLoading && !_profileLoaded) {
          return const _SplashScreen(message: 'Syncing profile data...');
        }

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
      backgroundColor: const Color(0xFF020617), // Deeper dark background for loading
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo Container with Pulse ──
            Container(
              height: 120, width: 120,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.code_rounded, color: Colors.white, size: 48),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2))
             .scale(duration: 1500.ms, begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), curve: Curves.easeInOut),

            const SizedBox(height: 40),

            // ── Tech Typography ──
            Text(
              'CodeSphere',
              style: GoogleFonts.outfit(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),

            const SizedBox(height: 12),

            // ── Message Sequence ──
            Text(
              message.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 64),

            // ── Modern Loader ──
            Container(
              width: 180,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat())
                     .moveX(duration: 1200.ms, begin: -180, end: 180),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 800.ms),
            
            const SizedBox(height: 100),
            
            // ── Identity Footer ──
            Text(
              "POWERING DEVELOPER INSIGHTS",
              style: TextStyle(
                color: Colors.white.withOpacity(0.15),
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}
