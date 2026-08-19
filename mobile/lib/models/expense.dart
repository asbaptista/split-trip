import 'member.dart';

class Expense {
  final int id;
  final String description;
  final double totalAmount;
  final DateTime expenseDate;
  final Member paidBy;

  Expense({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.expenseDate,
    required this.paidBy,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['id'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String?) ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: json['expenseDate'] != null
          ? DateTime.parse(json['expenseDate'] as String)
          : DateTime.now(),
      paidBy: json['paidBy'] != null
          ? Member.fromJson(json['paidBy'] as Map<String, dynamic>)
          : Member(id: 0, name: ''),
    );
  }
}
