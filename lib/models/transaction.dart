class Transaction {
  final int id;
  final String title;
  final double amount;
  final DateTime date;
  final String userId;
  final String category; // <--- 1. NEW FIELD

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.userId,
    required this.category, // <--- 2. REQUIRED
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] is int ? map['id'] : 0,
      title: map['title']?.toString() ?? 'No Title',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      date: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()).toLocal()
          : DateTime.now(),
      userId: map['user_id']?.toString() ?? '',
      
      // <--- 3. MAP FROM DATABASE
      category: map['category']?.toString() ?? 'Other', 
    );
  }
}