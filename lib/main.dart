import 'package:flutter/material.dart';
import 'package:guardian_shield/theme.dart';
import 'package:guardian_shield/screens/main_screen.dart';
import 'package:guardian_shield/screens/login_screen.dart';
import 'package:guardian_shield/services/theme_service.dart';
import 'package:guardian_shield/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeService = ThemeService.instance;

  @override
  void initState() {
    super.initState();
    _themeService.loadTheme();
    _themeService.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeGuard - Danger Alert',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeService.themeMode,
      home: StreamBuilder(
        stream: SupabaseService.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.hasData ? snapshot.data!.session : null;
          return session != null ? const MainScreen() : const LoginScreen();
        },
      ),
    );
  }
}