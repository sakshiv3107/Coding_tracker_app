import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final userName = auth.user?["name"] ?? "User";
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeSphere'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.read<ProfileProvider>().clearProfile();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        backgroundColor: theme.colorScheme.surface,
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // placeholder for refresh logic
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $userName',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keep coding and ship features!',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.settings,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text('Connected Platforms', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),

                Column(
                  children: [
                    _platformTile(
                      context,
                      'LeetCode',
                      profile.profile?['leetcode'] ?? '',
                    ),
                    _platformTile(
                      context,
                      'CodeChef',
                      profile.profile?['codechef'] ?? '',
                    ),
                    _platformTile(
                      context,
                      'CodeForces',
                      profile.profile?['codeforces'] ?? '',
                    ),
                    _platformTile(
                      context,
                      'GitHub',
                      profile.profile?['github'] ?? '',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text('Overall Stats', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _statCard(context, 'Total Problems', '0', Icons.list_alt),
                    _statCard(
                      context,
                      'Current Streak',
                      '0',
                      Icons.local_fire_department,
                    ),
                    _statCard(context, 'Contests', '0', Icons.emoji_events),
                    _statCard(context, 'Commits', '0', Icons.code),
                  ],
                ),

                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Stats'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _platformTile(BuildContext context, String platform, String id) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.code,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          platform,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          id.isNotEmpty ? id : 'Not connected',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: id.isNotEmpty
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
