import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:emprendedor/data/models/business_profile_model.dart' as model;
import 'package:emprendedor/presentation/pages/business_profile_edit_page.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

// Crear una instancia de Logger para esta página
final Logger _logger = Logger('ProfilePage');

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _logger.info('initState: Llamando a fetchBusinessProfile');
        Provider.of<ProfileController>(context, listen: false).fetchBusinessProfile();
      }
    });
  }

  String _formatPaymentMethods(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return 'No se han establecido métodos de pago';
    }
    try {
      final decoded = json.decode(jsonString);
      _logger.fine('Decoded payment methods: $decoded');
      if (decoded is List && decoded.isNotEmpty) {
        // ... (resto de la lógica)
        final List<String> methodNames = decoded.map((method) {
          if (method is Map<String, dynamic> && method.containsKey('name')) {
            String name = method['name'] as String;
            final details = (method['details'] as Map<String, dynamic>?) ?? {};

            if (name == 'PayPal' && details.containsKey('paypalEmail') && (details['paypalEmail'] as String?)?.isNotEmpty == true) {
              return "$name (${details['paypalEmail']})";
            }
            return name;
          }
          return null;
        }).whereType<String>().toList();

        if (methodNames.isEmpty) {
          return 'No se han establecido métodos de pago';
        }
        return methodNames.join(', ');
      }
    } catch (e, stackTrace) {
      _logger.warning('Error al decodificar métodos de pago: $jsonString', e, stackTrace);
      if (jsonString.trim() == "[]" || jsonString.trim().isEmpty) {
        return 'No se han establecido métodos de pago';
      }
    }
    return jsonString.isNotEmpty ? jsonString : 'No se han establecido métodos de pago';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        _logger.finer('Build: Controller BusinessProfile: ${controller.businessProfile?.name}, isLoading: ${controller.isLoading}, error: ${controller.errorMessage}'); // Nivel 'FINER' para logs muy frecuentes

        // Si no hay perfil, muestra un mensaje
        final profile = controller.businessProfile ?? model.BusinessProfileModel(userId: '', name: '', description: null, address: null, openingHours: null, paymentMethods: null, profileImageUrl: null, id: null);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[300],
                backgroundImage: profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                    ? NetworkImage(profile.profileImageUrl!)
                    : null,
                child: (profile.profileImageUrl == null || profile.profileImageUrl!.isEmpty)
                    ? Icon(Icons.business_center_outlined, size: 70, color: Colors.grey[600])
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                profile.name.isEmpty ? 'Mi Negocio' : profile.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                profile.description?.isNotEmpty == true ? profile.description! : 'Aún no has agregado una descripción.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 0.8),
              const SizedBox(height: 16),
              _buildInfoTile(
                context: context,
                icon: Icons.location_on_outlined,
                title: 'Dirección',
                subtitle: profile.address?.isNotEmpty == true ? profile.address! : 'No se ha especificado la dirección',
              ),
              _buildInfoTile(
                context: context,
                icon: Icons.access_time_outlined,
                title: 'Horarios de Atención',
                subtitle: profile.openingHours?.isNotEmpty == true ? profile.openingHours! : 'No se han establecido horarios',
              ),
              _buildInfoTile(
                context: context,
                icon: Icons.payment_outlined,
                title: 'Métodos de Pago',
                subtitle: _formatPaymentMethods(profile.paymentMethods),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Editar Perfil'),
                onPressed: () {
                  _logger.info('Navegando a la página de edición de perfil.');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BusinessProfileEditPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Construye un ListTile con información
  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 26),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      ),
    );
  }
}

