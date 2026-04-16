  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'dart:io';
  import 'package:url_launcher/url_launcher.dart';

  // Screens
  import 'screens/auth_wrapper.dart';
  import 'screens/leetcode_stats_screen.dart';
  import 'screens/github_stats_screen.dart';
  import 'screens/codeforces_stats_screen.dart';
  import 'screens/codechef_stats_screen.dart';
  import 'screens/settings_screen.dart';
  import 'screens/edit_profile_screen.dart';
  import 'screens/hackerrank_stats_screen.dart';
  import 'screens/resume_screen.dart';
  import 'screens/contest_calendar_screen.dart';
  import 'screens/activity_tracking_screen.dart';
  import 'screens/review_screen.dart';
  import 'screens/goals_screen.dart';

  // Providers
  import 'providers/auth_provider.dart';
  import 'providers/profile_provider.dart';
  import 'providers/stats_provider.dart';
  import 'providers/github_provider.dart';
  import 'providers/goal_provider.dart';
  import 'providers/achievement_provider.dart';
  import 'providers/resume_provider.dart';
  import 'providers/theme_provider.dart';
  import 'providers/gamification_provider.dart';
  import 'providers/skill_provider.dart';
  import 'screens/ai_insight_coach_screen.dart';

  // Services
  import 'services/ota_service.dart';
  import 'services/notification_service.dart';
  import 'services/streak_monitor_service.dart';
  import 'screens/settings/notification_settings_screen.dart';

  import 'services/notification_permission_service.dart';

  import 'firebase_options.dart';
  import 'theme/app_theme.dart';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Only critical blocking initialization
    await dotenv.load(fileName: ".env");
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        debugPrint('Firebase already initialized');
      } else {
        rethrow;
      }
    }

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
          ChangeNotifierProxyProvider<StatsProvider, GamificationProvider>(
            create: (context) => GamificationProvider(Provider.of<StatsProvider>(context, listen: false)),
            update: (context, stats, previous) => GamificationProvider(stats),
          ),
          ChangeNotifierProxyProvider<StatsProvider, SkillProvider>(
            create: (context) => SkillProvider(Provider.of<StatsProvider>(context, listen: false)),
            update: (context, stats, previous) => SkillProvider(stats),
          ),
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
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        home: const _AppEntry(),
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
          '/activity_heatmap': (context) => const ActivityTrackingScreen(),
          '/review': (context) => const ReviewScreen(),
          '/ai-coach': (context) => const AIInsightCoachScreen(),
          '/goals': (context) => const GoalsScreen(),
          '/notification_settings': (context) => const NotificationSettingsScreen(),
        },
      ); 
    }
  }

  class MyHttpOverrides extends HttpOverrides {
    @override
    HttpClient createHttpClient(SecurityContext? context) {
      return super.createHttpClient(context)
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
    }
  }

  class _AppEntry extends StatefulWidget {
    const _AppEntry();

    @override
    State<_AppEntry> createState() => _AppEntryState();
  }

  class _AppEntryState extends State<_AppEntry> {
    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _deferredInit();
      });
    }

    // ✅ All non-critical init happens AFTER engine is ready
    Future<void> _deferredInit() async {
      if (!mounted) return;
      
      // Set HttpOverrides after engine is running
      HttpOverrides.global = MyHttpOverrides();
      
      // Initialize services in background
      try {
        await NotificationService.instance.initialize();
        await StreakMonitorService.initialize();
        await StreakMonitorService.scheduleTask();
      } catch (e) {
        debugPrint('Background service init failed: $e');
      }

      // Check for updates
      if (mounted) {
        _checkUpdateAndHandle();
        NotificationPermissionService.checkAndRequestPermission(context);
      }
    }

    Future<void> _checkUpdateAndHandle() async {
    final data = await OTAService.checkForUpdate();
    if (data == null || !mounted) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _UpdateDialog(data: data),
      );
    }
  }

    @override
    Widget build(BuildContext context) => const AuthWrapper();
  }

  class _UpdateDialog extends StatefulWidget {
    final Map<String, dynamic> data;
    const _UpdateDialog({required this.data});

    @override
    State<_UpdateDialog> createState() => _UpdateDialogState();
  }

  class _UpdateDialogState extends State<_UpdateDialog> {


    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🚀  '),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v${widget.data['version'] ?? ''}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.data['changelog'] ?? 'Bug fixes and improvements.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          // In _UpdateDialogState's build method, replace the ElevatedButton onPressed:

          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(OTAService.readmeUrl); // ← changed
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                debugPrint('Could not launch update URL: $e');
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View on GitHub'),  // ← label updated for clarity
          ),
                  ],
      );
    }
  }



