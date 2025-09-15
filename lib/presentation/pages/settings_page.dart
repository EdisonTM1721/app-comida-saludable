import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/pages/business_profile_edit_page.dart';
import 'package:emprendedor/presentation/pages/social_media_page.dart';
import 'package:emprendedor/presentation/pages/payment_methods_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:emprendedor/presentation/controllers/social_media_controller.dart';
import 'package:emprendedor/presentation/controllers/payment_method_controller.dart';

// Configuración de usuario
final Logger logger = Logger('SettingsPage');

// Página de configuración
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Cierra la sesión del usuario
  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {

        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      logger.severe("Error durante el logout: $e", e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  // Construye el widget
  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId == null) {

      return const Scaffold(
        body: Center(
          child: Text('Usuario no autenticado.'),
        ),
      );
    }

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

              Provider.of<ProfileController>(context, listen: false).setUserId(userId);
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

              Provider.of<SocialMediaController>(context, listen: false).setUserId(userId);
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

              Provider.of<PaymentMethodController>(context, listen: false).setUserId(userId);
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