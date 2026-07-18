import 'package:flutter/material.dart';
import '../src/presentation/theme/quantum_colors.dart';
import 'demo_data.dart';
import 'owner_screen.dart';
import 'staff_screen.dart';
import 'client_screen.dart';

/// Login demo con los 3 tipos de cuenta (Dueño / Empleado / Cliente).
/// Acepta las credenciales mock o entrada rápida con un toque.
class DemoLoginScreen extends StatefulWidget {
  const DemoLoginScreen({super.key});

  @override
  State<DemoLoginScreen> createState() => _DemoLoginScreenState();
}

class _DemoLoginScreenState extends State<DemoLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final user = demoUsers.where(
      (u) => u.email == email && u.password == password,
    );
    if (user.isEmpty) {
      setState(() =>
          _error = 'Credenciales inválidas. Usa las cuentas demo de abajo.');
      return;
    }
    _enterAs(user.first);
  }

  void _enterAs(DemoUser user) {
    setState(() => _error = null);
    final Widget home = switch (user.role) {
      'owner' => DemoOwnerScreen(user: user),
      'staff' => DemoStaffScreen(user: user),
      _ => DemoClientScreen(user: user),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => home));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      QuantumColors.quantumBlue.withValues(alpha: 0.25),
                      QuantumColors.holoPurple.withValues(alpha: 0.25),
                    ]),
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      size: 48, color: QuantumColors.quantumBlue),
                ),
                const SizedBox(height: 20),
                const Text(
                  'QUANTUM GYM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: QuantumColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DEMO · DATOS DE PRUEBA',
                    style: TextStyle(
                      color: QuantumColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                _buildField(
                  controller: _emailController,
                  hint: 'Correo electrónico',
                  icon: Icons.mail_outline_rounded,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _passwordController,
                  hint: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: const TextStyle(
                        color: QuantumColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: QuantumColors.quantumBlue,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _login,
                    child: const Text('INICIAR SESIÓN',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, letterSpacing: 2)),
                  ),
                ),
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('o entra directo como',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                ]),
                const SizedBox(height: 20),
                ...demoUsers.map((u) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoleCard(user: u, onTap: () => _enterAs(u)),
                    )),
                const SizedBox(height: 8),
                const Text(
                  'Contraseña de todas las cuentas: demo123',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: QuantumColors.voidGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final DemoUser user;
  final VoidCallback onTap;

  const _RoleCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (user.role) {
      'owner' => (Icons.business_center_rounded, QuantumColors.holoPurple),
      'staff' => (Icons.badge_rounded, QuantumColors.deepSpaceBlue),
      _ => (Icons.person_rounded, QuantumColors.matrixCyan),
    };
    return Material(
      color: QuantumColors.voidGray,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.roleLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(user.email,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
