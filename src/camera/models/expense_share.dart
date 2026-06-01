// lib/models/expense_share.dart
class ExpenseShare {
  final int id;
  final int expenseId;
  final int userId;
  final double amount;
  final bool isPaid;

  ExpenseShare({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    required this.isPaid,
  });

  factory ExpenseShare.fromJson(Map<String, dynamic> json) {
    return ExpenseShare(
      id: json['id'],
      expenseId: json['expense_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      isPaid: json['is_paid'] == 1 || json['is_paid'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'amount': amount,
      'is_paid': isPaid,
    };
  }
}