import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../providers/profile_provider.dart';
import '../models/platform_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/animations/animated_stat_counter.dart';
import '../widgets/responsive_card.dart';

class CodeChefStatsScreen extends StatefulWidget {
  const CodeChefStatsScreen({super.key});

  @override
  State<CodeChefStatsScreen> createState() => _CodeChefStatsScreenState();
}

class _CodeChefStatsScreenState extends State<CodeChefStatsScreen> {
  // static const _codechefBrown = Color(0xFF6B3A2A);
  static const _codechefAmber = Color(0xFFE08D2D);
  // static const _codechefGold  = Color(0xFFFFD166);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stats   = context.read<StatsProvider>();
      final profile = context.read<ProfileProvider>();
      final username = profile.profile?["codechef"] ?? "";
      if (username.isNotEmpty && stats.codechefStats == null && !stats.codechefLoading) {
        stats.fetchCodeChefStats(username);
      }
    });
  }

  void _refresh() {
    final stats   = context.read<StatsProvider>();
    final profile = context.read<ProfileProvider>();
    final username = profile.profile?["codechef"] ?? "";
    if (username.isNotEmpty) {
      stats.fetchCodeChefStats(username, forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats   = context.watch<StatsProvider>();
    final profile = context.watch<ProfileProvider>();
    final username = profile.profile?["codechef"] ?? "";
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: _codechefAmber,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Top bar ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _BackButton(isDark: isDark),
                      const SizedBox(width: 16),
                      Text('CodeChef', style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      _RefreshButton(
                        isLoading: stats.codechefLoading,
                        onRefresh: _refresh,
                        color: _codechefAmber,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Error ────────────────────────────────────────────────
              if (stats.codechefError != null && stats.codechefStats == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _ErrorBanner(
                        message: stats.codechefError!,
                        onRetry: _refresh,
                      ),
                    ),
                  ),
                )

              // ── Skeleton ─────────────────────────────────────────────
              else if (stats.codechefLoading && stats.codechefStats == null)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SkeletonLoading(width: double.infinity, height: 140, borderRadius: 24),
                      const SizedBox(height: 16),
                      const SkeletonLoading(width: double.infinity, height: 100, borderRadius: 24),
                      const SizedBox(height: 16),
                      const Row(children: [
                        Expanded(child: SkeletonLoading(width: double.infinity, height: 100, borderRadius: 24)),
                        SizedBox(width: 12),
                        Expanded(child: SkeletonLoading(width: double.infinity, height: 100, borderRadius: 24)),
                        SizedBox(width: 12),
                        Expanded(child: SkeletonLoading(width: double.infinity, height: 100, borderRadius: 24)),
                      ]),
                      const SizedBox(height: 16),
                      const SkeletonLoading(width: double.infinity, height: 200, borderRadius: 24),
                    ]),
                  ),
                )

              // ── Loaded ───────────────────────────────────────────────
              else if (stats.codechefStats != null)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _buildContent(stats.codechefStats!, username, isDark),
                    ),
                  ),
                )

              // ── Empty (no username) ───────────────────────────────────
              else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          username.isEmpty ? 'No CodeChef username set' : 'No data found for $username',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _codechefAmber,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(PlatformStats cc, String username, bool isDark) {
    return [
      // 1. Profile header
      FadeSlideTransition(
        child: _ProfileHeader(stats: cc, username: username),
      ),
      const SizedBox(height: 20),

      // 2. Rating banner (highlighted card)
      FadeSlideTransition(
        delay: const Duration(milliseconds: 80),
        child: _RatingBanner(stats: cc),
      ),
      const SizedBox(height: 20),

      // 3. Main stat row: solved / global rank / country rank
      FadeSlideTransition(
        delay: const Duration(milliseconds: 140),
        child: _MainStatRow(stats: cc),
      ),
      const SizedBox(height: 20),

      FadeSlideTransition(
        delay: const Duration(milliseconds: 200),
        child: _StarsCard(stats: cc),
      ),
      const SizedBox(height: 24),

      // 5. Heatmap
      FadeSlideTransition(
        delay: const Duration(milliseconds: 260),
        child: _SectionHeader(title: 'Submission Activity'),
      ),
      const SizedBox(height: 12),
      FadeSlideTransition(
        delay: const Duration(milliseconds: 280),
        child: _ActivityHeatmap(stats: cc),
      ),
      const SizedBox(height: 24),


      // 6. Extra metrics grid (globalRank, countryRank, division, country)
      if (cc.extraMetrics.isNotEmpty) ...[
        FadeSlideTransition(
          delay: const Duration(milliseconds: 320),
          child: _SectionHeader(title: 'Platform Metrics'),
        ),
        const SizedBox(height: 12),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 340),
          child: _ExtraMetricsGrid(stats: cc),
        ),
        const SizedBox(height: 24),
      ],

      const SizedBox(height: 96),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.stats, required this.username});
  final PlatformStats stats;
  final String username;

  static const _amber = Color(0xFFE08D2D);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 20,
      child: Row(
        children: [
          // Avatar / icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B3A2A), Color(0xFFE08D2D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: stats.avatarUrl != null && stats.avatarUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      stats.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                    ),
                  )
                : const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 32),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        stats.ranking ?? 'Unrated',
                        style: const TextStyle(
                          color: _amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'CodeChef',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating Banner
// ─────────────────────────────────────────────────────────────────────────────
class _RatingBanner extends StatelessWidget {
  const _RatingBanner({required this.stats});
  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      borderRadius: 24,
      gradient: const LinearGradient(
        colors: [Color(0xFF6B3A2A), Color(0xFFE08D2D)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT RATING',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedStatCounter(
                  value: stats.rating ?? 0,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (stats.maxRating != null) ...[
            Container(width: 1, height: 56, color: Colors.white24),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HIGHEST',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedStatCounter(
                  value: stats.maxRating!,
                  style: const TextStyle(
                    color: Color(0xFFFFD166),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Stat Row (3 cards)
// ─────────────────────────────────────────────────────────────────────────────
class _MainStatRow extends StatelessWidget {
  const _MainStatRow({required this.stats});
  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    final globalRank  = stats.extraMetrics['globalRank'];
    final countryRank = stats.extraMetrics['countryRank'];

    return Row(
      children: [
        Expanded(
          child: ResponsiveCard(
            label: 'SOLVED',
            value: stats.totalSolved.toString(),
            icon: Icons.check_circle_rounded,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ResponsiveCard(
            label: 'GLOBAL',
            value: globalRank != null && globalRank != '0' ? '#$globalRank' : '—',
            icon: Icons.public_rounded,
            color: const Color(0xFFE08D2D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ResponsiveCard(
            label: 'COUNTRY',
            value: countryRank != null && countryRank != '0' ? '#$countryRank' : '—',
            icon: Icons.flag_rounded,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Stars / Division card
// ─────────────────────────────────────────────────────────────────────────────
class _StarsCard extends StatelessWidget {
  const _StarsCard({required this.stats});
  final PlatformStats stats;

  static const _gold = Color(0xFFFFD166);

  @override
  Widget build(BuildContext context) {
    final division = stats.extraMetrics['division'];
    final country  = stats.extraMetrics['country'];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Row(
        children: [
          // Star display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STAR RATING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      stats.ranking ?? 'Unrated',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(width: 1, height: 60, color: Colors.grey.shade200),
          const SizedBox(width: 20),
          // Division + country
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (division != null && division.isNotEmpty)
                  _InfoRow(
                    icon: Icons.bar_chart_rounded,
                    label: 'Division',
                    value: division,
                    color: const Color(0xFFE08D2D),
                  ),
                if (country != null && country.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.place_rounded,
                    label: 'Country',
                    value: country,
                    color: Colors.blue,
                  ),
                ],
                if ((division == null || division.isEmpty) && (country == null || country.isEmpty))
                  Text('No division data', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Heatmap
// Renders a GitHub-style contribution heatmap using the rating history
// or a placeholder grid when no calendar data is available.
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.stats});
  final PlatformStats stats;

  static const _amber = Color(0xFFE08D2D);

  Map<DateTime, int> _buildCalendar() {
    return stats.submissionCalendar ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cal    = _buildCalendar();

    // Build 52 weeks ending today
    final today     = DateTime.now();
    final startDate = today.subtract(const Duration(days: 364));

    // Normalise to midnight
    DateTime norm(DateTime d) => DateTime(d.year, d.month, d.day);

    final weeks = <List<DateTime?>>[];
    // Start on the Sunday of the start week
    var cursor = norm(startDate);
    while (cursor.weekday != DateTime.sunday) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (cursor.isBefore(norm(today).add(const Duration(days: 1)))) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final day = cursor.add(Duration(days: d));
        week.add(day.isAfter(norm(today)) ? null : day);
      }
      weeks.add(week);
      cursor = cursor.add(const Duration(days: 7));
    }

    final maxVal = cal.values.isEmpty ? 1 : cal.values.reduce((a, b) => a > b ? a : b);

    Color cellColor(DateTime? day) {
      if (day == null) return Colors.transparent;
      final count = cal[norm(day)] ?? 0;
      if (count == 0) return isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);
      final intensity = (count / maxVal).clamp(0.15, 1.0);
      return _amber.withValues(alpha: intensity);
    }

    // Month labels
    final monthLabels = <int, String>{};
    for (int i = 0; i < weeks.length; i++) {
      final firstNonNull = weeks[i].firstWhere((d) => d != null, orElse: () => null);
      if (firstNonNull != null) {
        final m = firstNonNull.month;
        if (!monthLabels.containsValue(_monthAbbr(m)) ||
            (i > 0 && weeks[i - 1].firstWhere((d) => d != null, orElse: () => null)?.month != m)) {
          monthLabels[i] = _monthAbbr(m);
        }
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month labels row
          SizedBox(
            height: 16,
            child: Row(
              children: List.generate(weeks.length, (i) {
                final label = monthLabels[i] ?? '';
                return Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          // Cell grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weeks.map((week) {
              return Expanded(
                child: Column(
                  children: List.generate(7, (di) {
                    final day = week.length > di ? week[di] : null;
                    return Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cellColor(day),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final opacity = i == 0 ? 0.06 : 0.2 + i * 0.2;
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))
                        : _amber.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text('More', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            ],
          ),
          if (cal.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Activity data not available from API yet',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthAbbr(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}

// ─────────────────────────────────────────────────────────────────────────────
// Extra Metrics Grid
// ─────────────────────────────────────────────────────────────────────────────
class _ExtraMetricsGrid extends StatelessWidget {
  const _ExtraMetricsGrid({required this.stats});
  final PlatformStats stats;

  static const _iconMap = <String, IconData>{
    'globalRank':  Icons.public_rounded,
    'countryRank': Icons.flag_rounded,
    'division':    Icons.bar_chart_rounded,
    'country':     Icons.place_rounded,
  };

  static const _colorMap = <String, Color>{
    'globalRank':  Color(0xFFE08D2D),
    'countryRank': Colors.blue,
    'division':    Colors.purple,
    'country':     Colors.teal,
  };

  @override
  Widget build(BuildContext context) {
    final entries = stats.extraMetrics.entries.toList();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2, 
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: entries.map((entry) {
        final key = entry.key;
        final value = entry.value.toString();
        return ResponsiveCard(
          label: _labelFor(key),
          value: value,
          icon: _iconMap[key] ?? Icons.analytics_rounded,
          color: _colorMap[key],
        );
      }).toList(),
    );
  }

  String _labelFor(String key) {
    const labels = <String, String>{
      'globalRank':  'GLOBAL RANK',
      'countryRank': 'COUNTRY RANK',
      'division':    'DIVISION',
      'country':     'COUNTRY',
    };
    return labels[key] ?? key.toUpperCase();
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back Button
// ─────────────────────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  const _BackButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
          size: 18,
          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Refresh Button
// ─────────────────────────────────────────────────────────────────────────────
class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isLoading, required this.onRefresh, required this.color});
  final bool isLoading;
  final VoidCallback onRefresh;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: isLoading ? null : onRefresh,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : const Icon(Icons.refresh_rounded, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Banner
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text('Could not load CodeChef data',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE08D2D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
}


