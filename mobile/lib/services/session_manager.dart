import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyMemberId = 'memberId';
  static const String _keyMemberName = 'memberName';
  static const String _keyRoomCode = 'roomCode';

  // guardar a sessão no telemóvel
  static Future<void> saveSession(
    int memberId,
    String memberName,
    String roomCode,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMemberId, memberId);
    await prefs.setString(_keyMemberName, memberName);
    await prefs.setString(_keyRoomCode, roomCode);
  }

  // verificar se o user já está numa viagem
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyRoomCode) && prefs.containsKey(_keyMemberId);
  }

  // ir buscar os dados todos de uma vez
  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();

    final memberId = prefs.getInt(_keyMemberId);
    final memberName = prefs.getString(_keyMemberName);
    final roomCode = prefs.getString(_keyRoomCode);

    if (memberId != null && memberName != null && roomCode != null) {
      return {
        'memberId': memberId,
        'memberName': memberName,
        'roomCode': roomCode,
      };
    }
    return null;
  }

  // logout, sair da viagem
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
