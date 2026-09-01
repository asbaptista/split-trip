import 'member.dart';

class ExpenseSplit {
  final int id;
  final Member member;
  final double amountOwed;

  ExpenseSplit({
    required this.id,
    required this.member,
    required this.amountOwed,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'] as int,
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      amountOwed: (json['amountOwed'] as num).toDouble(),
    );
  }
}

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
    var splitsList = <ExpenseSplit>[];
    if (json['splits'] != null) {
      splitsList = (json['splits'] as List)
          .map((i) => ExpenseSplit.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return Expense(
      id: json['id'] as int,
      description: json['description'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidBy: Member.fromJson(json['paidBy'] as Map<String, dynamic>),
      splits: splitsList,
    );
  }
}