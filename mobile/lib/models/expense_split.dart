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
      id: json['id'] != null ? (json['id'] as num).toInt() : 0,
      member: json['member'] != null
          ? Member.fromJson(json['member'] as Map<String, dynamic>)
          : Member(id: 0, name: 'Desconhecido'),
      amountOwed: ((json['owedAmount'] ?? json['amountOwed']) as num?)?.toDouble() ?? 0.0,
    );
  }
}