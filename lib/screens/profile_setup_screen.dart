import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final nameCtrl = TextEditingController();
  final leetcodeCtrl = TextEditingController();
  final codechefCtrl = TextEditingController();
  final codeforcesCtrl = TextEditingController();
  final githubCtrl = TextEditingController();
  final hackerrankCtrl = TextEditingController();


  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameCtrl.dispose();
    leetcodeCtrl.dispose();
    codechefCtrl.dispose();
    codeforcesCtrl.dispose();
    githubCtrl.dispose();
    hackerrankCtrl.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─── Header & Avatar ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                  ),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Setup Coding Profile",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  
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
                          // ERROR MESSAGE
                          if (profileProvider.error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                profileProvider.error!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          _buildInputField(
                            controller: nameCtrl,
                            label: "Full Name",
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 20),
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
                            required: false,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: codeforcesCtrl,
                            label: "CodeForces Username",
                            icon: Icons.emoji_events,
                            required: false,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: githubCtrl,
                            label: "GitHub Username",
                            icon: Icons.account_tree,
                            required: false,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: hackerrankCtrl,
                            label: "HackerRank Username",
                            icon: Icons.code_rounded,
                            required: false,
                          ),
                          const SizedBox(height: 30),

                          // Modern Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize: const Size(double.infinity, 55),
                              
                            ),
                            onPressed: profileProvider.isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      final nav = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );

                                      await profileProvider.saveProfile(
                                        name: nameCtrl.text.trim(),
                                        profilePic: null,
                                        leetcode: leetcodeCtrl.text.trim(),
                                        codechef: codechefCtrl.text.trim(),
                                        codeforces: codeforcesCtrl.text.trim(),
                                        github: githubCtrl.text.trim(),
                                        hackerrank: hackerrankCtrl.text.trim(),
                                      );

                                      // Guard against async widget disposal
                                      if (!mounted) return;

                                      if (profileProvider.error == null &&
                                          profileProvider.isProfileCompleted) {
                                        // ── Explicit navigation ────────────
                                        // Do NOT rely on AuthWrapper auto-
                                        // redirect — push HomeScreen directly
                                        // and wipe the back-stack so the user
                                        // cannot navigate back to this screen.
                                        nav.pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (_) => const HomeScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      } else if (profileProvider.error !=
                                          null) {
                                        // Show error feedback
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Error saving profile: ${profileProvider.error}",
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: profileProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
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
    bool required = true,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      validator: (value) => required && (value == null || value.isEmpty)
          ? "Required field"
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}


