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
import 'screens/coding_stats_screen.dart';
import 'screens/github_stats_screen.dart';
import 'firebase_options.dart';
import '../theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => GithubProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        // Stream provider for real-time auth state
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodeSphere',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      routes: {
        '/leetcode_stats': (context) => const CodingStatsScreen(),
        '/github_stats': (context) => const GitHubStatsScreen(),
      },
    );
  }
}
