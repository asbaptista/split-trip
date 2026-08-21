import 'package:flutter/material.dart';
import 'services/session_manager.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplitTripApp());
}

class SplitTripApp extends StatelessWidget {
  const SplitTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitTrip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: SessionManager.isLoggedIn(),
        builder: (context, snapshot) {
          // Enquanto verifica a memória local, mostra um ecrã de carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Se já tiver dados na sessão, vai direto para o Dashboard
          if (snapshot.data == true) {
            return const DashboardScreen();
          }

          // Caso contrário, mostra o ecrã inicial de entrada/criação
          return const HomeScreen();
        },
      ),
    );
  }
}