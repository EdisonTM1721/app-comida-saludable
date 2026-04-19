import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emprendedor/presentation/controllers/nutritionist/nutritionist_profile_controller.dart';
import 'package:emprendedor/presentation/pages/auth/auth_wrapper.dart';

class NutritionistProfileEditPage extends StatefulWidget {
  const NutritionistProfileEditPage({super.key});

  @override
  State<NutritionistProfileEditPage> createState() =>
      _NutritionistProfileEditPageState();
}

class _NutritionistProfileEditPageState
    extends State<NutritionistProfileEditPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionistProfileController>().loadInitialData(null);
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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _save(NutritionistProfileController controller) async {
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
    final controller = context.watch<NutritionistProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Nutricionista'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.health_and_safety_outlined,
                            color: Colors.teal,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completa tu perfil profesional',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Registra tus datos para gestionar consultas, pacientes y recomendaciones.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: controller.nameController,
                  decoration: _inputDecoration(
                    label: 'Nombre completo',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (value) =>
                      controller.validateRequired(value, 'tu nombre'),
                  onChanged: (_) => controller.clearError(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    label: 'Teléfono',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (value) =>
                      controller.validateRequired(value, 'tu teléfono'),
                  onChanged: (_) => controller.clearError(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.specialtyController,
                  decoration: _inputDecoration(
                    label: 'Especialidad',
                    icon: Icons.workspace_premium_outlined,
                  ),
                  validator: (value) =>
                      controller.validateRequired(value, 'tu especialidad'),
                  onChanged: (_) => controller.clearError(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    label: 'Descripción profesional',
                    icon: Icons.description_outlined,
                  ),
                  validator: (value) =>
                      controller.validateRequired(value, 'una descripción'),
                  onChanged: (_) => controller.clearError(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.modeController,
                  decoration: _inputDecoration(
                    label: 'Modalidad de consulta',
                    icon: Icons.video_call_outlined,
                  ),
                  validator: (value) =>
                      controller.validateRequired(value, 'la modalidad'),
                  onChanged: (_) => controller.clearError(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.isSaving
                        ? null
                        : () => _save(controller),
                    icon: controller.isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      controller.isSaving
                          ? 'Guardando...'
                          : 'Guardar perfil',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}