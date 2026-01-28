// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/features/home/pages/homepage.dart';
import 'package:expense_tracker/features/auth/modern_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://unrvcyleaklgziglwjif.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVucnZjeWxlYWtsZ3ppZ2x3amlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5MDQ0NDgsImV4cCI6MjA4MTQ4MDQ0OH0.MRa_6qBrLIkZ2QDDhpa2Ekwx8N993KhhsiyWS8cA9L0',
    );
    runApp(const MyApp());
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
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isDarkMode = false; // Default to light theme

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes. This stream fires an event immediately
    // with the current auth state, covering the initial app launch and any
    // subsequent login/logout events.
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      _loadTheme();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  // 1. Load Theme from Supabase
  Future<void> _loadTheme() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // When user is logged out, reset to the default (light) theme.
      if (mounted) setState(() => _isDarkMode = false);
      return;
    }

    try {
      final data = await _supabase
          .from('users_settings')
          .select('is_dark')
          .eq('user_id', user.id)
          .maybeSingle(); // Use maybeSingle in case row doesn't exist yet

      // Check if the widget is still in the tree before calling setState.
      if (mounted) {
        setState(() {
          // Use null-aware operator on the map itself.
          _isDarkMode = data?['is_dark'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Theme Load Error: $e");
      // On error, we can choose to do nothing and keep the current theme.
    }
  }

  // 2. Toggle & Save to Supabase
  Future<void> _toggleTheme() async {
    // Optimistically update the UI
    final newIsDarkMode = !_isDarkMode;
    setState(() => _isDarkMode = newIsDarkMode);

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('users_settings').upsert({
          'user_id': user.id,
          'is_dark': newIsDarkMode, // Save new value
          // We don't mention monthly_limit here, upsert will keep it if it exists
        });
      } catch (e) {
        debugPrint("Theme Save Error: $e");
        // If saving fails, revert the UI and show an error message.
        if (mounted) {
          setState(() => _isDarkMode = !newIsDarkMode); // Revert
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to save theme preference.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinWiz',
      // === THEME LOGIC ===
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212), // Nice Dark Grey
      ),
      // ===================
      
      // Use a StreamBuilder to reactively switch between the login screen and
      // the home page. This is the key to making login/logout feel instant.
      home: StreamBuilder<AuthState>(
        stream: _supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Show a loading indicator while waiting for the first auth event.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // If a user session exists, show the homepage.
          if (snapshot.hasData && snapshot.data?.session != null) {
            return Homepage(toggleTheme: _toggleTheme, isDark: _isDarkMode);
          }
          // Otherwise, show the login screen.
          return const ModernLoginScreen();
        },
      ),
          
      routes: {
        '/login': (context) => const ModernLoginScreen(),
        '/home': (context) => Homepage(toggleTheme: _toggleTheme, isDark: _isDarkMode),
      },
    );
  }
}