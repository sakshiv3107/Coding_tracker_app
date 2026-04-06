import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'profile_setup_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms of Service to continue'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      _nameCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const ProfileSetupScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: 400.ms,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => auth.isNewUser
              ? const ProfileSetupScreen()
              : const _HomeRedirect(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: 400.ms,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // ── Background Gradients ──


            SafeArea(
              child: Column(
                children: [
                  // ── Navigation Bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.05),
                            padding: const EdgeInsets.all(12),
                          ),
                        ).animate().fadeIn().slideX(begin: -0.2),
                        const Spacer(),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: const AuthHeroLogo().animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8))),
                            const SizedBox(height: 32),
                            Text('Join the Network', 
                              style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1)
                            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                            const SizedBox(height: 8),
                            Text('Start your journey to elite coding performance', 
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15)
                            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                            const SizedBox(height: 32),

                            // ── Glass Form Card ──
                            ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (auth.error != null)
                                        AuthErrorBanner(message: auth.error!).animate().shake().fadeIn(),
                                      if (auth.error != null) const SizedBox(height: 20),

                                      _buildField(
                                        controller: _nameCtrl,
                                        hint: 'Full Name',
                                        icon: Icons.person_rounded,
                                        validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildField(
                                        controller: _emailCtrl,
                                        hint: 'Email Address',
                                        icon: Icons.alternate_email_rounded,
                                        validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildPasswordField(
                                        controller: _passwordCtrl,
                                        obscure: _obscurePassword,
                                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                                        validator: (v) => (v != null && v.length < 6) ? 'Min 6 characters' : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildPasswordField(
                                        controller: _confirmCtrl,
                                        obscure: _obscureConfirm,
                                        hint: 'Verify Password',
                                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                        validator: (v) => (v != _passwordCtrl.text) ? 'Passwords match fail' : null,
                                      ),
                                      
                                      const SizedBox(height: 24),

                                      // ── Terms ──
                                      GestureDetector(
                                        onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                                        child: Row(
                                          children: [
                                            AnimatedContainer(
                                              duration: 200.ms,
                                              width: 22, height: 22,
                                              decoration: BoxDecoration(
                                                color: _agreeToTerms ? AppTheme.primary : Colors.transparent,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: _agreeToTerms ? AppTheme.primary : Colors.white.withOpacity(0.35)),
                                              ),
                                              child: _agreeToTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text('Accept Terms of Service', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 32),

                                      _PressEffect(
                                        onTap: auth.isLoading ? null : _handleSignup,
                                        child: AuthGradientButton(
                                          label: auth.isLoading ? 'Processing...' : 'Create Account',
                                          icon: auth.isLoading ? null : Icons.shield_rounded,
                                          isLoading: auth.isLoading,
                                          onTap: null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 300.ms, duration: 800.ms).slideY(begin: 0.1),

                            const SizedBox(height: 32),
                            const AuthOrDivider().animate().fadeIn(delay: 500.ms),
                            const SizedBox(height: 24),

                            _PressEffect(
                              onTap: auth.isLoading ? null : _handleGoogleSignUp,
                              child: _GoogleSignupButton(isLoading: auth.isLoading),
                            ).animate().fadeIn(delay: 600.ms),

                            const SizedBox(height: 48),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    children: const [
                                      TextSpan(text: 'Already registered? '),
                                      TextSpan(text: 'Sign In', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 800.ms),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String hint, required IconData icon, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, size: 20, color: Colors.white.withOpacity(0.4)),
        filled: true, fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.06))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required bool obscure, required VoidCallback onToggle, required String? Function(String?) validator, String hint = '••••••••'}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(Icons.lock_rounded, size: 20, color: Colors.white.withOpacity(0.4)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: Colors.white.withOpacity(0.4)),
          onPressed: onToggle,
        ),
        filled: true, fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.06))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

// class _BlurCircle extends StatelessWidget {
//   final Color color;
//   final double size;
//   const _BlurCircle({required this.color, required this.size});
//   @override
//   Widget build(BuildContext context) {
//     return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)).animate().fadeIn(duration: 1200.ms).scale();
//   }
// }

class _PressEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressEffect({required this.child, this.onTap});
  @override
  State<_PressEffect> createState() => _PressEffectState();
}

class _PressEffectState extends State<_PressEffect> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _pressed ? 0.97 : 1.0, duration: 100.ms, child: widget.child),
    );
  }
}

class _GoogleSignupButton extends StatelessWidget {
  final bool isLoading;
  const _GoogleSignupButton({required this.isLoading});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthGoogleIcon(),
          SizedBox(width: 14),
          Text('Sync with Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

class _HomeRedirect extends StatefulWidget {
  const _HomeRedirect();
  @override
  State<_HomeRedirect> createState() => _HomeRedirectState();
}

class _HomeRedirectState extends State<_HomeRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}