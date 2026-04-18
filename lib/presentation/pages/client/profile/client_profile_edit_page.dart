import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emprendedor/presentation/controllers/client/client_profile_controller.dart';
import 'package:emprendedor/presentation/pages/auth/auth_wrapper.dart';

class ClientProfileEditPage extends StatefulWidget {
  const ClientProfileEditPage({super.key});

  @override
  State<ClientProfileEditPage> createState() => _ClientProfileEditPageState();
}

class _ClientProfileEditPageState extends State<ClientProfileEditPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProfileController>().loadInitialData(null);
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClientProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Cliente'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
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
                    label: 'Objetivo',
                    icon: Icons.flag,
                  ),
                  validator: (v) =>
                      controller.validateRequired(v, 'tu objetivo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.ageController,
                  decoration: _inputDecoration(
                    label: 'Edad',
                    icon: Icons.cake,
                  ),
                  validator: (v) =>
                      controller.validateRequired(v, 'tu edad'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: controller.isSaving
                      ? null
                      : () => _save(controller),
                  child: Text(
                    controller.isSaving
                        ? 'Guardando...'
                        : 'Guardar Perfil',
                  ),
                ),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: Colors.red),
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