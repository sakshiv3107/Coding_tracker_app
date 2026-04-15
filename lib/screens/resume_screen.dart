import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/resume_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/resume_analyzer/upload_card.dart';
import '../widgets/resume_analyzer/analyze_button.dart';
import '../widgets/resume_analyzer/score_card.dart';
import '../widgets/resume_analyzer/insight_card.dart';
import '../widgets/resume_analyzer/error_card.dart';

class ResumeScreen extends StatelessWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resume = context.watch<ResumeProvider>();
    final stats = context.watch<StatsProvider>();
    final github = context.watch<GithubProvider>();
    final auth = context.watch<AuthProvider>();

    final leetcodeSolved = stats.leetcodeStats?.totalSolved ?? 0;
    final githubCommits = github.githubStats?.totalContributions ?? 0;
    // final githubStars = github.githubStats?.totalStars ?? 0;

    final candidateName = auth.user?['name'] ?? 'Candidate';

    // final codingProfileData =
    //     """
    // Platforms: LeetCode (Solved: $leetcodeSolved, Ranking: ${stats.leetcodeStats?.ranking ?? 'N/A'}, Contest Rating: ${stats.leetcodeStats?.contestRating ?? 'N/A'}), 
    // GitHub (Contributions: $githubCommits, Stars: $githubStars), 
    // HackerRank (Solved: ${stats.hackerrankStats?.totalSolved ?? 0}, Rank: ${stats.hackerrankStats?.ranking ?? 'N/A'}).
    // """;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false, // Don't extend so we have a cleaner top
      body: Stack(
        children: [
          // ── Background Decorative Elements ──────────────────────────
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.08),
              ),
            ).animate().fadeIn(duration: 2.seconds).scale(begin: const Offset(0.5, 0.5)),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withOpacity(0.05),
              ),
            ).animate().fadeIn(duration: 3.seconds).scale(begin: const Offset(0.8, 0.8)),
          ),

          // ── Main Content ─────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Section ───────────────────────────────────────────
                _buildHeader(theme),
                const SizedBox(height: 24),

                // ── Upload Section ─────────────────────────────────────────────
                UploadCard(
                  filePath: resume.resumePath,
                  url: resume.resumeUrl,
                  isPdf: resume.isPdf,
                  onPickPdf: () => _pickPdf(context, resume),
                  onAddLink: () => _showLinkDialog(context, resume),
                  onRemove: () => resume.clearResume(),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // ── Analyze Button ─────────────────────────────────────────────
                if (resume.resumePath != null || resume.resumeUrl != null)
                  AnalyzeButton(
                    isLoading: resume.isAnalyzing,
                    text: resume.resumeSummary == null
                        ? 'Analyze Resume'
                        : 'Re-analyze Resume',
                    onPressed: () => resume.analyzeResume(
                      candidateName: candidateName,
                      stats: {
                        'leetcode': leetcodeSolved,
                        'github': githubCommits,
                        'hackerrank': stats.hackerrankStats?.totalSolved ?? 0,
                      },
                    ),
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 32),

                // ── Results UI ────────────────────────────────────────────────
                if (resume.analysisError != null)
                  ErrorCard(
                    message: resume.analysisError!,
                    onRetry: () =>
                        resume.analyzeResume(candidateName: candidateName),
                  )
                else if (resume.resumeSummary != null && !resume.isAnalyzing) ...[
                  _buildResultsHeader(context, theme, resume)
                      .animate()
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: 20),

                  // Score Overall
                  if (resume.atsScore != null)
                    ScoreCard(
                      score: int.tryParse(resume.atsScore!) ?? 75,
                    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 32),

                  // AI Insights
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "AI Insights",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  _buildInsightSections(
                    theme,
                    resume.resumeSummary!,
                    Icons.flare_rounded,
                    hideTitle: true,
                  ),

                  const SizedBox(height: 16),

                  // Improvement Suggestions
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Recommendations",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  _buildInsightSections(
                    theme,
                    resume.recommendations ?? "",
                    Icons.tips_and_updates_rounded,
                    isRecommendation: true,
                  ),

                  const SizedBox(height: 48),
                ] else if (!resume.isAnalyzing &&
                    resume.resumePath == null &&
                    resume.resumeUrl == null)
                  _buildEmptyState(theme)
                else if (resume.isAnalyzing)
                  _buildAnalyzingState(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "AI Resume Analyzer",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Get expert AI feedback on your resume",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildResultsHeader(
    BuildContext context,
    ThemeData theme,
    ResumeProvider resume,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Analysis Results",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (resume.generatedPdfPath != null)
          Row(
            children: [
              IconButton(
                onPressed: () => _openPdf(context, resume.generatedPdfPath!),
                icon: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                tooltip: 'View Report',
              ),
              IconButton(
                onPressed: () => Share.shareXFiles([
                  XFile(resume.generatedPdfPath!),
                ], subject: 'CodeSphere Resume Analysis'),
                icon: Icon(
                  Icons.share_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                tooltip: 'Share Analysis',
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInsightSections(
    ThemeData theme,
    String content,
    IconData icon, {
    bool isRecommendation = false,
    bool hideTitle = false,
  }) {
    if (isRecommendation) {
      // For recommendations, we split by double newline blocks to keep cat/issue/fix together
      final blocks = content.split('\n\n').where((b) => b.trim().isNotEmpty).toList();

      return Column(
        children: blocks.map((block) {
          final lines = block.split('\n').where((l) => l.trim().isNotEmpty).toList();
          if (lines.isEmpty) return const SizedBox.shrink();

          // Heading: e.g., "[HIGH] Action Verbs"
          final header = lines.first.trim();

          // Body: The rest of the lines (issue & fix) formatted as points
          final bodyLines = lines.skip(1).toList();
          final explanation = bodyLines.isEmpty
              ? ""
              : bodyLines.map((l) {
                  final trimmed = l.trim();
                  // Keep existing markers or add bullet
                  if (trimmed.startsWith('->') ||
                      trimmed.startsWith('•') ||
                      trimmed.startsWith('-')) {
                    return trimmed;
                  }
                  return '• $trimmed';
                }).join('\n');

          // Premium Touch: Color icon based on priority found in header
          Color priorityColor = theme.colorScheme.primary;
          final upperHeader = header.toUpperCase();
          if (upperHeader.contains('[HIGH]')) {
            priorityColor = theme.colorScheme.tertiary; // Rose/Red
          } else if (upperHeader.contains('[MEDIUM]')) {
            priorityColor = const Color(0xFFF97316); // LeetCode Orange
          } else if (upperHeader.contains('[LOW]')) {
            priorityColor = theme.colorScheme.secondary; // Cyan
          }

          return InsightCard(
            icon: icon,
            title: header,
            explanation: explanation,
            iconColor: priorityColor,
          ).animate().fadeIn(delay: (100 * (bodyLines.length)).ms).slideX(begin: 0.05);
        }).toList(),
      );
    }

    // Default logic for Summary points
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Column(
      children: lines.map((line) {
        final cleanLine = line.replaceFirst(RegExp(r'^•\s*'), '').trim();
        final parts = cleanLine.split('—');

        String? title;
        String explanation;

        if (parts.length > 1) {
          title = parts.first.trim();
          explanation = parts.sublist(1).join('—').trim();
        } else {
          explanation = cleanLine;
        }

        return InsightCard(
          icon: icon,
          title: hideTitle ? null : title,
          explanation: explanation,
          iconColor: theme.colorScheme.primary,
        ).animate().fadeIn(delay: (100 * lines.indexOf(line)).ms).slideY(begin: 0.1);
      }).toList(),
    );
  }

  Widget _buildAnalyzingState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.05),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 60,
              color: theme.colorScheme.primary,
            ).animate(onPlay: (c) => c.repeat())
             .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds)
             .rotate(begin: 0, end: 1, duration: 4.seconds)
             .then()
             .shimmer(duration: 2.seconds),
          ),
          const SizedBox(height: 32),
          Text(
            "Analyzing Your Potential...",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Our AI is scanning your profile for the best insights",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.document_scanner_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
          const Text(
            "Upload your resume",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Get instant AI-powered feedback to improve your profile.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Future<void> _pickPdf(BuildContext context, ResumeProvider resume) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (await file.length() > 5 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size exceeds 5MB limit.')),
          );
        }
        return;
      }
      resume.setResumeFile(result.files.single.path!);
    }
  }

  void _showLinkDialog(BuildContext context, ResumeProvider resume) {
    final controller = TextEditingController(text: resume.resumeUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Portfolio Link'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://...',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty)
                {resume.setResumeUrl(controller.text);}
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _openPdf(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Analysis Report')),
          body: SfPdfViewer.file(File(path)),
        ),
      ),
    );
  }
}


