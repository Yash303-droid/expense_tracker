import 'package:flutter/material.dart';

// Ye function string lega aur Icon dega
IconData getCategoryIcon(String categoryName) {
  switch (categoryName) {
    case 'Food':
      return Icons.fastfood;
    case 'Travel':
      return Icons.directions_car;
    case 'Shopping':
      return Icons.shopping_bag;
    case 'Bills':
      return Icons.receipt;
    case 'Entertainment':
      return Icons.movie;
    case 'Health':
      return Icons.medical_services;
    default:
      return Icons.attach_money; // Default icon
  }
}

// Ye color ke liye (Optional styling)
Color getCategoryColor(String categoryName) {
  switch (categoryName) {
    case 'Food': return Colors.orange;
    case 'Travel': return Colors.blue;
    case 'Shopping': return Colors.pink;
    case 'Bills': return Colors.red;
    case 'Entertainment': return Colors.green;
    case 'Health': return Colors.teal;  
    default: return Colors.purple;
  }
}