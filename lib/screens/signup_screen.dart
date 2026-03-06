import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: height * 0.18,
                    child: Image.asset(
                      "assets/images/login_image.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create Account 🎉',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join us to track your coding progress',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ERROR MESSAGE
                  if (auth.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        auth.error!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // NAME FIELD
                  _buildTextField(
                    controller: nameController,
                    hint: "Enter your full name",
                    icon: Icons.person_outlined,
                  ),
                  const SizedBox(height: 16),

                  // EMAIL FIELD
                  _buildTextField(
                    controller: emailController,
                    hint: "Enter your email",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),

                  // PASSWORD FIELD
                  _buildTextField(
                    controller: passwordController,
                    hint: "Enter password (min 6 characters)",
                    icon: Icons.lock_outlined,
                    isPassword: true,
                    obscureText: obscurePassword,
                    onVisibilityToggle: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // CONFIRM PASSWORD FIELD
                  _buildTextField(
                    controller: confirmPasswordController,
                    hint: "Confirm your password",
                    icon: Icons.lock_outlined,
                    isPassword: true,
                    obscureText: obscureConfirmPassword,
                    onVisibilityToggle: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // TERMS & CONDITIONS
                  Row(
                    children: [
                      Checkbox(
                        value: agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                      Expanded(
                        child: Text(
                          "I agree to Terms & Conditions",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SIGNUP BUTTON
                  ElevatedButton(
                    onPressed: auth.isLoading || !agreeToTerms
                        ? null
                        : () {
                            _handleSignup(context, auth);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Create Account",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(height: 25),

                  // DIVIDER
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: theme.colorScheme.outlineVariant),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text("or", style: theme.textTheme.bodySmall),
                      ),
                      Expanded(
                        child: Divider(color: theme.colorScheme.outlineVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // GOOGLE BUTTON
                  OutlinedButton.icon(
                    onPressed: auth.isLoading
                        ? null
                        : () {
                            auth.signInWithGoogle();
                          },
                    icon: Icon(
                      Icons.g_mobiledata,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    label: Text(
                      "Continue with Google",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // SIGN IN LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: theme.textTheme.bodySmall,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Sign In",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignup(BuildContext context, AuthProvider auth) {
    // Validate inputs
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password length
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password match
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Proceed with signup
    auth.signUp(
      emailController.text.trim(),
      passwordController.text.trim(),
      nameController.text.trim(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onVisibilityToggle,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
