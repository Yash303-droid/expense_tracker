// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/features/home/pages/homepage.dart';
import 'package:expense_tracker/features/auth/modern_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDark') ?? false;

  try {
    await Supabase.initialize(
      url: 'https://unrvcyleaklgziglwjif.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVucnZjeWxlYWtsZ3ppZ2x3amlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5MDQ0NDgsImV4cCI6MjA4MTQ4MDQ0OH0.MRa_6qBrLIkZ2QDDhpa2Ekwx8N993KhhsiyWS8cA9L0',
    );
    runApp(MyApp(isDarkMode: isDarkMode));
  } catch (e) {
    // If Supabase initialization fails, show an error screen instead of crashing.
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('App failed to initialize: $e')),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  // Toggle Function: Switch dabane par ye chalega
  void _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pocket Tracker',
      
      // 2. THEME SETUP
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // A. Light Theme Settings
      // Using ColorScheme.fromSeed is the modern Material 3 approach.
      // It generates a full, consistent, and stable color palette.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
      ),
      
      // B. Dark Theme Settings
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
      ),

      // 3. Pass Toggle Function to HomePage
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // Handle error state
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text('Authentication Error: ${snapshot.error}')));
          }

          // Use session data from the stream's snapshot
          final session = snapshot.data?.session;
          if (session != null) { // User is logged in
            return Homepage(toggleTheme: _toggleTheme, isDark: _isDarkMode);
          }
          return const ModernLoginScreen();
        },
      ),
    );
  }
}