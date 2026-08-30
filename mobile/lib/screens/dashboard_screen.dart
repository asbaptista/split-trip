import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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

  void _showMembersModal(BuildContext context) {
    if (_trip == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Membros do Grupo (${_trip!.members.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _trip!.members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = _trip!.members[index];
                    final isCurrentUser = member.name == _currentMemberName;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isCurrentUser
                            ? Colors.teal
                            : Colors.grey.shade300,
                        foregroundColor: isCurrentUser
                            ? Colors.white
                            : Colors.black87,
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        member.name,
                        style: TextStyle(
                          fontWeight: isCurrentUser
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isCurrentUser
                          ? const Chip(
                              label: Text('Tu', style: TextStyle(fontSize: 12)),
                              backgroundColor: Colors.tealAccent,
                              padding: EdgeInsets.zero,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareTripCode(String roomCode, String tripName) {
    Share.share(
      'Junta-te à viagem "$tripName" no SplitTrip!\n\n'
      'Código da sala: $roomCode\n\n'
      'Abre no browser:  https://lambent-longma-a84c8b.netlify.app/  (ou usa a app)',
      subject: 'Código da Viagem SplitTrip',
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final session = await SessionManager.getSession();
      if (session == null) throw Exception("Sessão não encontrada");

      _currentMemberName = session['memberName'] ?? '';
      final roomCode = session['roomCode'];

      _trip = await _apiService.getTripDetails(roomCode);

      final results = await Future.wait([
        _apiService.getTripExpenses(_trip!.id),
        _apiService.getBalances(_trip!.id),
        _apiService.getSettlements(_trip!.id),
      ]);

      if (!mounted) return;

      setState(() {
        _expenses = results[0] as List<Expense>;
        _balances = results[1] as List<MemberBalance>;
        _settlements = results[2] as List<TransferInstruction>;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            icon: const Icon(Icons.group),
            tooltip: 'Ver Membros',
            onPressed: () => _showMembersModal(context),
          ),
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
            // CÓDIGO DA SALA E BOTÃO DE PARTILHA
            if (_trip != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Código: ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _trip!.roomCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.teal),
                        tooltip: 'Partilhar código',
                        onPressed: () =>
                            _shareTripCode(_trip!.roomCode, _trip!.name),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // AJUSTE DE CONTAS (QUEM PAGA A QUEM)
            const Text(
              'Ajuste de Contas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _settlements.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'As contas estão certas! Ninguém deve a ninguém. 🎉',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
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
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

            const SizedBox(height: 24),

            // HISTÓRICO DE DESPESAS
            const Text(
              'Histórico de Despesas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _expenses.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Ainda não há despesas registadas.'),
                    ),
                  )
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
          final currentMemberId = (session?['memberId'] ?? 0) as int;

          final despesaAdicionada = await Navigator.of(context).push<bool>(
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
