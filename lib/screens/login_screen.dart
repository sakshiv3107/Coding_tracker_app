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
          pageBuilder: (_, _, _) => const ProfileSetupScreen(),
          transitionsBuilder: (_, anim, _, child) =>
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
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () => _showForgotPasswordDialog(context),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: AppTheme.primaryLight.withOpacity(0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  _PressEffect(
                                    onTap: auth.isLoading ? null : _handleLogin,
                                    child: AuthGradientButton(
                                      label: auth.isLoading ? 'Verifying...' : 'Sign In',
                                      icon: auth.isLoading ? null : Icons.bolt_rounded,
                                      isLoading: auth.isLoading,
                                      onTap: auth.isLoading ? null : _handleLogin, 
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
                          child: AuthSocialButton(
                            label: 'Continue with Google',
                            icon: const AuthGoogleIcon(),
                            isLoading: auth.isLoading,
                            onTap: auth.isLoading ? null : _handleGoogleSignIn,
                          ),
                        ).animate().fadeIn(delay: 700.ms),

                        const SizedBox(height: 48),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("New to the network? ", style: TextStyle(color: Colors.white.withOpacity(0.4))),
                            GestureDetector(
                               onTap: () {
                                 context.read<AuthProvider>().clearError();
                                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                               },
                               child: Text('Initialize Account', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
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
    return SizedBox(
      height: 100, width: 100,
      child: Image.asset(
        'assets/images/icon.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.code_rounded, color: Colors.white, size: 50),
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppTheme.primaryLight, width: 1.5)),
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppTheme.primaryLight, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final auth = context.watch<AuthProvider>();
            
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                title: Text('Reset Password', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enter your email address and we will send you a link to reset your password.',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: emailCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email Address',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          prefixIcon: Icon(Icons.alternate_email_rounded, size: 20, color: Colors.white.withOpacity(0.4)),
                          filled: true, fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.06))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.primaryLight)),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Text(auth.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ]
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      auth.clearError();
                      Navigator.pop(context);
                    },
                    child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : () async {
                      if (formKey.currentState!.validate()) {
                        final success = await auth.resetPassword(emailCtrl.text.trim());
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Password reset link sent to your email(Check spam folder if not found)'),
                              backgroundColor: AppTheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: auth.isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send Link'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clear any errors that might have been shown in the dialog
      if (context.mounted) {
        context.read<AuthProvider>().clearError();
      }
    });
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


