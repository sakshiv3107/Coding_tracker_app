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

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          "Setup Coding Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                
                    const SizedBox(height: 20),
                
                    const Text(
                      "Add Your Coding Handles 🚀",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                
                    const SizedBox(height: 8),
                
                    const Text(
                      "These usernames will help us track your progress.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                
                    const SizedBox(height: 30),
                
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
                
                    const SizedBox(height: 40),
                
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize: const Size(double.infinity, 55),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                
                          profileProvider.saveProfile(
                            leetcode: leetcodeCtrl.text.trim(),
                            codechef: codechefCtrl.text.trim(),
                            codeforces: codeforcesCtrl.text.trim(),
                            github: githubCtrl.text.trim(),
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
                
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
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
    return TextFormField(
      controller: controller,
      validator: (value) =>
          value == null || value.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(
            color: Colors.deepPurple,
            width: 2,
          ),
        ),
      ),
    );
  }
}