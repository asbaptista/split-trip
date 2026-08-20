import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../models/member_balance.dart';
import '../models/transfer_instruction.dart';
import 'home_screen.dart';
import 'add_expense_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  Trip? _trip;
  List<Expense> _expenses = [];
  List<MemberBalance> _balances = [];
  List<TransferInstruction> _settlements = [];
  String _currentMemberName = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // er a sessão guardada
      final session = await SessionManager.getSession();
      if (session == null) throw Exception("Sessão não encontrada");

      _currentMemberName = session['memberName'];
      final roomCode = session['roomCode'];

      // Ir buscar os detalhes da Viagem (para sabermos o tripId real)
      _trip = await _apiService.getTripDetails(roomCode);

      // Ir buscar as contas todas em simultâneo para ser mais rápido
      final results = await Future.wait([
        _apiService.getTripExpenses(_trip!.id),
        _apiService.getBalances(_trip!.id),
        _apiService.getSettlements(_trip!.id),
      ]);

      setState(() {
        _expenses = results[0] as List<Expense>;
        _balances = results[1] as List<MemberBalance>;
        _settlements = results[2] as List<TransferInstruction>;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_trip?.name ?? 'SplitTrip'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair da Viagem',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // CÓDIGO DA SALA
            Center(
              child: Text(
                'Código da Sala: ${_trip?.roomCode}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SECÇÃO: QUEM PAGA A QUEM (MBWay)
            const Text(
              'Ajuste de Contas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _settlements.isEmpty
                ? const Text(
                    'As contas estão certas! Ninguém deve a ninguém. 🎉',
                  )
                : Column(
                    children: _settlements
                        .map(
                          (s) => Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.sync_alt,
                                color: Colors.orange,
                              ),
                              title: Text(
                                '${s.senderName} paga a ${s.receiverName}',
                              ),
                              trailing: Text(
                                '${s.amount.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

            const SizedBox(height: 24),

            // SECÇÃO: FEED DE DESPESAS
            const Text(
              'Histórico de Despesas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _expenses.isEmpty
                ? const Text('Ainda não há despesas registadas.')
                : Column(
                    children: _expenses
                        .map(
                          (e) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.receipt, color: Colors.white),
                              ),
                              title: Text(e.description),
                              subtitle: Text('Pago por ${e.paidBy.name}'),
                              trailing: Text(
                                '${e.totalAmount.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
     onPressed: () async {
       if (_trip == null) return;

       final session = await SessionManager.getSession();
       final currentMemberId = session?['memberId'] as int;

       // Abre o ecrã de Nova Despesa e fica à espera do resultado
       final despesaAdicionada = await Navigator.of(context).push(
         MaterialPageRoute(
           builder: (_) => AddExpenseScreen(
             trip: _trip!,
             currentMemberId: currentMemberId,
           ),
         ),
       );

       
       if (despesaAdicionada == true) {
         _loadDashboardData();
       }
     },
     icon: const Icon(Icons.add),
     label: const Text('Despesa'),
     backgroundColor: Colors.teal,
     foregroundColor: Colors.white,
   ),
    );
  }
}
