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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil de Nutricionista'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa tu teléfono' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'Especialidad'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa tu especialidad' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción profesional'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa una descripción' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modeController,
                decoration: const InputDecoration(labelText: 'Modalidad de consulta'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa la modalidad' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: Text(_isSaving ? 'Guardando...' : 'Guardar Perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}