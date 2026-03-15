import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Appearance', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ModernCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildThemeOption(
                  context,
                  title: 'Light Mode',
                  icon: Icons.light_mode_rounded,
                  isSelected: themeProvider.themeMode == ThemeMode.light,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 24),
                _buildThemeOption(
                  context,
                  title: 'Dark Mode',
                  icon: Icons.dark_mode_rounded,
                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
                const Divider(height: 24),
                _buildThemeOption(
                  context,
                  title: 'System Default',
                  icon: Icons.settings_suggest_rounded,
                  isSelected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Text('Account', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ModernCard(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.pushNamed(context, '/edit_profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isSelected ? AppTheme.primary : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected 
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) 
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
