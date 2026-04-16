import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _picController;
  late TextEditingController _leetcodeController;
  late TextEditingController _codechefController;
  late TextEditingController _codeforcesController;
  late TextEditingController _githubController;
  late TextEditingController _hackerrankController;




  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    _nameController = TextEditingController(text: auth.user?["name"] ?? "");
    _picController = TextEditingController(text: profile.profile?["profilePic"] ?? "");
    _leetcodeController = TextEditingController(text: profile.profile?["leetcode"] ?? "");
    _codechefController = TextEditingController(text: profile.profile?["codechef"] ?? "");
    _codeforcesController = TextEditingController(text: profile.profile?["codeforces"] ?? "");
    _githubController = TextEditingController(text: profile.profile?["github"] ?? "");
    _hackerrankController = TextEditingController(text: profile.profile?["hackerrank"] ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _picController.dispose();
    _leetcodeController.dispose();
    _codechefController.dispose();
    _codeforcesController.dispose();
    _githubController.dispose();
    _hackerrankController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();

    final name = _nameController.text.trim();
    final pic = _picController.text.trim();
    final leetcode = _leetcodeController.text.trim();
    final codechef = _codechefController.text.trim();
    final codeforces = _codeforcesController.text.trim();
    final github = _githubController.text.trim();
    final hackerrank = _hackerrankController.text.trim();


    await profileProvider.updateFullProfile(
      name: name,
      profilePic: pic,
      leetcode: leetcode,
      codechef: codechef,
      codeforces: codeforces,
      github: github,
      hackerrank: hackerrank,
    );

    if (profileProvider.error == null) {
      authProvider.updateName(name);
      if (mounted) {
        _showFeedback(context, 'Identity Sync Successful', isError: false);
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        _showFeedback(context, profileProvider.error!, isError: true);
      }
    }
  }

  void _showFeedback(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.watch<ProfileProvider>().isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Premium Top Bar ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    _buildBackButton(context, isDark),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refine Identity',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Updating your global persona',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.darkTextSecondary.withOpacity(0.4),
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Form Content ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 🏠 Personal Info Section
                      const PremiumSectionHeader(
                        title: 'Personal Attributes',
                        subtitle: 'Core identity details across the platform',
                        icon: Icons.face_retouching_natural_rounded,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      // ── Profile Picture & Name ──────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.person_rounded, 
                                size: 60, 
                                color: theme.colorScheme.primary.withOpacity(0.5)
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        
                        borderRadius: 28,
                        child: Column(
                          children: [
                            _buildModernField(
                              controller: _nameController,
                              label: 'FULL NAME',
                              icon: Icons.badge_rounded,
                              hint: 'Developer Name',
                              validator: (v) => v!.isEmpty ? 'Name required' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 🌐 Platform Nodes Section
                      const PremiumSectionHeader(
                        title: 'Platform Logic',
                        subtitle: 'Connect your developer nodes for data sync',
                        icon: Icons.hub_rounded,
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        
                        borderRadius: 28,
                        child: Column(
                          children: [
                            _buildModernField(
                              controller: _leetcodeController,
                              label: 'LEETCODE UID',
                              icon: FontAwesomeIcons.code,
                              hint: 'leetcode_username',
                            ),
                            _buildModernField(
                              controller: _githubController,
                              label: 'GITHUB NODE',
                              icon: FontAwesomeIcons.github,
                              hint: 'github_handle',
                            ),
                            _buildModernField(
                              controller: _hackerrankController,
                              label: 'HACKERRANK ID',
                              icon: FontAwesomeIcons.hackerrank,
                              hint: 'hr_nick',
                            ),
                            _buildModernField(
                              controller: _codeforcesController,
                              label: 'CODEFORCES',
                              icon: Icons.trending_up,
                              hint: 'handle_cf',
                            ),
                            _buildModernField(
                              controller: _codechefController,
                              label: 'CODECHEF',
                              icon: Icons.restaurant_menu,
                              hint: 'chef_pro',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // 💾 Save Button
                      PremiumGradientButton(
                        text: isLoading ? 'SYNCING...' : 'PERSIST CHANGES',
                        onPressed: isLoading ? () {} : () => _saveProfile(),
                        icon: isLoading ? null : Icons.security_update_good_rounded,
                      ),
                      
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSecondaryBg : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required dynamic icon, // Changed from IconData to dynamic
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.15),
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: icon is IconData 
                  ? Icon(icon, size: 18, color: AppTheme.primary.withOpacity(0.6))
                  : FaIcon(icon, size: 18, color: AppTheme.primary.withOpacity(0.6)),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.02)),
        ],
      ),
    );
  }
}



