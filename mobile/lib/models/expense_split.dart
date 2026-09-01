import 'member.dart';

class ExpenseSplit {
  final int id;
  final Member member;
  final double owedAmount;

  ExpenseSplit({
    required this.id,
    required this.member,
    required this.owedAmount,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'] as int,
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      owedAmount: (json['owedAmount'] as num).toDouble(),
    );
  }
}