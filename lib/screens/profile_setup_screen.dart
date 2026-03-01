import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final leetcodeCtrl = TextEditingController();
  final codechefCtrl = TextEditingController();
  final codeforcesCtrl = TextEditingController();
  final githubCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    leetcodeCtrl.dispose();
    codechefCtrl.dispose();
    codeforcesCtrl.dispose();
    githubCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.read<ProfileProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Gradient Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.code, size: 50, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Setup Coding Profile",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: leetcodeCtrl,
                            label: "LeetCode Username",
                            icon: Icons.code,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: codechefCtrl,
                            label: "CodeChef Username",
                            icon: Icons.restaurant_menu,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: codeforcesCtrl,
                            label: "CodeForces Username",
                            icon: Icons.emoji_events,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: githubCtrl,
                            label: "GitHub Username",
                            icon: Icons.account_tree,
                          ),
                          const SizedBox(height: 30),

                          // Modern Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.primary,
                              foregroundColor:
                                  theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize:
                                  const Size(double.infinity, 55),
                              elevation: 6,
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                profileProvider.saveProfile(
                                  leetcode:
                                      leetcodeCtrl.text.trim(),
                                  codechef:
                                      codechefCtrl.text.trim(),
                                  codeforces:
                                      codeforcesCtrl.text.trim(),
                                  github:
                                      githubCtrl.text.trim(),
                                );

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Profile Saved Successfully 🚀"),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "Save & Continue",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      validator: (value) =>
          value == null || value.isEmpty ? "Required field" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHigh,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}