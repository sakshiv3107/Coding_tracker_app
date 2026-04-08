import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ota_update/ota_update.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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

// Providers
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/github_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/resume_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/insights_provider.dart';

// Services
import 'services/notification_service.dart';
import 'services/smart_reminder_service.dart';
import 'services/background_task_service.dart';
import 'services/ota_service.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
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
      },
    ); // Added a copyWith just to ensure a fresh state if possible
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

class _UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  const _UpdateDialog({required this.data});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  String _status = '';
  bool _isDownloading = false;
  bool _hasFailed = false;



void _startUpdate() async {
  // ✅ Check & request "Install unknown apps" permission first
  if (!await Permission.requestInstallPackages.isGranted) {
    final status = await Permission.requestInstallPackages.request();
    if (!status.isGranted) {
      setState(() {
        _hasFailed = true;
        _status = 'Permission denied.\nGo to Settings → Install unknown apps → allow CodeSphere.';
      });
      // Open settings so user can enable it
      await openAppSettings();
      return;
    }
  }

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
            break;
          case OtaStatus.INSTALLING:
            _progress = null;
            _isDownloading = false;
            _status = 'Installing update…';
            break;
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            _isDownloading = false;
            _hasFailed = true;
            _status = 'Permission denied.\nEnable "Install unknown apps" in Settings.';
            openAppSettings(); // Auto-open settings
            break;
          case OtaStatus.DOWNLOAD_ERROR:
            _isDownloading = false;
            _hasFailed = true;
            _status = 'Download failed. Check your internet.';
            break;
          case OtaStatus.CHECKSUM_ERROR:
            _isDownloading = false;
            _hasFailed = true;
            _status = 'File corruption detected. Please retry.';
            break;
          case OtaStatus.INTERNAL_ERROR:
            _isDownloading = false;
            _hasFailed = true;
            _status = 'Internal error. Please try again.';
            break;
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
          if (_isDownloading || _hasFailed) ...[
            const SizedBox(height: 20),
            if (_progress != null)
              LinearProgressIndicator(value: _progress! / 100, backgroundColor: colorScheme.surfaceVariant),
            const SizedBox(height: 8),
            Text(_status, style: TextStyle(fontSize: 12, color: _hasFailed ? Colors.red : colorScheme.onSurface)),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
        if (!_isDownloading || _hasFailed)
          ElevatedButton(onPressed: _startUpdate, child: Text(_hasFailed ? 'Retry' : 'Update Now')),
      ],
    );
  }
}