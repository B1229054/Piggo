// lib/models/expense.dart
class Expense {
  final int id;
  final int tripId;
  final int payerId;
  final double amount;
  final String title;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.tripId,
    required this.payerId,
    required this.amount,
    required this.title,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      tripId: json['trip_id'],
      payerId: json['payer_id'],
      amount: (json['amount'] as num).toDouble(),
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'payer_id': payerId,
      'amount': amount,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }
}