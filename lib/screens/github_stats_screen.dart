import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/github_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/submission_heatmap.dart';
import '../models/github_stats.dart';
import 'package:intl/intl.dart';

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
          color: Colors.black,
          child: CustomScrollView(
            slivers: [
              // Custom Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _buildBackButton(context),
                      const SizedBox(width: 20),
                      Text('GitHub Activity', style: theme.textTheme.headlineMedium),
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
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.black)),
                )
              else if (github.githubStats != null)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildProfileHero(github.githubStats!, theme),
                      const SizedBox(height: 32),
                      
                      // Overall Stats
                      _buildOverallStats(github.githubStats!),
                      const SizedBox(height: 32),

                      // Contribution Heatmap
                      Text('Contributions', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      //  Text(
                      //   "${github.githubStats!.totalContributions} contributions in the last year",
                      //   style: TextStyle(
                      //     color: Colors.grey.shade600,
                      //     fontSize: 12,
                      //   ),
                      // ),
                      SubmissionHeatmap(
                        datasets: github.githubStats!.contributionCalendar,
                        baseColor: const Color(0xFF2EA44F), // GitHub Green
                      ),
                      const SizedBox(height: 32),

                      // Top Languages
                      Text('Most Used Languages', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _buildLanguagesSection(github.githubStats!),
                      const SizedBox(height: 32),

                      // Latest Repositories
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Latest Repositories', style: theme.textTheme.titleLarge),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View all', style: TextStyle(color: AppTheme.primaryMint)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...github.latestRepos.map((repo) => _buildRepoCard(repo, theme)).toList(),
                      
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.charcoal),
      ),
    );
  }

  Widget _buildRefreshButton(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: isLoading ? null : _refreshStats,
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : const Icon(Icons.refresh_rounded, size: 22, color: Colors.black),
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
              const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text('GitHub Profile Not Set', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'Connect your GitHub account in profile settings to sync your repositories and contributions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Connect GitHub'),
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
          child: ModernCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 48),
                const SizedBox(height: 16),
                const Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(stats.avatarUrl),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stats.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('@${stats.login}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              if (stats.bio != null) ...[
                const SizedBox(height: 8),
                Text(
                  stats.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallStats(GithubStats stats) {
    return Row(
      children: [
        Expanded(child: _buildSmallStatCard('REPOS', stats.publicRepos.toString(), Icons.folder_copy_rounded, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildSmallStatCard('FOLLOWERS', stats.followers.toString(), Icons.people_rounded, Colors.purple)),
        const SizedBox(width: 12),
        Expanded(child: _buildSmallStatCard('STARS', stats.totalStars.toString(), Icons.star_rounded, Colors.orange)),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, IconData icon, Color color) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection(GithubStats stats) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: stats.topLanguages.entries.map((entry) {
          final color = _getLanguageColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 5, backgroundColor: color),
                        const SizedBox(width: 10),
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text('${(entry.value * 100).toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: entry.value,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRepoCard(GithubRepository repo, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    repo.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
            if (repo.description != null) ...[
              const SizedBox(height: 8),
              Text(
                repo.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (repo.language != null) ...[
                  Row(
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: _getLanguageColor(repo.language!)),
                      const SizedBox(width: 6),
                      Text(repo.language!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(width: 20),
                ],
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(repo.stars.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    const Icon(Icons.fork_right_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(repo.forks.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const Spacer(),
                Text(
                  'Updated ${DateFormat('MMM d').format(repo.updatedAt)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getLanguageColor(String lang) {
    switch (lang.toLowerCase()) {
      case 'javascript': return Colors.yellow.shade700;
      case 'dart': return Colors.blue.shade600;
      case 'python': return Colors.blue.shade400;
      case 'java': return Colors.orange.shade800;
      case 'html': return Colors.orange.shade600;
      case 'css': return Colors.purple.shade500;
      case 'typescript': return Colors.blue.shade800;
      case 'c++': return Colors.pink.shade400;
      default: return Colors.blueGrey;
    }
  }
}
