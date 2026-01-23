import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/transaction.dart';
import '../../../utils/category_icons.dart'; // Color lene ke liye

class CategoryPieChart extends StatelessWidget {
  final List<Transaction> transactions;

  const CategoryPieChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. Data Grouping Logic
    // Map banayenge: {'Food': 500.0, 'Travel': 200.0}
    Map<String, double> categoryTotals = {};

    for (var tx in transactions) {
      if (categoryTotals.containsKey(tx.category)) {
        categoryTotals[tx.category] = categoryTotals[tx.category]! + tx.amount;
      } else {
        categoryTotals[tx.category] = tx.amount;
      }
    }

    // Total spending (percentage nikalne ke liye)
    final totalSpent = transactions.fold(0.0, (sum, item) => sum + item.amount);

    if (totalSpent == 0) return const SizedBox(); // Agar koi kharcha nahi, to empty raho

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(20),
      color: Colors.white, // Dark mode walon ke liye adjust kar lena
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Category Breakdown",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),
            
            // 2. THE PIE CHART
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2, // Slices ke beech gap
                  centerSpaceRadius: 30, // Donut style chart
                  sections: categoryTotals.entries.map((entry) {
                    final percentage = (entry.value / totalSpent) * 100;
                    
                    return PieChartSectionData(
                      color: getCategoryColor(entry.key), // Humara util function
                      value: entry.value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 3. LEGEND (Neeche jo batata hai kaunsa color kya hai)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categoryTotals.keys.map((cat) {
                return Chip(
                  avatar: CircleAvatar(backgroundColor: getCategoryColor(cat)),
                  label: Text(cat),
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}