import 'member.dart';
import 'expense_split.dart';

class Expense {
  final int id;
  final String description;
  final double totalAmount;
  final Member paidBy;
  final List<ExpenseSplit> splits;

  Expense({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.paidBy,
    this.splits = const [],
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      description: json['description'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidBy: Member.fromJson(json['paidBy'] as Map<String, dynamic>),
      splits: (json['splits'] as List<dynamic>?)
              ?.map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}