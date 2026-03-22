import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';

class PlatformQuickStatsGrid extends StatelessWidget {
  final Map<String, dynamic> leetcode;
  final Map<String, dynamic> github;
  final Map<String, dynamic> codeforces;
  final Map<String, dynamic> codechef;
  final Map<String, dynamic> gfg;
  final Map<String, dynamic> hackerrank;
  final VoidCallback? onLeetCodeTap;
  final VoidCallback? onGitHubTap;
  final VoidCallback? onCodeforcesTap;
  final VoidCallback? onCodeChefTap;
  final VoidCallback? onGfgTap;
  final VoidCallback? onHackerRankTap;

  const PlatformQuickStatsGrid({
    super.key,
    required this.leetcode,
    required this.github,
    required this.codeforces,
    required this.codechef,
    required this.gfg,
    required this.hackerrank,
    this.onLeetCodeTap,
    this.onGitHubTap,
    this.onCodeforcesTap,
    this.onCodeChefTap,
    this.onGfgTap,
    this.onHackerRankTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15, // Better aspect ratio for mobile
      children: [
        _platformCard(
          context,
          'LeetCode',
          FontAwesomeIcons.code,
          AppTheme.leetCodeYellow,
          [
            '${leetcode['solved'] ?? 0} Solved',
            'E: ${leetcode['easy'] ?? 0} M: ${leetcode['medium'] ?? 0}',
          ],
          onLeetCodeTap,
        ),
        _platformCard(
          context,
          'GitHub',
          FontAwesomeIcons.github,
          AppTheme.githubGrey,
          [
            '${github['repos'] ?? 0} Repos',
            '${github['commits'] ?? 0} Contributions', // Fixed: more precise label
          ],
          onGitHubTap,
        ),
        _platformCard(
          context,
          'Codeforces',
          Icons.trending_up,
          Colors.blueAccent,
          [
            'Rating: ${codeforces['rating'] ?? 'N/A'}',
            'Rank: ${codeforces['rank'] ?? 'N/A'}',
          ],
          onCodeforcesTap,
        ),
        _platformCard(
          context,
          'CodeChef',
          Icons.restaurant_menu,
          Colors.brown,
          [
            'Rating: ${codechef['rating'] ?? 'N/A'}',
            'Global: ${codechef['rank'] ?? 'N/A'}',
          ],
          onCodeChefTap,
        ),
        _platformCard(
          context,
          'GeeksforGeeks',
          Icons.school,
          Colors.green,
          [
            'Solved: ${gfg['solved'] ?? 0}',
            'Score: ${gfg['score'] ?? 0}',
          ],
          onGfgTap,
        ),
        _platformCard(
          context,
          'HackerRank',
          FontAwesomeIcons.hackerrank,
          const Color(0xFF2EC866),
          [
            'Solved: ${hackerrank['solved'] ?? 0}',
            'Rank: ${hackerrank['rank'] ?? 'N/A'}',
          ],
          onHackerRankTap,
        ),
      ],
    );
  }

  Widget _platformCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<String> stats,
    VoidCallback? onTap,
  ) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16), // Slightly reduced padding for grid
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FaIcon(icon, color: color, size: (constraints.maxHeight * 0.18).clamp(16, 20)),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...stats.map((s) => Flexible(
                    child: Text(
                      s,
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}
