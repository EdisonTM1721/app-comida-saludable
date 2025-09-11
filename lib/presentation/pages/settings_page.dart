import 'package:flutter/material.dart';
import 'package:emprendedor/presentation/pages/business_profile_edit_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/presentation/pages/social_media_page.dart';
import 'package:emprendedor/presentation/pages/payment_methods_page.dart';

final Logger logger = Logger('SettingsPage');

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // El AuthWrapper de main.dart se encargará de la navegación
    } catch (e, stackTrace) {
      logger.severe("Error durante el logout: $e", e, stackTrace);
      // Opcionalmente, mostrar un SnackBar con el error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.teal),
            title: const Text('Editar Perfil'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BusinessProfileEditPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.public, color: Colors.teal),
            title: const Text('Redes Sociales'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SocialMediaPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.credit_card, color: Colors.teal),
            title: const Text('Métodos de Pago'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PaymentMethodsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
