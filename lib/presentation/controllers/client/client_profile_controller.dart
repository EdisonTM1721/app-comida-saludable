import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:emprendedor/data/models/client/client_profile_model.dart';
import 'package:emprendedor/data/repositories/client/client_profile_repository.dart';

class ClientProfileController extends ChangeNotifier {
  final Logger _logger = Logger('ClientProfileController');
  final ClientProfileRepository _repository = ClientProfileRepository();

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final goalController = TextEditingController();
  final ageController = TextEditingController();

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void loadInitialData(ClientProfileModel? profile) {
    nameController.text = profile?.name ?? '';
    phoneController.text = profile?.phone ?? '';
    addressController.text = profile?.address ?? '';
    goalController.text = profile?.dietaryGoal ?? '';
    ageController.text = profile?.age ?? '';
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
      final profile = ClientProfileModel(
        userId: user.uid,
        name: nameController.text.trim(),
        role: 'cliente',
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        dietaryGoal: goalController.text.trim(),
        age: ageController.text.trim(),
      );

      await _repository.saveClientProfile(profile);

      _logger.info('Perfil cliente guardado');
      _setSaving(false);
      return true;
    } catch (e) {
      _logger.severe('Error guardando perfil cliente', e);
      _setError('Error al guardar perfil');
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
    addressController.dispose();
    goalController.dispose();
    ageController.dispose();
    super.dispose();
  }
}