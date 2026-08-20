import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'dashboard_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Controladores de texto para "Criar Viagem"
  final _createTripNameController = TextEditingController();
  final _createMemberNameController = TextEditingController();

  // Controladores de texto para "Entrar na Viagem"
  final _joinRoomCodeController = TextEditingController();
  final _joinMemberNameController = TextEditingController();

  // Função para  a criação
  Future<void> _handleCreateTrip() async {
    final tripName = _createTripNameController.text.trim();
    final memberName = _createMemberNameController.text.trim();

    if (tripName.isEmpty || memberName.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      //Cria a viagem no backend (devolve a Trip com o código gerado)
      final newTrip = await _apiService.createTrip(tripName);

      // Junta imediatamente quem criou a viagem (devolve o Member gerado)
      final newMember = await _apiService.joinTrip(
        newTrip.roomCode,
        memberName,
      );

      // Guarda a sessão na memória do telemóvel
      await SessionManager.saveSession(
        newMember.id,
        newMember.name,
        newTrip.roomCode,
      );

      _goToDashboard();
    } catch (e) {
      _showError('Erro ao criar viagem: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Função para a entrada
  Future<void> _handleJoinTrip() async {
    final roomCode = _joinRoomCodeController.text.trim().toUpperCase();
    final memberName = _joinMemberNameController.text.trim();

    if (roomCode.isEmpty || memberName.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Tenta entrar na viagem com o código
      final newMember = await _apiService.joinTrip(roomCode, memberName);

      // Guarda a sessão
      await SessionManager.saveSession(newMember.id, newMember.name, roomCode);

      _goToDashboard();
    } catch (e) {
      _showError('Código inválido ou erro de ligação.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'SplitTrip',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- CARTÃO: CRIAR VIAGEM ---
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nova Viagem',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _createTripNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome da Viagem',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _createMemberNameController,
                            decoration: const InputDecoration(
                              labelText: 'O teu nome',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleCreateTrip,
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  'Criar Grupo',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- CARTÃO: ENTRAR EM VIAGEM ---
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Já tens um código?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _joinRoomCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Código da Sala (Ex: A7F9X2)',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _joinMemberNameController,
                            decoration: const InputDecoration(
                              labelText: 'O teu nome',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _handleJoinTrip,
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  'Entrar no Grupo',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Extensão rápida para não dar erro no SnackBar de sucesso
extension ScaffoldMessengerExtension on ScaffoldMessengerState {
  void showSuccessSnackBar(SnackBar snackBar) {
    showSnackBar(
      SnackBar(content: snackBar.content, backgroundColor: Colors.green),
    );
  }
}
