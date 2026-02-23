// 

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/stats_provider.dart';

import 'sections/welcome_section.dart';
import '../../screens/home/sections/platform_section.dart';
import '../home/sections/stats_section.dart';
import '../home/sections/difficulty_section.dart';
// import 'sections/refresh_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final stats = context.watch<StatsProvider>();
    final theme= Theme.of(context);

    final userName = auth.user?["name"] ?? "User";
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeSphere'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.read<ProfileProvider>().clearProfile();
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeSection(userName: userName, theme: theme, isSmallScreen: isSmallScreen),

              const SizedBox(height: 24),

              PlatformSection(profile: profile, isSmallScreen: isSmallScreen),

              const SizedBox(height: 24),

              StatsSection(stats: stats, theme: theme, isSmallScreen: isSmallScreen),

              const SizedBox(height: 24),

              DifficultySection(stats: stats),

              const SizedBox(height: 24),

              Center( 
                child: SizedBox( 
                  width: isSmallScreen ? double.infinity : null, 
                    child: FilledButton.icon( 
                      onPressed: () { 
                        final username = profile.profile?["leetcode"] ?? ""; 
                        context.read<StatsProvider>().fetchLeetCodeStats(username); 
                        },
                         icon: const Icon(Icons.refresh), 
                         label: const Text('Refresh Stats'), 
                         style: FilledButton.styleFrom( 
                          padding: EdgeInsets.symmetric( 
                            vertical: isSmallScreen ? 14 : 12, 
                            horizontal: isSmallScreen ? 16 : 24, 
                            ), 
                          ),
                         ),
                         ),
            ],
          ),
        ),
      ),
    );
  }
}