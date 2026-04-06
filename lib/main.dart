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
import '../services/ota_service.dart';
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
import 'firebase_options.dart';
import '../theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ota_update/ota_update.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

// ─── MyApp ────────────────────────────────────────────────────────────────────

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

      // ✅ Use home: with a wrapper that triggers the update check
      //    AFTER MaterialApp's Navigator is ready.
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
      },
    );
  }
}

// ─── _AppEntry ────────────────────────────────────────────────────────────────
// Thin wrapper that lives INSIDE MaterialApp's navigator tree.
// This means showDialog() will always find a valid Navigator.

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    // Wait one frame so the Navigator is fully mounted, then check for updates.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    final data = await OTAService.checkForUpdate();
    if (data == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) => const AuthWrapper();
}

// ─── _UpdateDialog ────────────────────────────────────────────────────────────

class _UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  const _UpdateDialog({required this.data});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress; // null = not started, 0–100 = in progress
  String _status = '';
  bool _isDownloading = false;
  bool _hasFailed = false;

  void _startUpdate() {
    setState(() {
      _isDownloading = true;
      _hasFailed = false;
      _status = 'Starting download...';
    });

    OTAService.startUpdate(widget.data['apk_url']).listen(
      (OtaEvent event) {
        if (!mounted) return;
        setState(() {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              _progress = double.tryParse(event.value ?? '0');
              _status = 'Downloading... ${event.value ?? 0}%';
            case OtaStatus.INSTALLING:
              _progress = null; // indeterminate while installing
              _status = 'Installing update…';
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              _isDownloading = false;
              _hasFailed = true;
              _status =
                  'Permission denied.\nEnable "Install unknown apps" in Settings.';
            case OtaStatus.ALREADY_RUNNING_ERROR:
              _status = 'Update already in progress.';
            case OtaStatus.INTERNAL_ERROR:
              _isDownloading = false;
              _hasFailed = true;
              _status = 'Internal error. Please try again.';
            default:
              _status = 'Status: ${event.status}';
          }
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _isDownloading = false;
          _hasFailed = true;
          _status = 'Download failed. Check your connection.';
        });
        debugPrint('OTA error: $e');
      },
    );
  }

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
          // Version badge
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

          // Changelog
          Text(
            widget.data['changelog'] ?? 'Bug fixes and improvements.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          // Progress section
          if (_isDownloading || _hasFailed) ...[
            const SizedBox(height: 20),
            if (_isDownloading)
              _progress != null
                  ? LinearProgressIndicator(
                      value: _progress! / 100,
                      borderRadius: BorderRadius.circular(4),
                    )
                  : const LinearProgressIndicator(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _hasFailed ? colorScheme.error : null,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        // "Later" — only when not actively downloading
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),

        // "Retry" — shown after failure
        if (_hasFailed)
          ElevatedButton.icon(
            onPressed: _startUpdate,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          )

        // "Update" — initial state
        else if (!_isDownloading)
          ElevatedButton(
            onPressed: _startUpdate,
            child: const Text('Update Now'),
          ),

        // "Hide" — while downloading (lets it continue in background)
        if (_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hide'),
          ),
      ],
    );
  }
}