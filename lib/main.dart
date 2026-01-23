// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/features/home/pages/homepage.dart';
import 'package:expense_tracker/features/auth/modern_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
     url: 'https://unrvcyleaklgziglwjif.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVucnZjeWxlYWtsZ3ppZ2x3amlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5MDQ0NDgsImV4cCI6MjA4MTQ4MDQ0OH0.MRa_6qBrLIkZ2QDDhpa2Ekwx8N993KhhsiyWS8cA9L0',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // State variable: Default Light Mode
  bool _isDarkMode = false;

  // Toggle Function: Switch dabane par ye chalega
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pocket Tracker',
      
      // 2. THEME SETUP
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // A. Light Theme Settings
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.purple,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple, 
          foregroundColor: Colors.white
        ),
      ),
      
      // B. Dark Theme Settings
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        primaryColor: Colors.lightBlueAccent,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep Black/Grey
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900], 
          foregroundColor: Colors.white
        ),
        
      ),

      // 3. Pass Toggle Function to HomePage
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return Homepage(toggleTheme: _toggleTheme, isDark: _isDarkMode);
          }
          return const ModernLoginScreen();
        },
      ),
    );
  }
}