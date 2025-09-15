// Archivo: business_profile_edit_page.dart (CORREGIDO Y OPTIMIZADO)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:emprendedor/data/models/business_profile_model.dart';
import 'package:emprendedor/presentation/pages/main_app_shell.dart';

enum NotificationType { success, error, warning, info }

class BusinessProfileEditPage extends StatefulWidget {
  const BusinessProfileEditPage({super.key});

  @override
  State<BusinessProfileEditPage> createState() => _BusinessProfileEditPageState();
}

class _BusinessProfileEditPageState extends State<BusinessProfileEditPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _openingHoursController;

  File? _selectedImageFile;
  bool _isSaving = false;

  // ⭐ CAMBIO CLAVE: Inicialización de controladores en initState
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _openingHoursController = TextEditingController();

    // ⭐ CORRECCIÓN: Usar addPostFrameCallback para inicializar controladores de forma segura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileController = Provider.of<ProfileController>(context, listen: false);
      if (profileController.businessProfile != null) {
        final profile = profileController.businessProfile!;
        _nameController.text = profile.name;
        _descriptionController.text = profile.description ?? '';
        _addressController.text = profile.address ?? '';
        _openingHoursController.text = profile.openingHours ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  Future<void> _showCustomNotification({
    required BuildContext context,
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (!mounted) return;

    IconData iconData;
    Color backgroundColor;
    Color iconColor = Colors.white;
    switch (type) {
      case NotificationType.success:
        iconData = Icons.check_circle_outline;
        backgroundColor = Colors.green.shade600;
        break;
      case NotificationType.error:
        iconData = Icons.error_outline;
        backgroundColor = Colors.red.shade600;
        break;
      case NotificationType.warning:
        iconData = Icons.warning_amber_outlined;
        backgroundColor = Colors.orange.shade600;
        break;
      case NotificationType.info:
        iconData = Icons.info_outline;
        backgroundColor = Colors.blue.shade600;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;
    final currentContext = context;
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    setState(() => _isSaving = true);

    final profileController = Provider.of<ProfileController>(currentContext, listen: false);
    final user = _auth.currentUser;
    BusinessProfileModel? currentProfile = profileController.businessProfile;

    if (user == null) {
      if (mounted) {
        _showCustomNotification(
          context: currentContext,
          message: 'Error: Usuario no autenticado.',
          type: NotificationType.error,
          duration: const Duration(seconds: 4),
        );
        setState(() => _isSaving = false);
      }
      return;
    }

    final profileDataToSave = (currentProfile ?? BusinessProfileModel(userId: user.uid, name: ''))
        .copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      openingHours: _openingHoursController.text.trim().isEmpty ? null : _openingHoursController.text.trim(),
    );

    bool success = await profileController.saveProfile(
      profileDataToSave,
      imageFile: _selectedImageFile,
    );
    if (!mounted) return;

    if (success) {
      // ⭐ CORRECCIÓN: Navegación sin usar `pop` para asegurar un flujo limpio
      // y evitar la reconstrucción del widget que podría causar el error de tipo.
      Navigator.of(currentContext).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainAppShell()),
      );
    } else {
      _showCustomNotification(
        context: currentContext,
        message: 'Error al actualizar el perfil: ${profileController.errorMessage ?? "Intente de nuevo."}',
        type: NotificationType.error,
        duration: const Duration(seconds: 4),
      );
    }
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil de Negocio'),
      ),
      body: Consumer<ProfileController>(
        builder: (context, profileController, child) {
          // ⭐ Eliminado: Ya no se necesita el booleano `_isInitializing`. La lógica de carga
          // se maneja en el `AuthWrapper` y los controladores se inicializan en `initState`.
          if (profileController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileController.businessProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!)
                                : (profile?.profileImageUrl != null && profile!.profileImageUrl!.isNotEmpty
                                ? NetworkImage(profile.profileImageUrl!)
                                : null) as ImageProvider?,
                            child: (profile?.profileImageUrl == null || profile!.profileImageUrl!.isEmpty) && _selectedImageFile == null
                                ? Icon(Icons.business_outlined, size: 80, color: Colors.grey[600])
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColorLight.withAlpha(229),
                              radius: 22,
                              child: Icon(Icons.camera_alt_outlined, color: Theme.of(context).primaryColorDark, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Negocio', prefixIcon: Icon(Icons.store_outlined)),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa el nombre de tu negocio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Descripción', prefixIcon: Icon(Icons.description_outlined)),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _openingHoursController,
                    decoration: const InputDecoration(labelText: 'Horarios de Atención', prefixIcon: Icon(Icons.access_time_outlined)),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_alt_outlined),
                    label: Text(_isSaving ? 'Guardando Cambios...' : 'Guardar Cambios del Perfil'),
                    onPressed: _isSaving ? null : () => _saveProfile(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}