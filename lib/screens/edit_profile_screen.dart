import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _leetcodeController;
  late TextEditingController _codechefController;
  late TextEditingController _codeforcesController;
  late TextEditingController _githubController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    _nameController = TextEditingController(text: auth.user?["name"] ?? "");
    _leetcodeController = TextEditingController(text: profile.profile?["leetcode"] ?? "");
    _codechefController = TextEditingController(text: profile.profile?["codechef"] ?? "");
    _codeforcesController = TextEditingController(text: profile.profile?["codeforces"] ?? "");
    _githubController = TextEditingController(text: profile.profile?["github"] ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _leetcodeController.dispose();
    _codechefController.dispose();
    _codeforcesController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();

    final name = _nameController.text.trim();
    final leetcode = _leetcodeController.text.trim();
    final codechef = _codechefController.text.trim();
    final codeforces = _codeforcesController.text.trim();
    final github = _githubController.text.trim();

    await profileProvider.updateFullProfile(
      name: name,
      leetcode: leetcode,
      codechef: codechef,
      codeforces: codeforces,
      github: github,
    );

    if (profileProvider.error == null) {
      authProvider.updateName(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${profileProvider.error}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<ProfileProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryMint,
                  ),
                ),
                const SizedBox(height: 16),
                ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Platform Usernames',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryMint,
                  ),
                ),
                const SizedBox(height: 16),
                ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _leetcodeController,
                        label: 'LeetCode Username',
                        hint: 'e.g. alex_rivera',
                        icon: Icons.code,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _githubController,
                        label: 'GitHub Username',
                        hint: 'e.g. alexrivera',
                        icon: Icons.pets,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _codechefController,
                        label: 'CodeChef Username',
                        hint: 'e.g. coder_alex',
                        icon: Icons.bar_chart,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _codeforcesController,
                        label: 'CodeForces Username',
                        hint: 'e.g. cf_user123',
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
