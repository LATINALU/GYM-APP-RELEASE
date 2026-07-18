import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Entry point de la DEMO con los 3 tipos de login (Dueño/Empleado/Cliente).
/// Sin Firebase, sin internet: todos los datos son mock (demo_data.dart).
///
/// Compilar el APK:
///   flutter build apk --release -t lib/demo/main.dart
void main() {
  runApp(const QuantumGymDemoApp());
}

class QuantumGymDemoApp extends StatelessWidget {
  const QuantumGymDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quantum Gym — Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const DemoLoginScreen(),
    );
  }
}
