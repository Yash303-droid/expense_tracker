import 'package:flutter/material.dart';
import 'chart_bar.dart';
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

 // double get totalSpending {
   // return groupedTransactionValues.fold(0.0, (sum, item) {
   //   return sum + (item['amount'] as double);
   // });
  //}
  double get maxSpending {
    return groupedTransactionValues.fold(0.0, (max, item) {
      final amount = item['amount'] as double;
      return amount > max ? amount : max;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: groupedTransactionValues.map((data) {
            return ChartBar(
              label: data['day'] as String,
              spendingamount: data['amount'] as double,
              spendingPctOfTotal: maxSpending == 0.0
                  ? 0.0
                  : (data['amount'] as double) / maxSpending,
            );
          }).toList(),
        ),
      ),
    );
  }
}