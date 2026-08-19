import 'member.dart';

class Trip {
  final int id;
  final String name;
  final String roomCode;
  final List<Member> members;

  Trip({
    required this.id,
    required this.name,
    required this.roomCode,
    required this.members,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      name: json['name'] ?? '',
      roomCode: json['roomCode'] ?? '',

      members: json['members'] != null
          ? (json['members'] as List).map((i) => Member.fromJson(i)).toList()
          : [],
    );
  }
}
