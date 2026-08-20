import 'dart:convert';
import 'package:http/http.dart' as http;

// Importar os  modelos
import '../models/trip.dart';
import '../models/member.dart';
import '../models/expense.dart';
import '../models/member_balance.dart';
import '../models/transfer_instruction.dart';

class ApiService {
  static const String baseUrl =
      'http://localhost:8080/api'; // TRIPS AND MEMBERS

  Future<Trip> createTrip(String tripName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tripName': tripName}),
    );

    if (response.statusCode == 201) {
      return Trip.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Falha ao criar a viagem.');
    }
  }

  Future<Member> joinTrip(String roomCode, String memberName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roomCode': roomCode, 'memberName': memberName}),
    );

    if (response.statusCode == 201) {
      return Member.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Falha ao entrar na viagem. Verifica o código.');
    }
  }

  Future<Trip> getTripDetails(String roomCode) async {
    final response = await http.get(Uri.parse('$baseUrl/trips/$roomCode'));

    if (response.statusCode == 200) {
      return Trip.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Viagem não encontrada.');
    }
  }

  // EXPENSES

  Future<Expense> addExpense(
    int tripId,
    int paidById,
    String description,
    double totalAmount,
    List<int> involvedMemberIds,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tripId': tripId,
        'paidById': paidById,
        'description': description,
        'totalAmount': totalAmount,
        'involvedMemberIds': involvedMemberIds,
      }),
    );

    if (response.statusCode == 201) {
      return Expense.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Falha ao registar a despesa.');
    }
  }

  Future<List<Expense>> getTripExpenses(int tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/expenses/trip/$tripId'),
    );

    if (response.statusCode == 200) {
      Iterable list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((i) => Expense.fromJson(i)).toList();
    } else {
      throw Exception('Falha ao carregar despesas.');
    }
  }

  Future<List<MemberBalance>> getBalances(int tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/expenses/trip/$tripId/balances'),
    );

    if (response.statusCode == 200) {
      Iterable list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((model) => MemberBalance.fromJson(model)).toList();
    } else {
      throw Exception('Falha ao carregar saldos.');
    }
  }

  Future<List<TransferInstruction>> getSettlements(int tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/expenses/trip/$tripId/settlements'),
    );

    if (response.statusCode == 200) {
      Iterable list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((model) => TransferInstruction.fromJson(model)).toList();
    } else {
      throw Exception('Falha ao carregar instruções de pagamento.');
    }
  }
}
