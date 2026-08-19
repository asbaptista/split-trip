class TransferInstruction {
  final int senderId;
  final String senderName;
  final int receiverId;
  final String receiverName;
  final double amount;

  TransferInstruction({
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.amount,
  });

  factory TransferInstruction.fromJson(Map<String, dynamic> json) {
    return TransferInstruction(
      senderId: (json['senderId'] as num?)?.toInt() ?? 0,
      senderName: (json['senderName'] as String?) ?? '',
      receiverId: (json['receiverId'] as num?)?.toInt() ?? 0,
      receiverName: (json['receiverName'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
