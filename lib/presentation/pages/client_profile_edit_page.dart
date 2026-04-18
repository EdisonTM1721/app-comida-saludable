import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emprendedor/data/models/client_profile_model.dart';
import 'package:emprendedor/data/repositories/client_profile_repository.dart';
import 'package:emprendedor/presentation/pages/auth_wrapper.dart';

class ClientProfileEditPage extends StatefulWidget {
  const ClientProfileEditPage({super.key});

  @override
  State<ClientProfileEditPage> createState() => _ClientProfileEditPageState();
}

class _ClientProfileEditPageState extends State<ClientProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _goalController = TextEditingController();
  final _ageController = TextEditingController();

  final _repo = ClientProfileRepository();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _goalController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final profile = ClientProfileModel(
      userId: user.uid,
      name: _nameController.text.trim(),
      role: 'cliente',
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      dietaryGoal: _goalController.text.trim(),
      age: _ageController.text.trim(),
    );

    await _repo.saveClientProfile(profile);

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
        title: const Text('Completar Perfil de Cliente'),
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
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa tu dirección' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(labelText: 'Objetivo alimenticio'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa tu objetivo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Edad'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa tu edad' : null,
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