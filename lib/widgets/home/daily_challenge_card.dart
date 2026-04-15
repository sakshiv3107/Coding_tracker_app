import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/proxy_service.dart';
import '../../providers/skill_provider.dart';
import '../../theme/app_theme.dart';
import '../glass_card.dart';
import '../../providers/stats_provider.dart';

class DailyChallengeCard extends StatefulWidget {
  const DailyChallengeCard({super.key});

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard> {
  Map<String, dynamic>? _challenge;
  bool _isLoading = true;
  bool _isSolved = false;
  String _fallbackTopic = 'Arrays';

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    final challenge = await ProxyService.getDailyChallenge();
    if (!mounted) return;
    final skillProvider = Provider.of<SkillProvider>(context, listen: false);
    // statsProvider was unused, removing it

    if (challenge != null) {
      if (mounted) {
        setState(() {
          _challenge = challenge;
          _isLoading = false;
        });
      }
      _checkIfSolved(challenge['question']['title']);
    } else {
      if (mounted) {
        setState(() {
          _fallbackTopic = skillProvider.weakestTopic;
          _isLoading = false;
        });
      }
    }
  }

  void _checkIfSolved(String title) {
    final statsProvider = Provider.of<StatsProvider>(context, listen: false);
    final subs = statsProvider.leetcodeStats?.recentSubmissions ?? [];
    bool solved = subs.any((s) => s.title == title && s.status == 'Accepted');
    if (solved && mounted) {
      setState(() {
        _isSolved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();

    final challenge = _challenge;
    final title = challenge != null ? challenge['question']['title'] : "Master $_fallbackTopic";
    final difficulty = challenge != null ? challenge['question']['difficulty'] : "Medium";
    final tags = (challenge != null && challenge['question']['topicTags'] != null)
        ? (challenge['question']['topicTags'] as List).map((t) => t['name'].toString()).toList()
        : [_fallbackTopic, 'Practice'];
    final url = challenge != null ? "https://leetcode.com${challenge['link']}" : "https://leetcode.com/problemset/all/?topicSlugs=${_fallbackTopic.toLowerCase()}";

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Color(0xFFEF9F27), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Today's Challenge",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF9F27),
                    ),
                  ),
                ],
              ),
              _buildDifficultyBadge(difficulty),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: tags.map((t) => _buildTag(t)).toList(),
          ),
          const SizedBox(height: 20),
          if (_isSolved)
            _buildSolvedState()
          else
            _buildCTA(url, context),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy': color = const Color(0xFF1D9E75); break;
      case 'hard': color = const Color(0xFFE24B4A); break;
      default: color = const Color(0xFFEF9F27);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Text(
        tag,
        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildCTA(String url, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          
        ),
        onPressed: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('opened_challenge_${DateFormat('yyyyMMdd').format(DateTime.now())}', true);
          }
        },
        child: Text(
          "Solve Now",
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSolvedState() {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 20),
        const SizedBox(width: 8),
        Text(
          "Solved today — come back tomorrow",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1D9E75),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const GlassCard(
      height: 180,
      borderRadius: 16,
      child: Center(child: CircularProgressIndicator(color: AppTheme.darkAccent)),
    );
  }
}


