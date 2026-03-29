import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/notification_settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configurations',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'System & Profile Preferences',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryDark.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Settings Content ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 🎨 Appearance Section
                  const PremiumSectionHeader(
                    title: 'Visual Matrix',
                    subtitle: 'Customize your interface experience',
                    icon: Icons.palette_rounded,
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    padding: const EdgeInsets.all(12),
                    isGlass: true,
                    borderRadius: 28,
                    child: Column(
                      children: [
                        _buildThemeTile(
                          context,
                          title: 'Light Spectrum',
                          subtitle: 'Optimized for high-light environments',
                          icon: Icons.light_mode_rounded,
                          isSelected: themeProvider.themeMode == ThemeMode.light,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                        ),
                        _buildThemeTile(
                          context,
                          title: 'Dark Dimension',
                          subtitle: 'High-contrast, OLED-ready dark mode',
                          icon: Icons.dark_mode_rounded,
                          isSelected: themeProvider.themeMode == ThemeMode.dark,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                        ),
                        _buildThemeTile(
                          context,
                          title: 'System Synced',
                          subtitle: 'Follows your device OS preferences',
                          icon: Icons.settings_suggest_rounded,
                          isSelected: themeProvider.themeMode == ThemeMode.system,
                          onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🔔 Notifications Section
                  const PremiumSectionHeader(
                    title: 'Alert Network',
                    subtitle: 'Manage real-time contest triggers',
                    icon: Icons.notifications_active_rounded,
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    isGlass: true,
                    borderRadius: 28,
                    child: const NotificationSettingsTile(),
                  ),

                  const SizedBox(height: 32),

                  // 👤 Profile Section
                  const PremiumSectionHeader(
                    title: 'Identity Control',
                    subtitle: 'Manage your nodes and personal data',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    padding: const EdgeInsets.all(12),
                    isGlass: true,
                    borderRadius: 28,
                    child: Column(
                      children: [
                        _buildActionTile(
                          context,
                          title: 'Refine Identity',
                          subtitle: 'Update names, avatars and bios',
                          icon: Icons.edit_note_rounded,
                          onTap: () => Navigator.pushNamed(context, '/edit_profile'),
                        ),
                        _buildActionTile(
                          context,
                          title: 'Safety & Privacy',
                          subtitle: 'Data handling and security tokens',
                          icon: Icons.security_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ⚙️ Advanced Section
                  const PremiumSectionHeader(
                    title: 'Environment',
                    subtitle: 'Application version and connectivity',
                    icon: Icons.settings_input_component_rounded,
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    padding: const EdgeInsets.all(24),
                    isGlass: true,
                    borderRadius: 28,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CORE VERSION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '1.0.4-α Production',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                              SizedBox(width: 6),
                              Text(
                                'STABLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 120),
                ]),
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

  Widget _buildThemeTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        tileColor: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.transparent,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: isSelected ? AppTheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        trailing: isSelected 
            ? const Icon(Icons.radio_button_checked_rounded, color: AppTheme.primary, size: 18)
            : Icon(Icons.radio_button_off_rounded, color: Colors.grey.withValues(alpha: 0.3), size: 18),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
