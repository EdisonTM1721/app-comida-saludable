import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emprendedor/presentation/controllers/client/client_profile_controller.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProfileController>().loadProfile();
    });
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _save(ClientProfileController controller) async {
    final success = await controller.saveProfile();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado correctamente'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClientProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: SafeArea(
        child: controller.isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 34,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Actualiza tu información para que tus pedidos y tu experiencia sean más completos.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller.nameController,
                  decoration: _inputDecoration(
                    label: 'Nombre completo',
                    icon: Icons.person,
                  ),
                  validator: (v) =>
                      controller.validateRequired(v, 'tu nombre'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    label: 'Teléfono',
                    icon: Icons.phone,
                  ),
                  validator: (v) =>
                      controller.validateRequired(v, 'tu teléfono'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.addressController,
                  decoration: _inputDecoration(
                    label: 'Dirección',
                    icon: Icons.location_on,
                  ),
                  validator: (v) =>
                      controller.validateRequired(v, 'tu dirección'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.goalController,
                  decoration: _inputDecoration(
                    label: 'Objetivo alimenticio',
                    icon: Icons.flag,
                  ),
                  validator: (v) =>
                      controller.validateRequired(v, 'tu objetivo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.ageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'Edad',
                    icon: Icons.cake,
                  ),
                  validator: controller.validateAge,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isSaving
                        ? null
                        : () => _save(controller),
                    child: Text(
                      controller.isSaving
                          ? 'Guardando...'
                          : 'Guardar perfil',
                    ),
                  ),
                ),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}