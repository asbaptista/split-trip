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

  void _shareTripCode(String roomCode, String tripName) {
    Share.share(
      'Junta-te à viagem "$tripName" no SplitTrip!\n\n'
      'Código da sala: $roomCode\n\n'
      'Abre no browser: https://lambent-longma-a84c8b.netlify.app/ (ou usa a app)',
      subject: 'Código da Viagem SplitTrip',
    );
  }

  Future<void> _logout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Future<void> _confirmDeleteExpense(
    Expense expense,
    BuildContext sheetContext,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Despesa'),
        content: Text(
          'Tens a certeza que queres eliminar "${expense.description}" (${expense.totalAmount.toStringAsFixed(2)} €)?\n\n'
          'Os saldos e o ajuste de contas serão recalculados automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _apiService.deleteExpense(expense.id);
        if (!mounted) return;

        if (Navigator.of(sheetContext).canPop()) {
          Navigator.of(sheetContext).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Despesa eliminada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDashboardData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _showExpenseDetailsModal(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      expense.description,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Valor Total:',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    '${expense.totalAmount.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pago por:',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    expense.paidBy.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Divisão da Despesa:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: expense.splits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final split = expense.splits[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person, color: Colors.teal),
                      title: Text(split.member.name),
                      trailing: Text(
                        '${split.owedAmount.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Botão Editar Despesa
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(
                   'Editar Despesa',
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: () async {
                    if (_trip == null) return;
                    final session = await SessionManager.getSession();
                    final currentMemberId = (session?['memberId'] ?? 0) as int;

                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop(); // Fecha o bottom sheet de detalhes

                    final expenseUpdated = await Navigator.of(context)
                        .push<bool>(
                          MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(
                              trip: _trip!,
                              currentMemberId: currentMemberId,
                              expenseToEdit: expense,
                            ),
                          ),
                        );

                    if (expenseUpdated == true) {
                      _loadDashboardData();
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Botão Eliminar Despesa
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(
                    'Eliminar Despesa',
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: () => _confirmDeleteExpense(expense, ctx),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
            if (_trip != null) _buildRoomCodeCard(),
            const SizedBox(height: 24),
            const Text(
              'Ajuste de Contas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSettlementList(),
            const SizedBox(height: 24),
            const Text(
              'Histórico de Despesas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildExpensesList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_trip == null) return;

          final session = await SessionManager.getSession();
          final currentMemberId = (session?['memberId'] ?? 0) as int;

          if (!context.mounted) return;

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

  Widget _buildRoomCodeCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              onPressed: () => _shareTripCode(_trip!.roomCode, _trip!.name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementList() {
    if (_settlements.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'As contas estão certas! Ninguém deve a ninguém. 🎉',
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    }
    return Column(
      children: _settlements
          .map(
            (s) => Card(
              child: ListTile(
                leading: const Icon(Icons.sync_alt, color: Colors.orange),
                title: Text('${s.senderName} paga a ${s.receiverName}'),
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
    );
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Ainda não há despesas registadas.'),
        ),
      );
    }
    return Column(
      children: _expenses
          .map(
            (e) => Card(
              child: ListTile(
                onTap: () => _showExpenseDetailsModal(e),
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.receipt, color: Colors.white),
                ),
                title: Text(e.description),
                subtitle: Text('Pago por ${e.paidBy.name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${e.totalAmount.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
