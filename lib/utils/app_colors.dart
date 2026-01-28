import 'package:flutter/material.dart';

class AppColors {
  // Main Theme Colors
  static const Color primary = Colors.purple;
  static const Color seed = Colors.purple;
  static const Color background = Color(0xFF121212);
  static const Color card = Color(0xFF1E1E1E);
  static const Color text = Colors.white;
  static const Color textSecondary = Color(0xFFBDBDBD); // grey[400]
  static const Color textFaded = Color(0xFF757575); // grey[600]

  // Gradients
  static const List<Color> loginGradient = [Color(0xFF121212), Color(0xFF2C2C2C)];

  // UI Elements
  static const Color searchField = Color(0xFF424242); // grey[800]
  static const Color transactionTile = Color(0xFF303030); // grey[850]

  // Budget Indicator Colors
  static const Color budgetGood = Colors.green;
  static const Color budgetWarning = Colors.orange;
  static const Color budgetOver = Colors.red;

  // Feedback & Status
  static const Color error = Color(0xFFEF5350); // red.shade400
  static const Color listening = Colors.redAccent;
}