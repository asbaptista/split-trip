class Member {
  final int id;
  final String name;

  Member({required this.id, required this.name});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] is String
          ? int.parse(json['id'])
          : json['id'] as int, //caso venha como string, nao deve acontecer
      name: json['name'] as String? ?? 'Sem nome',
    );
  }
}
