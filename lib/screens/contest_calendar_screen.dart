import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/stats_provider.dart';
import '../providers/profile_provider.dart';
import '../services/contest_service.dart';
import '../theme/app_theme.dart';

class ContestCalendarScreen extends StatefulWidget {
  const ContestCalendarScreen({super.key});

  @override
  State<ContestCalendarScreen> createState() => _ContestCalendarScreenState();
}

class _ContestCalendarScreenState extends State<ContestCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _refresh() {
    final stats = context.read<StatsProvider>();
    final profile = context.read<ProfileProvider>();
    final cfUser = profile.profile?['codeforces'] ?? '';
    final lcUser = profile.profile?['leetcode'] ?? '';
    stats.fetchUpcomingContests(cfHandle: cfUser, lcHandle: lcUser);
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Contest Calendar',
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),

            Expanded(
              child:
                  stats.contestsLoading &&
                      stats.upcomingContests.isEmpty &&
                      stats.attendedContests.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async => _refresh(),
                      child:
                          (stats.upcomingContests.isEmpty &&
                              stats.attendedContests.isEmpty)
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_busy_rounded,
                                          size: 64,
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No contests found',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: _refresh,
                                          child: const Text('Tap to retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              children: [
                                if (stats.attendedContests.isNotEmpty) ...[
                                  _SectionHeader(title: 'Previously Attended'),
                                  const SizedBox(height: 16),
                                  ...stats.attendedContests.map(
                                    (c) => _ContestListItem(
                                      contest: c,
                                      isPast: true,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                                if (stats.upcomingContests.isNotEmpty) ...[
                                  _SectionHeader(title: 'Upcoming Contests'),
                                  const SizedBox(height: 16),
                                  ...stats.upcomingContests.map(
                                    (c) => _ContestListItem(contest: c),
                                  ),
                                ],
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: theme.colorScheme.primary.withOpacity(0.8),
      ),
    );
  }
}

class _ContestListItem extends StatelessWidget {
  final Contest contest;
  final bool isPast;

  const _ContestListItem({required this.contest, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color platformColor;
    final IconData platformIcon;

    switch (contest.platform.toLowerCase()) {
      case 'codeforces':
        platformColor = Colors.blueAccent;
        platformIcon = Icons.code_rounded;
        break;
      case 'leetcode':
        platformColor = AppTheme.leetCodeYellow;
        platformIcon = Icons.terminal_rounded;
        break;
      case 'codechef':
        platformColor = const Color(0xFFE08D2D);
        platformIcon = Icons.ramen_dining_rounded;
        break;
      default:
        platformColor = theme.colorScheme.primary;
        platformIcon = Icons.event_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSecondaryBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.12),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Side accent bar
              Container(width: 6, color: platformColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(platformIcon, size: 14, color: platformColor),
                          const SizedBox(width: 8),
                          Text(
                            contest.platform.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: platformColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          if (isPast)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'COMPLETED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (contest.startsSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.fireplace_rounded,
                                    size: 13,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Starts Soon',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        contest.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _ContestDetailLabel(
                              icon: Icons.calendar_month_rounded,
                              label: DateFormat(
                                'MMM d, yyyy',
                              ).format(contest.startTime),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _ContestDetailLabel(
                              icon: Icons.access_time_filled_rounded,
                              label: DateFormat(
                                'hh:mm a',
                              ).format(contest.startTime),
                            ),
                          ),
                          _ContestDetailLabel(
                            icon: Icons.timer_rounded,
                            label: _formatDuration(contest.duration),
                          ),
                        ],
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

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return m > 0 ? '$h hr $m m' : '$h hr';
    }
    return '${d.inMinutes} m';
  }
}

class _ContestDetailLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContestDetailLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


