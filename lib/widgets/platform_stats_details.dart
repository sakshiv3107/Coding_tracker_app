import 'package:flutter/material.dart';
import '../models/platform_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/responsive_card.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/not_connected_widget.dart';
import '../widgets/app_drawer.dart';
import '../widgets/platform_error_card.dart';

class PlatformStatsDetailsScreen extends StatelessWidget {
  final PlatformStats? stats;
  final String platformName;
  final IconData icon;
  final Color color;
  final String username;
  final bool isLoading;
  final String? errorMessage;
  final bool isUserNotFound;
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
    this.isUserNotFound = false,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
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
                      const SizedBox(width: 12),
                      _buildMenuButton(context, isDark),
                      Expanded(
                        child: Text(
                          platformName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: PlatformErrorCard(
                        platformName: platformName,
                        message: errorMessage ?? 'No data found for $username',
                        onRetry: onRefresh,
                        isUserNotFound: isUserNotFound,
                      ),
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
                        child: _buildMainStats(theme, isDark),
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
                        const SizedBox(height: 32),
                      ],

                      // 4. Recent Submissions
                      if (stats!.recentSubmissions.isNotEmpty) ...[
                        FadeSlideTransition(
                          delay: const Duration(milliseconds: 250),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded, size: 24, color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent),
                              const SizedBox(width: 12),
                              Text('Recent Activity', style: theme.textTheme.titleLarge),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...stats!.recentSubmissions.map((sub) {
                          final isAccepted = sub.status.toLowerCase().contains('accepted') || 
                                           sub.status.toLowerCase() == 'ac' ||
                                           sub.status.toLowerCase() == 'ok';
                          return FadeSlideTransition(
                            delay: const Duration(milliseconds: 300),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                borderRadius: 12,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (isAccepted ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isAccepted ? Icons.check_circle_outline : Icons.error_outline_rounded,
                                        color: isAccepted ? AppTheme.success : AppTheme.error,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                sub.status,
                                                style: TextStyle(
                                                  color: isAccepted ? Colors.green : Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (sub.lang != null && sub.lang!.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                const Text('•', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                                const SizedBox(width: 8),
                                                Text(sub.lang!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatTime(sub.timestamp),
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
  Widget _buildProfileHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                  '$platformName ${stats?.ranking ?? "User"}',
                  style: TextStyle(color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.6) : AppTheme.lightTextSecondary.withOpacity(0.6), fontSize: 14),
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

  Widget _buildMainStats(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'PROBLEMS SOLVED',
            stats!.totalSolved,
            Icons.check_circle_rounded,
            AppTheme.success,
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
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : AppTheme.lightTextPrimary),
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

  Widget _buildMenuButton(BuildContext context, bool isDark) {
    return Builder(builder: (context) {
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
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: Icon(
            Icons.menu_rounded,
            size: 18,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
        ),
      );
    });
  }
}


