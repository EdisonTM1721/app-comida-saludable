import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:emprendedor/data/models/business_profile_model.dart';
import 'package:emprendedor/data/repositories/business_profile_repository.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger('ProfileController');

// Clase para controlar el perfil del negocio
class ProfileController extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final BusinessProfileRepository _repository = BusinessProfileRepository();

  // Propiedades privadas
  BusinessProfileModel? _businessProfile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;

  // Propiedades públicas
  BusinessProfileModel? get businessProfile => _businessProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _businessProfile != null;
  String? get userId => _userId;

  // Constructor
  ProfileController();

  // Métodos públicos
  Future<void> setUserId(String userId) async {
    if (_userId == userId) {
      return;
    }
    _userId = userId;
    logger.info('ProfileController inicializado para el usuario: $_userId.');
    await fetchBusinessProfile();
  }

  // Métodos privados
  Future<void> fetchBusinessProfile() async {
    logger.info('fetchBusinessProfile: Iniciando carga del perfil...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_userId == null) {
        _errorMessage = "Usuario no autenticado.";
        _businessProfile = null;
        logger.warning('fetchBusinessProfile: No hay usuario autenticado. Perfil establecido a null.');
        return;
      }

      logger.info('fetchBusinessProfile: Intentando obtener perfil del repositorio para el usuario $_userId...');
      final BusinessProfileModel? fetchedProfile = await _repository.getBusinessProfile(_userId!);

      if (fetchedProfile == null) {
        _businessProfile = null;
        _errorMessage = "No se encontró un perfil de negocio para este usuario.";
        logger.info('fetchBusinessProfile: No se encontró perfil en el repositorio para $_userId. _businessProfile es null.');
      } else {
        _businessProfile = fetchedProfile;
        _errorMessage = null;
        logger.info('fetchBusinessProfile: Perfil encontrado y asignado para $_userId. Nombre: ${_businessProfile?.name}');
      }
    } catch (e, stackTrace) {
      _errorMessage = "Error al obtener el perfil: ${e.toString()}";
      _businessProfile = null;
      logger.severe('fetchBusinessProfile: Excepción capturada durante la obtención del perfil. _businessProfile es null.', e, stackTrace);
    } finally {
      _isLoading = false;
      logger.info('fetchBusinessProfile: Carga finalizada. isLoading: $_isLoading, hasError: ${_errorMessage != null}, profileName: ${_businessProfile?.name}');
      notifyListeners();
    }
  }

  // Métodos públicos
  Future<bool> saveProfile(BusinessProfileModel profileToSave, {File? imageFile}) async {
    logger.info('saveProfile: Iniciando guardado del perfil...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;

    try {
      if (_userId == null) {
        _errorMessage = "Usuario no autenticado. No se puede guardar el perfil.";
        logger.warning('saveProfile: Usuario no autenticado.');
        return false;
      }

      profileToSave = profileToSave.copyWith(userId: _userId);

      String? imageUrl = profileToSave.profileImageUrl;
      if (imageFile != null) {
        logger.info('saveProfile: Subiendo imagen...');
        final String imagePath = 'profile_images/$_userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = _storage.ref().child(imagePath);
        final uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask.whenComplete(() => logger.info('saveProfile: Subida de imagen completada.'));
        imageUrl = await snapshot.ref.getDownloadURL();
        logger.info("saveProfile: Imagen subida exitosamente: $imageUrl");
      }

      final BusinessProfileModel finalProfileToSave = profileToSave.copyWith(
        profileImageUrl: imageUrl,
      );

      if (finalProfileToSave.id != null && finalProfileToSave.id!.isNotEmpty) {
        logger.info("saveProfile: Actualizando perfil existente con ID: ${finalProfileToSave.id}");
        await _repository.updateBusinessProfile(finalProfileToSave);
      } else {
        logger.info("saveProfile: Creando nuevo perfil para el usuario: $_userId");
        await _repository.createBusinessProfile(finalProfileToSave);
      }

      // Actualizar el perfil localmente
      await fetchBusinessProfile();

      success = true;
      logger.info('saveProfile: Perfil guardado exitosamente.');
    } on FirebaseException catch (e, stackTrace) {
      _errorMessage = "Error de Firebase al guardar el perfil: ${e.message ?? e.code}";
      logger.severe('saveProfile: Error de Firebase. $_errorMessage', e, stackTrace);
      success = false;
    } catch (e, stackTrace) {
      _errorMessage = "Error inesperado al guardar el perfil: ${e.toString()}";
      logger.severe('saveProfile: Error inesperado. $_errorMessage', e, stackTrace);
      success = false;
    } finally {
      _isLoading = false;
      logger.info('saveProfile: Guardado finalizado. Success: $success, isLoading: $_isLoading, hasError: ${_errorMessage != null}');
      notifyListeners();
    }
    return success;
  }
}