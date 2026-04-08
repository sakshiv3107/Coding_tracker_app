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
    final githubStars = github.githubStats?.totalStars ?? 0;
    
    final candidateName = auth.user?['name'] ?? 'Candidate';

    final codingProfileData = """
    Platforms: LeetCode (Solved: $leetcodeSolved, Ranking: ${stats.leetcodeStats?.ranking ?? 'N/A'}, Contest Rating: ${stats.leetcodeStats?.contestRating ?? 'N/A'}), 
    GitHub (Contributions: $githubCommits, Stars: $githubStars), 
    HackerRank (Solved: ${stats.hackerrankStats?.totalSolved ?? 0}, Rank: ${stats.hackerrankStats?.ranking ?? 'N/A'}).
    """;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false, // Don't extend so we have a cleaner top
      appBar: AppBar(
        title: const Text('AI Resume Analyzer', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
            ),
            
            const SizedBox(height: 20),

            // ── Analyze Button ─────────────────────────────────────────────
            if (resume.resumePath != null || resume.resumeUrl != null)
              AnalyzeButton(
                isLoading: resume.isAnalyzing,
                text: resume.resumeSummary == null ? 'Analyze Resume' : 'Re-analyze Resume',
                onPressed: () => resume.analyzeResume(
                  codingProfileData, 
                  candidateName: candidateName,
                  stats: {
                    'leetcode': leetcodeSolved,
                    'github': githubCommits,
                    'hackerrank': stats.hackerrankStats?.totalSolved ?? 0,
                  }
                ),
              ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 32),

            // ── Results UI ────────────────────────────────────────────────
            if (resume.analysisError != null)
              ErrorCard(
                message: resume.analysisError!,
                onRetry: () => resume.analyzeResume(
                  codingProfileData, 
                  candidateName: candidateName,
                ),
              )
            else if (resume.resumeSummary != null && !resume.isAnalyzing) ...[
              _buildResultsHeader(context, theme, resume),
              const SizedBox(height: 20),
              
              // Score Overall
              if (resume.atsScore != null)
                ScoreCard(score: int.tryParse(resume.atsScore!) ?? 75)
                    .animate().fadeIn().scale(delay: 100.ms),
              
              const SizedBox(height: 32),

              // AI Insights
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text("AI Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _buildInsightSections(theme, resume.resumeSummary!, Icons.flare_rounded, hideTitle: true),
              
              const SizedBox(height: 16),

              // Improvement Suggestions
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text("Recommendations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _buildInsightSections(theme, resume.recommendations ?? "", Icons.tips_and_updates_rounded, isRecommendation: true),
              
              const SizedBox(height: 48),
            ] else if (!resume.isAnalyzing && resume.resumePath == null && resume.resumeUrl == null)
              _buildEmptyState(theme)
            else if (resume.isAnalyzing)
              const SizedBox.shrink(), 
          ],
        ),
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

  Widget _buildResultsHeader(BuildContext context, ThemeData theme, ResumeProvider resume) {
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
                icon: Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.primary, size: 20),
                tooltip: 'View Report',
              ),
              IconButton(
                onPressed: () => Share.shareXFiles(
                  [XFile(resume.generatedPdfPath!)],
                  subject: 'CodeSphere Resume Analysis',
                ),
                icon: Icon(Icons.share_outlined, color: theme.colorScheme.primary, size: 20),
                tooltip: 'Share Analysis',
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInsightSections(ThemeData theme, String content, IconData icon, {bool isRecommendation = false, bool hideTitle = false}) {
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
          if (isRecommendation) {
            final words = cleanLine.split(' ');
            if (words.length > 4) {
              title = "${words.sublist(0, 4).join(' ')}...";
            } else {
              title = cleanLine;
            }
          }
        }

        return InsightCard(
          icon: icon,
          title: hideTitle ? null : title, 
          explanation: explanation,
          iconColor: theme.colorScheme.primary,
        );
      }).toList(),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) resume.setResumeUrl(controller.text);
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
