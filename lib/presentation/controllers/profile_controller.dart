// Archivo: profile_controller.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:emprendedor/data/models/business_profile_model.dart';
import 'package:emprendedor/data/repositories/business_profile_repository.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger('ProfileController');

class ProfileController extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final BusinessProfileRepository _repository = BusinessProfileRepository();

  BusinessProfileModel? _businessProfile;
  bool _isLoading = false;
  String? _errorMessage;

  BusinessProfileModel? get businessProfile => _businessProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Agrega este getter para verificar la existencia del perfil
  bool get hasProfile => _businessProfile != null;

  ProfileController({required String userId}) {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        logger.info('ProfileController Constructor: Usuario autenticado (${user.uid}). Llamando a fetchBusinessProfile.');
        fetchBusinessProfile();
      } else {
        logger.info('ProfileController Constructor: Usuario no autenticado o deslogueado. Limpiando perfil y estado.');
        _businessProfile = null;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchBusinessProfile() async {
    logger.info('fetchBusinessProfile: Iniciando carga del perfil...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _errorMessage = "Usuario no autenticado.";
        _businessProfile = null;
        logger.warning('fetchBusinessProfile: No hay usuario autenticado. Perfil establecido a null.');
        return;
      }

      logger.info('fetchBusinessProfile: Intentando obtener perfil del repositorio para el usuario $userId...');
      final BusinessProfileModel? fetchedProfile = await _repository.getBusinessProfile(userId);

      if (fetchedProfile == null) {
        _businessProfile = null;
        _errorMessage = "No se encontró un perfil de negocio para este usuario.";
        logger.info('fetchBusinessProfile: No se encontró perfil en el repositorio para $userId. _businessProfile es null.');
      } else {
        _businessProfile = fetchedProfile;
        _errorMessage = null;
        logger.info('fetchBusinessProfile: Perfil encontrado y asignado para $userId. Nombre: ${_businessProfile?.name}');
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

  Future<bool> saveProfile(BusinessProfileModel profileToSave, {File? imageFile}) async {
    logger.info('saveProfile: Iniciando guardado del perfil para el usuario: ${profileToSave.userId ?? _auth.currentUser?.uid}');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _errorMessage = "Usuario no autenticado. No se puede guardar el perfil.";
        logger.warning('saveProfile: Usuario no autenticado.');
        return false;
      }

      profileToSave = profileToSave.copyWith(userId: userId);

      String? imageUrl = profileToSave.profileImageUrl;
      if (imageFile != null) {
        logger.info('saveProfile: Subiendo imagen...');
        final String imagePath = 'profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = _storage.ref().child(imagePath);
        final uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask.whenComplete(() => logger.info('saveProfile: Subida de imagen completada.'));
        imageUrl = await snapshot.ref.getDownloadURL();
        logger.info("saveProfile: Imagen subida exitosamente: $imageUrl");
      }

      BusinessProfileModel finalProfileToSave = profileToSave.copyWith(
        profileImageUrl: imageUrl,
      );

      if (finalProfileToSave.id != null && finalProfileToSave.id!.isNotEmpty) {
        logger.info("saveProfile: Actualizando perfil existente con ID: ${finalProfileToSave.id}");
        await _repository.updateBusinessProfile(finalProfileToSave);
        logger.info("saveProfile: Perfil actualizado para ${finalProfileToSave.id}");
        _businessProfile = finalProfileToSave;
      } else {
        logger.info("saveProfile: Creando nuevo perfil para el usuario: ${finalProfileToSave.userId}");
        BusinessProfileModel? createdProfile = await _repository.createBusinessProfile(finalProfileToSave);
        if (createdProfile != null) {
          _businessProfile = createdProfile;
          logger.info("saveProfile: Perfil creado con ID: ${createdProfile.id} para ${createdProfile.userId}");
        } else {
          logger.warning("saveProfile: createBusinessProfile devolvió null, no se actualizó _businessProfile local.");
          _businessProfile = finalProfileToSave;
        }
      }

      _errorMessage = null;
      success = true;
      logger.info('saveProfile: Perfil guardado exitosamente en el controlador. Nombre: ${_businessProfile?.name}');
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
      logger.info('saveProfile: Guardado finalizado. Success: $success, isLoading: $_isLoading, hasError: ${_errorMessage != null}, profileName: ${_businessProfile?.name}');
      notifyListeners();
    }
    return success;
  }
}