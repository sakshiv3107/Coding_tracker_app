import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/stats_provider.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _leetcodeController;
  late TextEditingController _codechefController;
  late TextEditingController _codeforceController;
  late TextEditingController _githubController;
  late String _originalLeetcode;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _originalLeetcode = profile.profile?['leetcode'] ?? '';
    _leetcodeController = TextEditingController(
      text: profile.profile?['leetcode'] ?? '',
    );
    _codechefController = TextEditingController(
      text: profile.profile?['codechef'] ?? '',
    );
    _codeforceController = TextEditingController(
      text: profile.profile?['codeforces'] ?? '',
    );
    _githubController = TextEditingController(
      text: profile.profile?['github'] ?? '',
    );
  }

  @override
  void dispose() {
    _leetcodeController.dispose();
    _codechefController.dispose();
    _codeforceController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final profile = context.read<ProfileProvider>();
    final stats = context.read<StatsProvider>();

    try {
      await profile.saveProfile(
        leetcode: _leetcodeController.text.trim(),
        codechef: _codechefController.text.trim(),
        codeforces: _codeforceController.text.trim(),
        github: _githubController.text.trim(),
      );

      // If LeetCode username changed, refresh stats
      if (_leetcodeController.text.trim() != _originalLeetcode) {
        await stats.fetchLeetCodeStats(_leetcodeController.text.trim());
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading;

    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _leetcodeController,
              label: 'LeetCode Username',
              icon: Icons.code,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _codechefController,
              label: 'CodeChef Username',
              icon: Icons.restaurant,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _codeforceController,
              label: 'CodeForces Username',
              icon: Icons.bolt,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _githubController,
              label: 'GitHub Username',
              icon: Icons.hub,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _saveProfile,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
