import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class GitHubStatsScreen extends StatefulWidget {
  const GitHubStatsScreen({super.key});

  @override
  State<GitHubStatsScreen> createState() => _GitHubStatsScreenState();
}

class _GitHubStatsScreenState extends State<GitHubStatsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    final githubUsername = profile.profile?["github"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub Stats'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (githubUsername.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_outlined,
                          size: 60,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'GitHub Profile Not Set',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please set your GitHub username in your profile to view your GitHub statistics',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/profile-setup');
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Set GitHub Username'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // GitHub Profile Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.pets,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          githubUsername,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Open GitHub profile in browser
                            // You can use url_launcher package for this
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('View on GitHub'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Coming Soon Section
                Text('Coming Soon', style: theme.textTheme.titleMedium),

                const SizedBox(height: 16),

                _StatCard(
                  title: 'Repositories',
                  value: '—',
                  icon: Icons.folder_outlined,
                  color: Colors.blue,
                ),

                const SizedBox(height: 12),

                _StatCard(
                  title: 'Followers',
                  value: '—',
                  icon: Icons.people_outline,
                  color: Colors.purple,
                ),

                const SizedBox(height: 12),

                _StatCard(
                  title: 'Contributions',
                  value: '—',
                  icon: Icons.favorite_outline,
                  color: Colors.red,
                ),

                const SizedBox(height: 12),

                _StatCard(
                  title: 'Stars',
                  value: '—',
                  icon: Icons.star_outline,
                  color: Colors.amber,
                ),

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    border: Border.all(color: Colors.blue, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'GitHub stats integration is coming soon! More detailed analytics will be available in the next update.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
