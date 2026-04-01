import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
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

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUpload(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final url = await context.read<ProfileProvider>().pickAndUploadImage(source);
      if (url != null) {
        setState(() {
          _picController.text = url;
        });
      }
    } catch (e) {
      if (mounted) {
        _showFeedback(context, 'Upload failed: $e', isError: true);
      }
    }
  }


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
                              color: AppTheme.textSecondaryDark.withValues(alpha: 0.4),
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
                            GestureDetector(
                              onTap: () => _showImageSourceActionSheet(context),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    backgroundImage: _picController.text.isNotEmpty
                                        ? CachedNetworkImageProvider(_picController.text)
                                        : null,
                                    child: _picController.text.isEmpty && !isLoading
                                        ? Opacity(
                                            opacity: 0.5,
                                            child: Icon(Icons.person_rounded, size: 60, color: theme.colorScheme.primary),
                                          )
                                        : isLoading && _picController.text.isEmpty
                                            ? const CircularProgressIndicator()
                                            : null,
                                  ),
                                  if (isLoading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            height: 30,
                                            width: 30,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      
                      ModernCard(
                        padding: const EdgeInsets.all(12),
                        isGlass: true,
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
                      ModernCard(
                        padding: const EdgeInsets.all(12),
                        isGlass: true,
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
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          color: isDark ? Colors.white : AppTheme.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Icon(icon, size: 18, color: AppTheme.primary.withValues(alpha: 0.6)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.02)),
        ],
      ),
    );
  }
}
