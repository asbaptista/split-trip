import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/trip.dart';

class AddExpenseScreen extends StatefulWidget {
  final Trip trip;
  final int currentMemberId; // Para selecionarmos logo quem está a usar a app

  const AddExpenseScreen({
    super.key, 
    required this.trip, 
    required this.currentMemberId
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final ApiService _apiService = ApiService();
  
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  int? _selectedPayerId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Por defeito, quem está a usar a app é quem pagou a conta
    _selectedPayerId = widget.currentMemberId;
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPayerId == null) return;

    setState(() => _isLoading = true);

    try {
      final description = _descriptionController.text.trim();
      // Substituir vírgulas por pontos para evitar erros a converter para double
      final amountText = _amountController.text.replaceAll(',', '.');
      final amount = double.parse(amountText);

      // Vamos dividir por todos os membros da viagem por defeito
      final involvedMemberIds = widget.trip.members.map((m) => m.id).toList();

      await _apiService.addExpense(
        widget.trip.id,
        _selectedPayerId!,
        description,
        amount,
        involvedMemberIds,
      );

      if (!mounted) return;
      
      // Se correu tudo bem, fecha o ecrã e devolve "true" para o Dashboard saber que tem de atualizar
      Navigator.of(context).pop(true);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar despesa: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Despesa'),
        centerTitle: true,
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
                      validator: (value) => value!.isEmpty ? 'Insere uma descrição' : null,
                    ),
                    const SizedBox(height: 16),

                    // Valor
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Valor Total (€)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Insere o valor';
                        if (double.tryParse(value.replaceAll(',', '.')) == null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quem pagou? (Dropdown)
                    DropdownButtonFormField<int>(
                      value: _selectedPayerId,
                      decoration: const InputDecoration(
                        labelText: 'Quem pagou?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: widget.trip.members.map((member) {
                        return DropdownMenuItem<int>(
                          value: member.id,
                          child: Text(member.name),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedPayerId = value),
                    ),
                    const SizedBox(height: 24),

                    // Botão Guardar
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _saveExpense,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Despesa', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}