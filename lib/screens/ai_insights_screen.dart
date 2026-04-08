import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/ai_insights_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/profile_provider.dart';
import '../models/insight_model.dart';
import '../widgets/modern_card.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiProvider = context.read<AIInsightsProvider>();
      final stats = context.read<StatsProvider>();
      final github = context.read<GithubProvider>();
      final goals = context.read<GoalProvider>();
      aiProvider.fetchInsights(stats: stats, goals: goals, github: github);
    });
  }

  Future<void> _onRefresh() async {
    final aiProvider = context.read<AIInsightsProvider>();
    final stats = context.read<StatsProvider>();
    final github = context.read<GithubProvider>();
    final goals = context.read<GoalProvider>();
    final profile = context.read<ProfileProvider>();

    final ghHandle = profile.githubHandle ?? "";

    // Refresh all data
    List<Future> refreshTasks = [
      stats.fetchAllStats(),
      aiProvider.fetchInsights(
        stats: stats,
        goals: goals,
        github: github,
        force: true,
      ),
    ];

    if (ghHandle.isNotEmpty) {
      refreshTasks.add(github.fetchGithubData(ghHandle, forceRefresh: true));
    }

    await Future.wait(refreshTasks);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiProvider = context.watch<AIInsightsProvider>();
    final stats = context.watch<StatsProvider>();
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        edgeOffset: 100, // Position it below the app bar if needed
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(theme, aiProvider),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderStats(theme, aiProvider),
                    const SizedBox(height: 32),

                    _sectionTitle(
                      theme,
                      'AI Performance Insights',
                      Icons.psychology_rounded,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your recent activity',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInsightsList(theme, aiProvider, stats, profile),

                    const SizedBox(height: 32),
                    _sectionTitle(
                      theme,
                      'Smart Recommendations',
                      Icons.auto_awesome_rounded,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Personalized path to level up',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendations(theme, aiProvider, stats),

                    const SizedBox(height: 32),
                    _sectionTitle(
                      theme,
                      'Improvement Trends',
                      Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTrendsChart(theme, aiProvider),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, AIInsightsProvider aiProvider) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        centerTitle: false,
        title: Text(
          'AI Coding Coach',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            final stats = context.read<StatsProvider>();
            final github = context.read<GithubProvider>();
            final goals = context.read<GoalProvider>();
            aiProvider.fetchInsights(
              stats: stats,
              goals: goals,
              github: github,
              force: true,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderStats(ThemeData theme, AIInsightsProvider aiProvider) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            theme,
            'Streak',
            '${aiProvider.streak} Days',
            Icons.local_fire_department_rounded,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            theme,
            'XP Points',
            '${aiProvider.xp}',
            Icons.bolt_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            theme,
            'Level',
            '${aiProvider.level}',
            Icons.workspace_premium_rounded,
            Colors.purple,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _statCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return ModernCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsList(
    ThemeData theme,
    AIInsightsProvider aiProvider,
    StatsProvider stats,
    ProfileProvider profile,
  ) {
    if (aiProvider.insightsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (aiProvider.insightsError != null) {
      return _buildErrorState(
        theme,
        title: 'Analysis Error',
        message: aiProvider.insightsError!,
        onRetry: () => _onRefresh(),
      );
    }

    if (aiProvider.insights.isEmpty) {
      // Check if any profile has data OR has handles configured
      final hasData = stats.totalSolved > 0;
      final hasHandles =
          profile.leetcodeHandle?.isNotEmpty == true ||
          profile.githubHandle?.isNotEmpty == true ||
          profile.codeforcesHandle?.isNotEmpty == true ||
          profile.codechefHandle?.isNotEmpty == true ||
          profile.hackerrankHandle?.isNotEmpty == true;

      if (hasData || hasHandles) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Analyzing your activity...',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We\'re crunching your latest stats to find meaningful patterns. Try pulling to refresh!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ).animate().fadeIn();
      } else {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.link_off_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 12),
              const Text(
                'No Profiles Connected',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect LeetCode, GitHub, or Codeforces in Settings to unlock personalized AI insights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ).animate().fadeIn();
      }
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: aiProvider.insights.length,
        itemBuilder: (context, index) {
          final insight = aiProvider.insights[index];
          return _buildInsightCard(theme, insight, aiProvider);
        },
      ),
    );
  }

  Widget _buildInsightCard(
    ThemeData theme,
    InsightModel insight,
    AIInsightsProvider aiProvider,
  ) {
    final isWeakness =
        insight.type == InsightType.weakness ||
        insight.type == InsightType.errorRate;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: ModernCard(
        padding: const EdgeInsets.all(20),
        gradient: isWeakness
            ? [
                theme.colorScheme.error.withOpacity(0.1),
                theme.colorScheme.error.withOpacity(0.05),
              ]
            : [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.primary.withOpacity(0.05),
              ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(insight.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildConfidenceBadge(theme, insight.confidence),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.reason,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    insight.topic,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showActionPlan(insight, aiProvider),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Improve this →',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(ThemeData theme, String level) {
    Color color = Colors.blueAccent;
    if (level.toLowerCase() == 'high') color = Colors.greenAccent;
    if (level.toLowerCase() == 'medium') color = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showActionPlan(InsightModel insight, AIInsightsProvider aiProvider) {
    aiProvider.generateActionPlan(insight);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ActionPlanBottomSheet(insight: insight);
      },
    );
  }

  Widget _buildRecommendations(
    ThemeData theme,
    AIInsightsProvider aiProvider,
    StatsProvider stats,
  ) {
    if (aiProvider.recommendationsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (aiProvider.recommendationsError != null) {
      return _buildErrorState(
        theme,
        title: 'Failed to load recommendations',
        message: aiProvider.recommendationsError!,
        onRetry: () => _onRefresh(),
      );
    }

    if (aiProvider.recommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Keep practice consistent to unlock smarter recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Limit to max 3 recommendations
    final recs = aiProvider.recommendations.take(3).toList();

    return Column(
      children: recs.map((rec) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ModernCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getColorForType(rec.type, theme).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(rec.icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rec.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _typeBadge(rec.type, theme),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.description,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _typeBadge(String type, ThemeData theme) {
    final color = _getColorForType(type, theme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColorForType(String type, ThemeData theme) {
    switch (type.toLowerCase()) {
      case 'focus':
        return Colors.redAccent;
      case 'improve':
        return Colors.orangeAccent;
      case 'challenge':
        return Colors.purpleAccent;
      case 'balance':
        return Colors.blueAccent;
      default:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildTrendsChart(ThemeData theme, AIInsightsProvider aiProvider) {
    return SizedBox(
      height: 200,
      child: ModernCard(
        padding: const EdgeInsets.all(20),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 40),
                  FlSpot(1, 45),
                  FlSpot(2, 42),
                  FlSpot(3, 58),
                  FlSpot(4, 55),
                  FlSpot(5, 70),
                  FlSpot(6, 75),
                ],
                isCurved: true,
                color: theme.colorScheme.primary,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.3),
                      theme.colorScheme.primary.withOpacity(0.0),
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

  Widget _buildErrorState(
    ThemeData theme, {
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.report_problem_rounded,
            color: theme.colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.error,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _ActionPlanBottomSheet extends StatelessWidget {
  final InsightModel insight;

  const _ActionPlanBottomSheet({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiProvider = context.watch<AIInsightsProvider>();
    final plan = aiProvider.currentActionPlan;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.assignment_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Action Plan',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      insight.topic,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (aiProvider.actionPlanLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (plan != null) ...[
            _planInfoRow(
              'Estimated Time',
              plan.estimatedTime,
              Icons.timer_rounded,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _planInfoRow(
              'Revision Topic',
              plan.revisionTopic,
              Icons.menu_book_rounded,
              Colors.purple,
            ),

            const SizedBox(height: 24),
            const Text(
              'Curated Problems',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...plan.problems.map(
              (p) => _problemItem(context, theme, p, aiProvider),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Start Practice Session',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ] else if (aiProvider.actionPlanError != null)
            Text('Error: ${aiProvider.actionPlanError}')
          else
            const Text('No plan generated.'),
        ],
      ).animate().slideY(begin: 0.1, end: 0, duration: 300.ms),
    );
  }

  Widget _planInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ],
    );
  }

  Widget _problemItem(
    BuildContext context,
    ThemeData theme,
    ProblemSuggestion problem,
    AIInsightsProvider aiProvider,
  ) {
    return GestureDetector(
      onTap: () {
        // Log a practice result for demonstration
        aiProvider.logPracticeResult(correct: true, points: 50);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulated practice for ${problem.title}')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.code_rounded, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    problem.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    problem.platform,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (problem.difficulty == 'Hard' ? Colors.red : Colors.orange)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                problem.difficulty,
                style: TextStyle(
                  color: problem.difficulty == 'Hard'
                      ? Colors.red
                      : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
