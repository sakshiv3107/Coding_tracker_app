import 'package:flutter/material.dart';
import '../models/platform_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/responsive_card.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/animations/animated_stat_counter.dart';
import '../widgets/not_connected_widget.dart';

class PlatformStatsDetailsScreen extends StatelessWidget {
  final PlatformStats? stats;
  final String platformName;
  final IconData icon;
  final Color color;
  final String username;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;

  const PlatformStatsDetailsScreen({
    super.key,
    required this.stats,
    required this.platformName,
    required this.icon,
    required this.color,
    required this.username,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          color: color,
          child: CustomScrollView(
            slivers: [
              // ── Top Bar ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _buildBackButton(context, isDark),
                      const SizedBox(width: 16),
                      Text(platformName, style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      _buildRefreshButton(isLoading, onRefresh),
                    ],
                  ),
                ),
              ),

              if (username.isEmpty)
                NotConnectedWidget(
                  platformName: platformName,
                  icon: icon,
                  color: color,
                )
              else if (isLoading && stats == null)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (stats == null)
                 SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage ?? 'No data found for $username',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: onRefresh, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Profile header
                      FadeSlideTransition(
                        child: _buildProfileHeader(theme),
                      ),
                      const SizedBox(height: 24),

                      // 2. Main stats
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 100),
                        child: _buildMainStats(theme),
                      ),
                      const SizedBox(height: 24),

                      // 3. Extra metrics
                      if (stats!.extraMetrics.isNotEmpty) ...[
                        FadeSlideTransition(
                          delay: const Duration(milliseconds: 150),
                          child: Text('Platform Metrics', style: theme.textTheme.titleLarge),
                        ),
                        const SizedBox(height: 16),
                        FadeSlideTransition(
                          delay: const Duration(milliseconds: 200),
                          child: _buildExtraMetrics(theme),
                        ),
                      ],
                      
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '$platformName ${stats?.rank ?? "User"}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          if (stats?.rating != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RATING', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text(stats!.rating.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMainStats(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'PROBLEMS SOLVED',
            stats!.totalSolved,
            Icons.check_circle_rounded,
            AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        if (stats?.maxRating != null)
          Expanded(
            child: _buildStatCard(
              'MAX RATING',
              stats!.maxRating!,
              Icons.trending_up_rounded,
              color,
            ),
          ),
      ],
    );
  }

  Widget _buildExtraMetrics(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.1, // Even more vertical space to prevent bottom overflow
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: stats!.extraMetrics.entries.map((entry) {
        return ResponsiveCard(
          label: entry.key,
          value: entry.value.toString(),
          icon: Icons.bar_chart_rounded,
          color: color,
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color cardColor) {
    return ResponsiveCard(
      label: label,
      value: value.toString(),
      icon: icon,
      color: cardColor,
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
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      ),
    );
  }

  Widget _buildRefreshButton(bool isLoading, VoidCallback onRefresh) {
    return IconButton.filledTonal(
      onPressed: isLoading ? null : onRefresh,
      icon: isLoading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.refresh_rounded, size: 20),
    );
  }
}
