class MemberBalance {
  final int memberId;
  final String memberName;
  final double totalPaid;
  final double totalOwed;
  final double balance;

  MemberBalance({
    required this.memberId,
    required this.memberName,
    required this.balance,
    required this.totalPaid,
    required this.totalOwed,
  });

  factory MemberBalance.fromJson(Map<String, dynamic> json) {
    return MemberBalance(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      memberName: (json['memberName'] as String?) ?? '',
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      totalOwed: (json['totalOwed'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
