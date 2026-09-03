import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import '../models/trip.dart';

class AddExpenseScreen extends StatefulWidget {
  final Trip trip;
  final int currentMemberId;
  final Expense?
  expenseToEdit; // Para selecionarmos logo quem está a usar a app

  const AddExpenseScreen({
    super.key,
    required this.trip,
    required this.currentMemberId,
    this.expenseToEdit,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final ApiService _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late int _selectedPayerId;
  final Set<int> _selectedMemberIds = {};
  bool _isLoading = false;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final expense = widget.expenseToEdit!;
      _descriptionController.text = expense.description;
      _amountController.text = expense.totalAmount.toStringAsFixed(2);
      _selectedPayerId = expense.paidBy.id;
      for (final split in expense.splits) {
        _selectedMemberIds.add(split.member.id);
      }
    } else {
      _selectedPayerId = widget.currentMemberId;
      for (final member in widget.trip.members) {
        _selectedMemberIds.add(member.id);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seleciona pelo menos uma pessoa para dividir a despesa.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final double? amount = double.tryParse(
      _amountController.text.replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insere um valor válido superior a zero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _apiService.updateExpense(
          expenseId: widget.expenseToEdit!.id,
          description: _descriptionController.text.trim(),
          totalAmount: amount,
          paidById: _selectedPayerId,
          splitAmongMemberIds: _selectedMemberIds.toList(),
        );
      } else {
        await _apiService.addExpense(
          widget.trip.id,
          _descriptionController.text.trim(),
          amount,
          _selectedPayerId,
          _selectedMemberIds.toList(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Despesa atualizada com sucesso!'
                : 'Despesa criada com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Se correu tudo bem, fecha o ecrã e devolve "true" para o Dashboard saber que tem de atualizar
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao guardar despesa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Despesa' : 'Nova Despesa'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Descrição
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'O que foi pago? (Ex: Jantar, Gasóleo)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) => value == null ||
                          value.trim().isEmpty ? 'Insere uma descrição' : null,
                    ),
                    const SizedBox(height: 16),

                    // Valor
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor Total (€)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Insere o montante'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quem pagou?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedPayerId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: widget.trip.members.map((member) {
                        return DropdownMenuItem<int>(
                          value: member.id,
                          child: Text(member.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPayerId = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    // 13. ALTERAÇÃO: Adição de uma barra superior com o botão "Selecionar Todos / Desmarcar Todos" para facilitar a gestão dos membros.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dividir entre quem?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedMemberIds.length ==
                                  widget.trip.members.length) {
                                _selectedMemberIds.clear();
                              } else {
                                _selectedMemberIds.clear();
                                for (final m in widget.trip.members) {
                                  _selectedMemberIds.add(m.id);
                                }
                              }
                            });
                          },
                          child: Text(
                            _selectedMemberIds.length ==
                                    widget.trip.members.length
                                ? 'Desmarcar Todos'
                                : 'Selecionar Todos',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 14. ALTERAÇÃO: A lista de seleção de membros agora está envolvida por um `Card` com divisores entre itens (`ListView.separated`) para um design visualmente mais organizado.
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.trip.members.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final member = widget.trip.members[index];
                          final isChecked = _selectedMemberIds.contains(
                            member.id,
                          );
                          return CheckboxListTile(
                            title: Text(member.name),
                            value: isChecked,
                            activeColor: Colors.teal,
                            onChanged: (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selectedMemberIds.add(member.id);
                                } else {
                                  _selectedMemberIds.remove(member.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 15. ALTERAÇÃO: Substituição do `FilledButton.icon` por um `ElevatedButton` estilizado e com texto dinâmico ("Gravar Alterações" vs "Adicionar Despesa").
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submitExpense,
                        child: Text(
                          _isEditing
                              ? 'Gravar Alterações'
                              : 'Adicionar Despesa',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ); 
  }
}
