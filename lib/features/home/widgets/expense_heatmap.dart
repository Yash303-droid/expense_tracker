import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../../models/transaction.dart';
import 'package:intl/intl.dart';

class ExpenseHeatmap extends StatelessWidget {
  final List<Transaction> transactions;

  const ExpenseHeatmap({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (transactions.isEmpty) {
      return const Center(
        child: Text("No transaction data for heatmap.", style: TextStyle(color: Colors.grey)),
      );
    }

    // 1. Process transaction data into a format the heatmap can understand.
    final Map<DateTime, int> datasets = {};
    for (var tx in transactions) {
      // Normalize the date to remove the time part, grouping all transactions on the same day.
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      datasets.update(date, (value) => value + tx.amount.toInt(), ifAbsent: () => tx.amount.toInt());
    }

    return HeatMapCalendar(
      datasets: datasets,
      // 2. Define a vibrant, theme-aware color palette for spending intensity.
      colorsets: {
        1: colorScheme.primary.withOpacity(0.2),
        100: colorScheme.primary.withOpacity(0.4),
        500: colorScheme.primary.withOpacity(0.6),
        1000: colorScheme.primary.withOpacity(0.8),
        2000: colorScheme.primary,
      },
      // 3. Style the widget for a polished look.
      defaultColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
      textColor: isDarkMode ? Colors.white70 : Colors.black87,
      monthFontSize: 16,
      weekFontSize: 12,
      weekTextColor: Colors.grey[500],
      borderRadius: 8,
      margin: const EdgeInsets.all(4),
      size: 32,
      // 4. Add interactive tooltips on tap.
      onClick: (date) {
        final amount = datasets[date];
        if (amount != null && amount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${DateFormat.yMMMd().format(date)}: ₹$amount')));
        }
      },
    );
  }
}