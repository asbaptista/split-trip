import 'package:flutter/material.dart';

void main() {
  runApp(const SplitTripApp());
}

class SplitTripApp extends StatelessWidget {
  const SplitTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitTrip',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Motor Flutter Pronto!', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
