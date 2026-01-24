import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/transaction.dart';

class Chart extends StatelessWidget {
  final List<Transaction> recentTransactions;

  const Chart({super.key, required this.recentTransactions});

  List<Map<String, Object>> get groupedTransactionValues {
    return List.generate(7, (index) {
      final weekDay = DateTime.now().subtract(Duration(days: index));
      double totalSum = 0.0;

      for (var tx in recentTransactions) {
        if (tx.date.day == weekDay.day &&
            tx.date.month == weekDay.month &&
            tx.date.year == weekDay.year) {
          totalSum += tx.amount;
        }
      }

      return {
        'day': DateFormat.E().format(weekDay).substring(0, 1),
        'amount': totalSum,
      };
    }).reversed.toList();
  }

  double get maxSpending {
    return groupedTransactionValues.fold(0.0, (max, item) {
      final amount = item['amount'] as double;
      return amount > max ? amount : max;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final double maxY = maxSpending == 0.0 ? 100.0 : maxSpending * 1.2; // Add 20% padding

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < groupedTransactionValues.length) {
                  final day = groupedTransactionValues[index]['day'] as String;
                  return SideTitleWidget(
                    
                    space: 4.0,
                    meta: meta,
                    child: Text(day, style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700], fontSize: 14)),
                  );
                }
                return Container();
              },
            ),
          ),
        ),
        barGroups: groupedTransactionValues.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final amount = data['amount'] as double;
          final isMax = amount == maxSpending && amount > 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: amount,
                gradient: isMax
                    ? LinearGradient(
                        colors: [Colors.amber.shade600, Colors.orange.shade400],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                width: 16,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: isDarkMode ? colorScheme.onSurface.withOpacity(0.1) : colorScheme.surfaceVariant,
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${rod.toY.toStringAsFixed(0)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
    );
  }
}