import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
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
    if (jsonString == null || jsonString.isEmpty || jsonString.trim() == "[]") {
      return 'No se han establecido métodos de pago';
    }
    try {
      final decoded = json.decode(jsonString);
      _logger.fine('Decoded payment methods: $decoded');
      if (decoded is List && decoded.isNotEmpty) {
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
      return 'Error al cargar métodos de pago';
    }
    return jsonString;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        _logger.finer('Build: Controller BusinessProfile: ${controller.businessProfile?.name}, isLoading: ${controller.isLoading}, error: ${controller.errorMessage}');

        // Manejar el estado de carga
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Manejar el estado de error
        if (controller.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Error: ${controller.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      controller.fetchBusinessProfile();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final profile = controller.businessProfile;

        // **Lógica de verificación de perfil corregida**
        if (profile == null) {
          // Si el perfil no existe, muestra un mensaje y un botón para crearlo
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_alt_1_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Aún no tienes un perfil de negocio! Haz clic en el botón para crear uno y empezar a vender.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _logger.info('Redirigiendo a BusinessProfileEditPage para crear un nuevo perfil.');
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BusinessProfileEditPage()),
                      );
                      if (result == true) {
                        _logger.info('Perfil creado, recargando datos.');
                        await controller.fetchBusinessProfile();
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Crear Perfil'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Si el perfil existe, muestra sus datos
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
                onPressed: () async {
                  _logger.info('Navegando a la página de edición de perfil.');
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BusinessProfileEditPage()),
                  );
                  if (result == true) {
                    _logger.info('Perfil guardado, recargando datos del perfil.');
                    await controller.fetchBusinessProfile();
                  }
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
