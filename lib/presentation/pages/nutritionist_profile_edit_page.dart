import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emprendedor/data/models/nutritionist_profile_model.dart';
import 'package:emprendedor/data/repositories/nutritionist_profile_repository.dart';
import 'package:emprendedor/presentation/pages/auth_wrapper.dart';

class NutritionistProfileEditPage extends StatefulWidget {
  const NutritionistProfileEditPage({super.key});

  @override
  State<NutritionistProfileEditPage> createState() =>
      _NutritionistProfileEditPageState();
}

class _NutritionistProfileEditPageState
    extends State<NutritionistProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _modeController = TextEditingController();

  final _repo = NutritionistProfileRepository();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _descriptionController.dispose();
    _modeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final profile = NutritionistProfileModel(
        userId: user.uid,
        name: _nameController.text.trim(),
        role: 'nutricionista',
        phone: _phoneController.text.trim(),
        specialty: _specialtyController.text.trim(),
        professionalDescription: _descriptionController.text.trim(),
        consultationMode: _modeController.text.trim(),
      );

      await _repo.saveNutritionistProfile(profile);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error al guardar el perfil: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Nutricionista'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
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
                            color: Colors.teal.withOpacity(0.10),
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
                  controller: _nameController,
                  decoration: _inputDecoration(
                    label: 'Nombre completo',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    label: 'Teléfono',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _specialtyController,
                  decoration: _inputDecoration(
                    label: 'Especialidad',
                    icon: Icons.workspace_premium_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu especialidad';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    label: 'Descripción profesional',
                    icon: Icons.description_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa una descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _modeController,
                  decoration: _inputDecoration(
                    label: 'Modalidad de consulta',
                    icon: Icons.video_call_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la modalidad';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar perfil'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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