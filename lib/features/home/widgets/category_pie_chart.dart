import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';
import '../../../utils/category_icons.dart'; // Color lene ke liye

class CategoryPieChart extends StatefulWidget {
  final List<Transaction> transactions;

  const CategoryPieChart({super.key, required this.transactions});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    Map<String, double> categoryTotals = {};
    for (var tx in widget.transactions) {
      categoryTotals.update(tx.category, (value) => value + tx.amount, ifAbsent: () => tx.amount);
    }

    final totalSpent = categoryTotals.values.fold(0.0, (sum, item) => sum + item);

    if (totalSpent == 0) {
      return const Center(
        child: Text("No transactions to display.", style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    List<PieChartSectionData> showingSections() {
      // Sort categories by amount
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.asMap().entries.map((entry) {
        final index = entry.key;
        final categoryData = entry.value;
        final isTouched = index == touchedIndex;
        final radius = isTouched ? 90.0 : 80.0;
        final fontSize = isTouched ? 18.0 : 14.0;
        final percentage = (categoryData.value / totalSpent) * 100;

        return PieChartSectionData(
          color: getCategoryColor(categoryData.key),
          value: categoryData.value,
          title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        );
      }).toList();
    }

    return Column(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: showingSections(),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Total Spent", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text(
                      '₹${NumberFormat.compact().format(totalSpent)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: ListView(
            padding: const EdgeInsets.only(top: 8.0),
            children: (categoryTotals.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .map((entry) {
                  final percentage = (entry.value / totalSpent) * 100;
                  return Indicator(
                    color: getCategoryColor(entry.key),
                    text: entry.key,
                    subtitle: '₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    this.subtitle,
  });
  final Color color;
  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}