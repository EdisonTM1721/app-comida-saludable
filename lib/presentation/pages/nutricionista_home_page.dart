import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emprendedor/presentation/pages/login_page.dart';

class NutricionistaHomePage extends StatelessWidget {
  const NutricionistaHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Nutricionista'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenido, ${user?.email ?? 'nutricionista'}'),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Mis citas'),
                subtitle: const Text('Consulta tu agenda'),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Pacientes'),
                subtitle: const Text('Revisa tu lista de pacientes'),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.food_bank),
                title: const Text('Recomendaciones'),
                subtitle: const Text('Gestiona planes alimenticios'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}