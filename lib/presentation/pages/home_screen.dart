import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';

// Pantalla principal
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usa un Consumer para escuchar los cambios en el ProfileController
    return Consumer<ProfileController>(
      builder: (context, profileController, child) {
        // Muestra un indicador de carga si el perfil no ha sido cargado
        if (profileController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final userName = profileController.businessProfile?.name;
        final greetingText = userName?.isNotEmpty == true ? 'Hola, $userName' : 'Hola, Emprendedor';

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agrega el saludo aquí
                Text(
                  greetingText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Tarjetas de resumen
                const InfoCard(
                  title: 'Ventas de hoy',
                  value: '\$0.00',
                  valueColor: Colors.green,
                ),
                const SizedBox(height: 16),
                const InfoCard(
                  title: 'Pedidos activos',
                  value: '0',
                ),
                const SizedBox(height: 16),

                // Sección de productos más vendidos
                Text(
                  'Productos más vendidos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No hay productos más vendidos aún.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget reutilizable para tarjetas de información
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
