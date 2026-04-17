import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emprendedor/presentation/pages/login_page.dart';

class ClienteHomePage extends StatelessWidget {
  const ClienteHomePage({super.key});

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
        title: const Text('Panel del Cliente'),
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
            Text('Bienvenido, ${user?.email ?? 'cliente'}'),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: const Text('Ver comidas saludables'),
                subtitle: const Text('Explora opciones disponibles'),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Mis pedidos'),
                subtitle: const Text('Consulta tus compras'),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Agendar cita'),
                subtitle: const Text('Reserva una cita con nutricionista'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}