import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/github_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/submission_heatmap.dart';
import '../models/github_stats.dart';
import '../widgets/animations/fade_slide_transition.dart';
//import '../widgets/animations/animated_stat_counter.dart';
import '../widgets/skeleton_loading.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/not_connected_widget.dart';
import '../providers/stats_provider.dart';
import '../widgets/weekly_activity_chart.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/app_drawer.dart';

class GitHubStatsScreen extends StatefulWidget {
  const GitHubStatsScreen({super.key});

  @override
  State<GitHubStatsScreen> createState() => _GitHubStatsScreenState();
}

class _GitHubStatsScreenState extends State<GitHubStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStats();
    });
  }

  void _refreshStats() {
    final profile = context.read<ProfileProvider>();
    final githubProvider = context.read<GithubProvider>();
    final username = profile.profile?["github"] ?? "";

    if (githubProvider.isLoading) return;

    if (username.isNotEmpty) {
      githubProvider.fetchGithubData(username);
    } else {
      githubProvider.setError("GitHub username not set in profile");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<ProfileProvider>();
    final github = context.watch<GithubProvider>();
    final stats = context.watch<StatsProvider>();
    final username = profile.profile?["github"] ?? "";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshStats(),
          color: AppTheme.githubGrey,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Modern Top Bar
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _buildBackButton(context),
                      const SizedBox(width: 12),
                      _buildMenuButton(context),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GitHub Intelligence',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Active Node: $username',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryDark.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildRefreshButton(github.isLoading),
                    ],
                  ),
                ),
              ),

              if (username.isEmpty)
                const NotConnectedWidget(
                  platformName: 'GitHub',
                  icon: FontAwesomeIcons.github,
                  color: AppTheme.githubGrey,
                )
              else if (github.error != null)
                _buildErrorState(github.error!)
              else if (github.isLoading && github.githubStats == null)
                _buildLoadingState()
              else if (github.githubStats != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Profile Hero
                      FadeSlideTransition(
                        child: _buildProfileHero(github.githubStats!, theme),
                      ),
                      const SizedBox(height: 32),
                      
                      // 2. Overview Section
                      const PremiumSectionHeader(
                        title: 'Repository Ecosystem',
                        subtitle: 'Overview of your contributions',
                        icon: FontAwesomeIcons.layerGroup,
                      ),
                      const SizedBox(height: 12),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 100),
                        child: _buildOverallStats(github.githubStats!),
                      ),
                      const SizedBox(height: 32),

                      // 3. Activity Section
                      const PremiumSectionHeader(
                        title: 'Contribution Flux',
                        subtitle: 'Spacetime activity pattern',
                        icon: FontAwesomeIcons.waveSquare,
                      ),
                      const SizedBox(height: 12),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            SubmissionHeatmap(
                              datasets: github.githubStats?.contributionCalendar ?? {},
                              baseColor: const Color(0xFF2EA44F),
                            ),
                            const SizedBox(height: 16),
                            WeeklyActivityChart(
                              leetcodeCalendar: stats.leetcodeStats?.submissionCalendar ?? {},
                              githubCalendar: github.githubStats?.contributionCalendar ?? {},
                              hackerrankCalendar: stats.hackerrankStats?.submissionHistory ?? {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 4. Languages Section
                      const PremiumSectionHeader(
                        title: 'Language Matrix',
                        subtitle: 'Technology stack distribution',
                        icon: FontAwesomeIcons.microchip,
                      ),
                      const SizedBox(height: 12),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 300),
                        child: _buildLanguagesSection(github.githubStats!),
                      ),
                      const SizedBox(height: 32),

                      // 5. Starred Section
                      if (github.starredRepos.isNotEmpty) ...[
                        const PremiumSectionHeader(
                          title: 'Curated Nodes',
                          subtitle: 'Top starred repositories',
                          icon: FontAwesomeIcons.solidStar,
                          iconColor: Colors.amber,
                        ),
                        const SizedBox(height: 12),
                        _buildStarredRepos(github.starredRepos, theme),
                        const SizedBox(height: 32),
                      ],

                      // 6. Latest Repos
                      const PremiumSectionHeader(
                        title: 'Recently Initialized',
                        subtitle: 'Latest repository activity',
                        icon: FontAwesomeIcons.codeBranch,
                      ),
                      const SizedBox(height: 12),
                      ...github.latestRepos.asMap().entries.map((entry) {
                        return FadeSlideTransition(
                          delay: Duration(milliseconds: 400 + (entry.key * 100)),
                          child: _buildRepoCard(entry.value, theme),
                        );
                      }),
                      
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

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SkeletonLoading(width: double.infinity, height: 120, borderRadius: 28),
          const SizedBox(height: 32),
          const Row(
            children: [
              Expanded(child: SkeletonLoading(width: double.infinity, height: 110, borderRadius: 24)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoading(width: double.infinity, height: 110, borderRadius: 24)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoading(width: double.infinity, height: 110, borderRadius: 24)),
            ],
          ),
          const SizedBox(height: 32),
          const SkeletonLoading(width: double.infinity, height: 220, borderRadius: 28),
        ]),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(FontAwesomeIcons.chevronLeft, size: 14, color: isDark ? Colors.white : AppTheme.textPrimaryLight),
      ),
    );
  }

  Widget _buildRefreshButton(bool isLoading) {
    return IconButton.filledTonal(
      onPressed: isLoading ? null : _refreshStats,
      icon: isLoading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
          : const Icon(FontAwesomeIcons.rotate, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        foregroundColor: AppTheme.primary,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Builder(builder: (context) {
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
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: Icon(
            Icons.menu_rounded,
            size: 18,
            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
          ),
        ),
      );
    });
  }

  Widget _buildErrorState(String error) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ModernCard(
            isGlass: true,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FontAwesomeIcons.triangleExclamation, color: Colors.orange, size: 48),
                const SizedBox(height: 20),
                Text('Uplink Interrupted', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text(error, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondaryDark.withValues(alpha: 0.5))),
                const SizedBox(height: 32),
                PremiumGradientButton(text: 'Reconnect', onPressed: _refreshStats),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(GithubStats stats, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return ModernCard(
      padding: EdgeInsets.zero,
      isGlass: true,
      borderRadius: 32,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              FontAwesomeIcons.github,
              size: 140,
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.cardTheme.color,
                    backgroundImage: NetworkImage(stats.avatarUrl),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.name, 
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        )
                      ),
                      Text(
                        '@${stats.login}', 
                        style: TextStyle(
                          color: AppTheme.primary, 
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        )
                      ),
                      if (stats.bio != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          stats.bio!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12, 
                            color: AppTheme.textSecondaryDark.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(GithubStats stats) {
    return Row(
      children: [
        Expanded(
          child: PremiumStatCard(
            label: 'REPOS', 
            value: stats.publicRepos.toString(), 
            icon: FontAwesomeIcons.bookBookmark, 
            color: Colors.blue
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumStatCard(
            label: 'STARRED', 
            value: stats.totalStarredRepos.toString(), 
            icon: FontAwesomeIcons.starHalfStroke, 
            color: Colors.purple
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumStatCard(
            label: 'STARS', 
            value: stats.totalStars.toString(), 
            icon: FontAwesomeIcons.solidStar, 
            color: Colors.amber
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(GithubStats stats) {
    return ModernCard(
      padding: const EdgeInsets.all(24),
      isGlass: true,
      borderRadius: 28,
      child: Column(
        children: stats.topLanguages.entries.map((entry) {
          final color = _getLanguageColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ],
                    ),
                    Text('${(entry.value * 100).toStringAsFixed(1)}%', style: TextStyle(color: AppTheme.textSecondaryDark.withValues(alpha: 0.4), fontWeight: FontWeight.w900, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: entry.value),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStarredRepos(List<GithubStarredRepository> starred, ThemeData theme) {
    return Column(
      children: starred.take(3).map((repo) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ModernCard(
          padding: const EdgeInsets.all(18),
          isGlass: true,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repo.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('by ${repo.owner}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(FontAwesomeIcons.solidStar, color: Colors.amber, size: 12),
                  const SizedBox(width: 6),
                  Text(repo.stars.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRepoCard(GithubRepository repo, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        padding: const EdgeInsets.all(24),
        isGlass: true,
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    repo.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                  ),
                ),
                Icon(FontAwesomeIcons.chevronRight, size: 12, color: AppTheme.textSecondaryDark.withValues(alpha: 0.2)),
              ],
            ),
            if (repo.description != null) ...[
              const SizedBox(height: 12),
              Text(
                repo.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textSecondaryDark.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (repo.language != null) ...[
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: _getLanguageColor(repo.language!), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(repo.language!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(width: 20),
                ],
                _repoStat(FontAwesomeIcons.solidStar, repo.stars.toString(), Colors.amber),
                const SizedBox(width: 20),
                _repoStat(FontAwesomeIcons.codeFork, repo.forks.toString(), Colors.grey),
                const Spacer(),
                Text(
                  'Updated ${DateFormat('MMM d').format(repo.updatedAt)}',
                  style: TextStyle(color: AppTheme.textSecondaryDark.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _repoStat(IconData icon, String val, Color color) {
    return Row(
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 6),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Color _getLanguageColor(String lang) {
    switch (lang.toLowerCase()) {
      case 'javascript': return const Color(0xFFF7DF1E);
      case 'dart': return const Color(0xFF00B4AB);
      case 'python': return const Color(0xFF3776AB);
      case 'java': return const Color(0xFFB07219);
      case 'html': return const Color(0xFFE34C26);
      case 'css': return const Color(0xFF563D7C);
      case 'typescript': return const Color(0xFF3178C6);
      case 'c++': return const Color(0xFFF34B7D);
      case 'c': return const Color(0xFF555555);
      case 'go': return const Color(0xFF00ADD8);
      default: return Colors.blueGrey;
    }
  }
}
