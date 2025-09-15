import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';

// Clase para mostrar el perfil de negocio
class BusinessProfilePage extends StatelessWidget {
  const BusinessProfilePage({super.key});

  // Construye el widget
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Consumer<ProfileController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const CircularProgressIndicator();
          }

          final profile = controller.businessProfile;
          if (profile == null) {
            return const Text("No hay datos de perfil disponibles.");
          }

          // Muestra los datos del perfil
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty)
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(profile.profileImageUrl!),
                    )
                  else
                    const CircleAvatar(
                      radius: 60,
                      child: Icon(Icons.business, size: 60),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileInfoCard(
                    icon: Icons.info_outline,
                    title: "Descripción",
                    content: profile.description,
                  ),
                  _buildProfileInfoCard(
                    icon: Icons.location_on_outlined,
                    title: "Dirección",
                    content: profile.address,
                  ),
                  _buildProfileInfoCard(
                    icon: Icons.schedule,
                    title: "Horarios de Atención",
                    content: profile.openingHours,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Construye una tarjeta de información
  Widget _buildProfileInfoCard({
    required IconData icon,
    required String title,
    required String? content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content != null && content.isNotEmpty
                        ? content
                        : "No especificado",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
