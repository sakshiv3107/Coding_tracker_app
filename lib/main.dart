import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../screens/auth_wrapper.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/resume_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/insights_provider.dart';
import '../services/notification_service.dart';
import '../services/smart_reminder_service.dart';
import '../services/background_task_service.dart';
import 'screens/leetcode_stats_screen.dart';
import 'screens/github_stats_screen.dart';
import 'screens/codeforces_stats_screen.dart';
import 'screens/codechef_stats_screen.dart';

import 'screens/settings_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/hackerrank_stats_screen.dart';
import 'screens/resume_screen.dart';
import 'screens/contest_calendar_screen.dart';
import 'firebase_options.dart';
import '../theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized');
    } else {
      rethrow;
    }
  }
  
  // Initialize Services
  await NotificationService.init();
  await SmartReminderService.init();
  await BackgroundTaskService.init();
  await BackgroundTaskService.schedulePeriodicTasks();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => GithubProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()..init()),
        ChangeNotifierProvider(create: (_) => ResumeProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => InsightsProvider()),
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodeSphere',
      theme: AppTheme.lightTheme(themeProvider.primaryColor),
      darkTheme: AppTheme.darkTheme(themeProvider.primaryColor),
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
      routes: {
        '/leetcode_stats': (context) => const CodingStatsScreen(),
        '/github_stats': (context) => const GitHubStatsScreen(),
        '/codeforces_stats': (context) => const CodeforcesStatsScreen(),
        '/codechef_stats': (context) => const CodeChefStatsScreen(),

        '/hackerrank_stats': (context) => const HackerRankStatsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/resume': (context) => const ResumeScreen(),
        '/contests': (context) => const ContestCalendarScreen(),
      },
    );
  }
}
