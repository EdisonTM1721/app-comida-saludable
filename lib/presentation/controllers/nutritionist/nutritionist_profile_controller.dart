import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:emprendedor/data/models/nutritionist_profile_model.dart';
import 'package:emprendedor/data/repositories/nutritionist_profile_repository.dart';

class NutritionistProfileController extends ChangeNotifier {
  final Logger _logger = Logger('NutritionistProfileController');
  final NutritionistProfileRepository _repository =
  NutritionistProfileRepository();

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final specialtyController = TextEditingController();
  final descriptionController = TextEditingController();
  final modeController = TextEditingController();

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void loadInitialData(NutritionistProfileModel? profile) {
    nameController.text = profile?.name ?? '';
    phoneController.text = profile?.phone ?? '';
    specialtyController.text = profile?.specialty ?? '';
    descriptionController.text = profile?.professionalDescription ?? '';
    modeController.text = profile?.consultationMode ?? '';
  }

  String? validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $field';
    }
    return null;
  }

  Future<bool> saveProfile() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('No hay usuario autenticado.');
      return false;
    }

    _setError(null);
    _setSaving(true);

    try {
      final profile = NutritionistProfileModel(
        userId: user.uid,
        name: nameController.text.trim(),
        role: 'nutricionista',
        phone: phoneController.text.trim(),
        specialty: specialtyController.text.trim(),
        professionalDescription: descriptionController.text.trim(),
        consultationMode: modeController.text.trim(),
      );

      await _repository.saveNutritionistProfile(profile);

      _logger.info('Perfil de nutricionista guardado correctamente.');
      _setSaving(false);
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error al guardar perfil de nutricionista', e, stackTrace);
      _setError('Ocurrió un error al guardar el perfil.');
      _setSaving(false);
      return false;
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _setSaving(bool value) {
    if (_isSaving == value) return;
    _isSaving = value;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    specialtyController.dispose();
    descriptionController.dispose();
    modeController.dispose();
    super.dispose();
  }
}