import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/resume_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/responsive_card.dart';

class ResumeScreen extends StatelessWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resume = context.watch<ResumeProvider>();
    final stats = context.watch<StatsProvider>();
    final github = context.watch<GithubProvider>();
    final auth = context.watch<AuthProvider>();

    final totalSolved = stats.totalSolved;
    final leetcodeSolved = stats.leetcodeStats?.totalSolved ?? 0;
    final githubCommits = github.githubStats?.totalContributions ?? 0;
    final githubStars = github.githubStats?.totalStars ?? 0;
    
    final candidateName = auth.user?['name'] ?? 'Candidate';

    // Auto-generate coding summary string for AI
    final codingProfileData = """
    Platforms: LeetCode (Solved: $leetcodeSolved, Ranking: ${stats.leetcodeStats?.ranking ?? 'N/A'}, Contest Rating: ${stats.leetcodeStats?.contestRating ?? 'N/A'}), 
    GitHub (Contributions: $githubCommits, Stars: $githubStars), 
    HackerRank (Solved: ${stats.hackerrankStats?.totalSolved ?? 0}, Rank: ${stats.hackerrankStats?.ranking ?? 'N/A'}).
    """;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── A. Upload Section ───────────────────────────────────────────
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   Icon(
                    resume.resumePath != null || resume.resumeUrl != null 
                        ? Icons.check_circle_rounded 
                        : Icons.cloud_upload_outlined, 
                    size: 48, 
                    color: resume.resumePath != null || resume.resumeUrl != null ? Colors.green : AppTheme.primary
                  ),
                  const SizedBox(height: 12),
                  const Text('Upload your Resume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('AI will extract performance data and generate a professional summary PDF.', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
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
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('Pick PDF'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showLinkDialog(context, resume),
                          icon: const Icon(Icons.link_rounded),
                          label: const Text('Add Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (resume.resumePath != null || resume.resumeUrl != null) ...[
                    const Divider(height: 32),
                    ListTile(
                      leading: Icon(
                        resume.isPdf ? Icons.picture_as_pdf : Icons.link,
                        color: AppTheme.accent,
                      ),
                      title: Text(
                        resume.isPdf ? 'PDF Uploaded' : 'Link Added',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        resume.isPdf ? resume.resumePath!.split(Platform.pathSeparator).last : resume.resumeUrl!,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => resume.clearResume(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!resume.isAnalyzing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => resume.analyzeResume(
                            codingProfileData, 
                            candidateName: candidateName,
                            stats: {
                              'leetcode': leetcodeSolved,
                              'github': githubCommits,
                              'hackerrank': stats.hackerrankStats?.totalSolved ?? 0,
                            }
                          ),
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: Text(resume.resumeSummary == null ? 'Analyze Resume' : 'Re-analyze'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── B. AI Results & Processing ──────────────────────────────
            if (resume.isAnalyzing) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.accent),
                    SizedBox(height: 16),
                    Text('Analysing skills & generating PDF...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ] else if (resume.analysisError != null) ...[
               _buildErrorCard(resume.analysisError!),
               const SizedBox(height: 32),
            ] else if (resume.resumeSummary != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI Analysis Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (resume.generatedPdfPath != null)
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _openPdf(context, resume.generatedPdfPath!),
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          label: const Text('View PDF', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Share.shareXFiles(
                            [XFile(resume.generatedPdfPath!)],
                            subject: 'CodeSphere Resume Analysis',
                          ),
                          icon: const Icon(Icons.share, color: AppTheme.primary, size: 20),
                          tooltip: 'Share Analysis',
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // ATS Score Card
              if (resume.atsScore != null) ...[
                _buildAtsScoreCard(theme, resume.atsScore!),
                const SizedBox(height: 16),
              ],

              _buildAISummaryCard(context, 'CANDIDATE SUMMARY', resume.resumeSummary!),
              const SizedBox(height: 16),
              if (resume.recommendations != null)
                _buildAISummaryCard(context, 'RECOMMENDATIONS FOR IMPROVEMENT', resume.recommendations!, icon: Icons.lightbulb_outline),
              const SizedBox(height: 16),
              _buildAISummaryCard(context, 'CODING EXPERTISE', resume.codingSummary!, isCoding: true),
              const SizedBox(height: 32),      
            ],

            // ── C. Portfolio Stats Grid ──────────────────────────────────
            const Text('Platform Highlights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                ResponsiveCard(label: 'Total Solved', value: '$totalSolved', icon: Icons.check_circle_rounded),
                ResponsiveCard(label: 'LeetCode AC', value: '$leetcodeSolved', icon: Icons.code_rounded),
                ResponsiveCard(label: 'GH Contributions', value: '$githubCommits', icon: Icons.commit_rounded),
                ResponsiveCard(label: 'Github Stars', value: '$githubStars', icon: Icons.star_rounded),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAtsScoreCard(ThemeData theme, String scoreStr) {
    final score = int.tryParse(scoreStr) ?? 0;
    final color = score > 80 ? Colors.green : (score > 50 ? Colors.orange : Colors.red);
    
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 64,
                width: 64,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.1),
                  color: color,
                ),
              ),
              Text(
                '$score',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATS Optimization Score',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Higher scores indicate better keyword matching and structure for automated screening.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISummaryCard(BuildContext context, String title, String content, {bool isCoding = false, IconData? icon}) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon ?? (isCoding ? Icons.terminal : Icons.person), size: 16, color: AppTheme.accent),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.accent)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(height: 1.6, fontSize: 14)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _openPdf(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Summary PDF')),
          body: SfPdfViewer.file(File(path)),
        ),
      ),
    );
  }

  void _showLinkDialog(BuildContext context, ResumeProvider resume) {
    final controller = TextEditingController(text: resume.resumeUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Portfolio Link'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://...', prefixIcon: Icon(Icons.link)),
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
      ),
    );
  }
}

