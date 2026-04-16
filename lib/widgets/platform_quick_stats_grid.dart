import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'home/platform_stat_card.dart';

class PlatformQuickStatsGrid extends StatelessWidget {
  final Map<String, dynamic> leetcode;
  final Map<String, dynamic> github;
  final Map<String, dynamic> codeforces;
  final Map<String, dynamic> codechef;
  final Map<String, dynamic> hackerrank;

  final String? leetcodeError;
  final String? codeforcesError;
  final String? codechefError;
  final String? hackerrankError;

  final bool leetcodeLoading;
  final bool codeforcesLoading;
  final bool codechefLoading;
  final bool hackerrankLoading;
  final bool githubLoading;

  final String leetcodeUsername;
  final String githubUsername;
  final String codeforcesUsername;
  final String codechefUsername;
  final String hackerrankUsername;

  final VoidCallback? onLeetCodeTap;
  final VoidCallback? onGitHubTap;
  final VoidCallback? onCodeforcesTap;
  final VoidCallback? onCodeChefTap;
  final VoidCallback? onHackerRankTap;

  const PlatformQuickStatsGrid({
    super.key,
    required this.leetcode,
    required this.github,
    required this.codeforces,
    required this.codechef,
    required this.hackerrank,
    this.leetcodeError,
    this.codeforcesError,
    this.codechefError,
    this.hackerrankError,
    this.leetcodeLoading = false,
    this.codeforcesLoading = false,
    this.codechefLoading = false,
    this.hackerrankLoading = false,
    this.githubLoading = false,
    this.leetcodeUsername = '',
    this.githubUsername = '',
    this.codeforcesUsername = '',
    this.codechefUsername = '',
    this.hackerrankUsername = '',
    this.onLeetCodeTap,
    this.onGitHubTap,
    this.onCodeforcesTap,
    this.onCodeChefTap,
    this.onHackerRankTap,
  });
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(
            'LeetCode', 
            '${leetcode['solved'] ?? 0}', 
            const Color(0xFFEF9F27), 
            FontAwesomeIcons.code,
            onLeetCodeTap,
            leetcodeLoading
          ),
          _buildChip(
            'GitHub', 
            '${github['repos'] ?? 0}', 
            const Color(0xFF4078c0), 
            FontAwesomeIcons.github,
            onGitHubTap,
            githubLoading
          ),
          _buildChip(
            'Codeforces', 
            '${codeforces['rating'] ?? 'N/A'}', 
            const Color(0xFFE24B4A), 
            FontAwesomeIcons.chartSimple,
            onCodeforcesTap,
            codeforcesLoading
          ),
          _buildChip(
            'CodeChef', 
            '${codechef['rating'] ?? 'N/A'}', 
            const Color(0xFF7B68EE), 
            FontAwesomeIcons.terminal,
            onCodeChefTap,
            codechefLoading
          ),
          _buildChip(
            'HackerRank', 
            '${hackerrank['solved'] ?? 0}', 
            const Color(0xFF2EC866), 
            FontAwesomeIcons.hackerrank,
            onHackerRankTap,
            hackerrankLoading
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String name, String stat, Color color, dynamic icon, VoidCallback? onTap, bool loading) {
    if (loading) {
      return Container(
        margin: const EdgeInsets.only(right: 12),
        width: 140,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF13162A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.03), width: 1),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const Spacer(),
                Container(width: 40, height: 8, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 60, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 2, color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF13162A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.15), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(icon, size: 14, color: color),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white.withOpacity(0.2)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    minHeight: 2,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


