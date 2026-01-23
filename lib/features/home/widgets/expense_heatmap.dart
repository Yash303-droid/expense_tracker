import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../../models/transaction.dart';

class ExpenseHeatmap extends StatelessWidget {
  final List<Transaction> transactions;

  const ExpenseHeatmap({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. Data Conversion
    Map<DateTime, int> dataset = {};
    for (var tx in transactions) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (dataset.containsKey(date)) {
        dataset[date] = dataset[date]! + tx.amount.toInt();
      } else {
        dataset[date] = tx.amount.toInt();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spending Intensity 🗓️",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

         
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white, // Background White
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200), // Halka Border
            ),
            child: HeatMap(
              datasets: dataset,
              startDate: DateTime.now().subtract(const Duration(days: 100)), // Pichle 3+ Mahine
              endDate: DateTime.now(),
              
              
              scrollable: true,       
              colorMode: ColorMode.color, 
              showText: false,        
              size: 18,               
              margin: const EdgeInsets.all(3), 
              borderRadius: 2,        
              
              
              colorsets: {
                1: Colors.red.shade100,    // Level 1: Chhota Kharcha (< ₹500)
                500: Colors.red.shade300,  // Level 2: Medium Kharcha
                1000: Colors.red.shade500, // Level 3: Bada Kharcha
                2000: Colors.red.shade700, // Level 4: Bhari Kharcha
                5000: Colors.red.shade900, // Level 5: Bank Khali
              },
              
              defaultColor: Colors.grey.shade200, // No Expense (Empty Box)
              
              onClick: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Spent on ${value.day}/${value.month}: ₹${dataset[value] ?? 0}")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}