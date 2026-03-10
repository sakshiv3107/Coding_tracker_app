import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/github_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/submission_heatmap.dart';
import '../models/github_stats.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/animations/animated_stat_counter.dart';
import '../widgets/skeleton_loading.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    final username = profile.profile?["github"] ?? "";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshStats(),
          color: AppTheme.githubBlack,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _buildBackButton(context),
                      const SizedBox(width: 16),
                      Text('GitHub', style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      _buildRefreshButton(github.isLoading),
                    ],
                  ),
                ),
              ),

              if (username.isEmpty)
                _buildMissingUsername(theme)
              else if (github.error != null)
                _buildErrorState(github.error!)
              else if (github.isLoading && github.githubStats == null)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SkeletonLoading(width: double.infinity, height: 120, borderRadius: 24),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: SkeletonLoading(width: double.infinity, height: 100, borderRadius: 24)),
                          SizedBox(width: 12),
                          Expanded(child: SkeletonLoading(width: double.infinity, height: 100, borderRadius: 24)),
                          SizedBox(width: 12),
                          Expanded(child: SkeletonLoading(width: double.infinity, height: 100, borderRadius: 24)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SkeletonLoading(width: double.infinity, height: 200, borderRadius: 24),
                    ]),
                  ),
                )
              else if (github.githubStats != null)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeSlideTransition(
                        child: _buildProfileHero(github.githubStats!, theme),
                      ),
                      const SizedBox(height: 24),
                      
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 100),
                        child: _buildOverallStats(github.githubStats!),
                      ),
                      const SizedBox(height: 24),

                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contribution Activity', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 16),
                            SubmissionHeatmap(
                              datasets: github.githubStats!.contributionCalendar,
                              baseColor: const Color(0xFF2EA44F),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 300),
                        child: Text('Most Used Languages', style: theme.textTheme.titleLarge),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 350),
                        child: _buildLanguagesSection(github.githubStats!),
                      ),
                      const SizedBox(height: 32),

                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 400),
                        child: Text('Starred Repositories', style: theme.textTheme.titleLarge),
                      ),
                      const SizedBox(height: 16),
                      _buildStarredRepos(github.starredRepos, theme),
                      const SizedBox(height: 32),

                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 450),
                        child: Text('Latest Repositories', style: theme.textTheme.titleLarge),
                      ),
                      const SizedBox(height: 16),
                      ...github.latestRepos.asMap().entries.map((entry) {
                        return FadeSlideTransition(
                          delay: Duration(milliseconds: 500 + (entry.key * 100)),
                          child: _buildRepoCard(entry.value, theme),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
            ],
          ),
        ),
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
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : AppTheme.textPrimaryLight),
      ),
    );
  }

  Widget _buildRefreshButton(bool isLoading) {
    return IconButton.filledTonal(
      onPressed: isLoading ? null : _refreshStats,
      icon: isLoading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
          : const Icon(Icons.refresh_rounded, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        foregroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildMissingUsername(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.github, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 24),
              Text('GitHub Not Connected', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'Add your GitHub username in profile settings to track your repositories and activity.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Go to Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _refreshStats, child: const Text('Try Again')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(GithubStats stats, ThemeData theme) {
    return ModernCard(
      padding: const EdgeInsets.all(24),
      showShadow: true,
      showBorder: false,
      child: Row(
        children: [
          Hero(
            tag: 'github_avatar',
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(stats.avatarUrl),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stats.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('@${stats.login}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                if (stats.bio != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    stats.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
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
        Expanded(child: _buildSmallStatCard('REPOS', stats.publicRepos, Icons.folder_copy_rounded, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildSmallStatCard('STARRED', stats.totalStarredRepos, Icons.star_border_rounded, Colors.purple)),
        const SizedBox(width: 12),
        Expanded(child: _buildSmallStatCard('STARS', stats.totalStars, Icons.star_rounded, Colors.amber)),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, int value, IconData icon, Color color) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      showShadow: true,
      showBorder: false,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          AnimatedStatCounter(
            value: value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection(GithubStats stats) {
    return ModernCard(
      padding: const EdgeInsets.all(24),
      showShadow: true,
      showBorder: false,
      child: Column(
        children: stats.topLanguages.entries.map((entry) {
          final color = _getLanguageColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text('${(entry.value * 100).toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
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
    if (starred.isEmpty) {
      return ModernCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('No starred repositories', style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    return Column(
      children: starred.take(3).map((repo) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ModernCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repo.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('by ${repo.owner}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(repo.stars.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
        showShadow: true,
        showBorder: false,
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    repo.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              ],
            ),
            if (repo.description != null) ...[
              const SizedBox(height: 12),
              Text(
                repo.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
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
                      Text(repo.language!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 20),
                ],
                _repoStat(Icons.star_rounded, repo.stars.toString(), Colors.amber),
                const SizedBox(width: 20),
                _repoStat(Icons.fork_right_rounded, repo.forks.toString(), Colors.grey),
                const Spacer(),
                Text(
                  'Updated ${DateFormat('MMM d').format(repo.updatedAt)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
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
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
