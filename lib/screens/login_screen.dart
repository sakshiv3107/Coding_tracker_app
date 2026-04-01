import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'signup_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  // bool _rememberMe = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _navigateAfterAuth(isNewUser: false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      _navigateAfterAuth(isNewUser: auth.isNewUser);
    }
  }

  void _navigateAfterAuth({required bool isNewUser}) {
    if (isNewUser) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ProfileSetupScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final sheetFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Form(
              key: sheetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Reset Identity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Enter your email to receive a recovery link.", style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  const SizedBox(height: 24),
                  _buildField(controller: emailCtrl, hint: 'email@example.com', icon: Icons.email_outlined),
                  const SizedBox(height: 24),
                  AuthGradientButton(
                    label: 'Send Recovery Link',
                    icon: Icons.send_rounded,
                    onTap: () async {
                      if (!sheetFormKey.currentState!.validate()) return;
                      final email = emailCtrl.text.trim();
                      Navigator.pop(ctx);
                      final auth = context.read<AuthProvider>();
                      final ok = await auth.resetPassword(email);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? '✅ Link sent to $email.' : '❌ Failed: ${auth.error ?? "Unknown error"}'),
                          backgroundColor: ok ? AppTheme.secondary : Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo().animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutBack),
                        const SizedBox(height: 32),
                        Column(
                          children: [
                            Text('CodeSphere', style: GoogleFonts.outfit(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1)),
                            const SizedBox(height: 8),
                            Text('Master your data-driven coding career', style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 0.5)),
                          ],
                        ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideY(begin: 0.1),
                        const SizedBox(height: 48),

                        // ── Glass Card ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (auth.error != null)
                                    AuthErrorBanner(message: auth.error!).animate().shake().fadeIn(),
                                  if (auth.error != null) const SizedBox(height: 20),

                                  _buildField(
                                    controller: _emailCtrl,
                                    hint: 'developer@codesphere.com',
                                    icon: Icons.alternate_email_rounded,
                                    validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildPasswordField(),
                                  const SizedBox(height: 32),

                                  _PressEffect(
                                    onTap: auth.isLoading ? null : _handleLogin,
                                    child: AuthGradientButton(
                                      label: auth.isLoading ? 'Verifying...' : 'Sign In',
                                      icon: auth.isLoading ? null : Icons.bolt_rounded,
                                      isLoading: auth.isLoading,
                                      onTap: null, 
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 1000.ms).slideY(begin: 0.05),

                        const SizedBox(height: 32),
                        const AuthOrDivider().animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 24),

                        _PressEffect(
                          onTap: auth.isLoading ? null : _handleGoogleSignIn,
                          child: _GoogleButton(isLoading: auth.isLoading),
                        ).animate().fadeIn(delay: 700.ms),

                        const SizedBox(height: 48),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("New to the network? ", style: TextStyle(color: Colors.white.withOpacity(0.4))),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                              child: const Text('Initialize Account', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ).animate().fadeIn(delay: 900.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 110, width: 110,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.15), blurRadius: 40, spreadRadius: 10)],
      ),
      child: Image.asset('assets/images/icon.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.code_rounded, color: Colors.white, size: 50)),
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

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(Icons.lock_rounded, size: 20, color: Colors.white.withOpacity(0.4)),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: Colors.white.withOpacity(0.4)),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
//     return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)).animate().fadeIn(duration: 1000.ms).scale();
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

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  const _GoogleButton({required this.isLoading});
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