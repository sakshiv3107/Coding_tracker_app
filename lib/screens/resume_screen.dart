import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../providers/resume_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
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

    final totalSolved = stats.totalSolved;
    final leetcodeSolved = stats.leetcodeStats?.totalSolved ?? 0;
    final githubCommits = github.githubStats?.totalContributions ?? 0;
    final githubStars = github.githubStats?.totalStars ?? 0;
    
    // Fallback template summary
    final summary = "Solved $totalSolved+ problems across platforms with a strong focus on Data Structures and Algorithms. "
        "Completed $leetcodeSolved+ LeetCode problems and maintained a consistent GitHub activity with over $githubCommits contributions.";

    // Auto-generate coding summary string for AI
    final codingProfileData = """
    Platforms: LeetCode (Solved: $leetcodeSolved, Ranking: ${stats.leetcodeStats?.ranking ?? 'N/A'}, Contest Rating: ${stats.leetcodeStats?.contestRating ?? 'N/A'}), 
    GitHub (Contributions: $githubCommits, Stars: $githubStars), 
    HackerRank (Solved: ${stats.hackerrankStats?.totalSolved ?? 0}, Rank: ${stats.hackerrankStats?.rank ?? 'N/A'}).
    """;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Mode', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('Add your PDF or portfolio link to generate AI summaries', textAlign: TextAlign.center),
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
                              resume.setResumeFile(result.files.single.path!);
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('Pick PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                          ),
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
                        resume.isPdf ? resume.resumePath!.split('\\').last : resume.resumeUrl!,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => resume.clearResume(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action button to trigger AI analysis
                    if (!resume.isAnalyzing && resume.resumeSummary == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => resume.analyzeResume(codingProfileData),
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Generate AI Summaries'),
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

            // ── B. AI Summaries (Split into Two) ──────────────────────────
            if (resume.isAnalyzing) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI is analyzing your profile...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ] else if (resume.analysisError != null) ...[
               Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(resume.analysisError!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ] else if (resume.resumeSummary != null || resume.codingSummary != null) ...[
              // B1. Resume Summary
              const Text('Resume-Based Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildAISummaryCard(context, resume.resumeSummary ?? "Resume summary not available."),
              
              const SizedBox(height: 24),
              
              // B2. Coding Summary
              const Text('Coding Profile Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildAISummaryCard(context, resume.codingSummary ?? "Coding summary not available.", isCodingSummary: true),

              const SizedBox(height: 32),
            ] else ...[
              // C. General Coding Summary (Fallback if no AI run yet)
              const Text('Suggested Summary (Template)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ModernCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      summary,
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ── C. Portfolio Auto-fill ──────────────────────────────────────
            const Text('Portfolio Highlights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2, // Balanced height for responsive layout
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

  Widget _buildAISummaryCard(BuildContext context, String content, {bool isCodingSummary = false}) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isCodingSummary ? Icons.terminal_rounded : Icons.person_search_rounded,
                size: 20,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 8),
              const Text('AI POWERED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.accent)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(height: 1.6, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy'),
            ),
          ),
        ],
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
          decoration: const InputDecoration(
            hintText: 'https://github.com/your-username',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                resume.setResumeUrl(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
