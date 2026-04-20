import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/repositories/entrepreneur/social_media_repository.dart';
import 'package:emprendedor/data/models/entrepreneur/social_media_model.dart';

// Clase para controlar los enlaces de redes sociales
class SocialMediaController extends ChangeNotifier {
  final Logger _logger = Logger('SocialMediaController');
  final SocialMediaRepository _repository = SocialMediaRepository();

  // Lista de enlaces de redes sociales
  List<SocialMediaModel> _socialMediaList = [];
  List<SocialMediaModel> get socialMediaList => _socialMediaList;

  // Propiedades públicas
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<SocialMediaModel>>? _socialMediaSubscription;
  String? _userId;

  // Constructor
  Future<void> setUserId(String? userId) async {
    if (_userId == userId) {
      return;
    }
    _userId = userId;
    if (userId != null) {
      await fetchSocialMediaLinks();
    }
  }

  // Método para limpiar la lista de enlaces de redes sociales
  @override
  void dispose() {
    _socialMediaSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchSocialMediaLinks() async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return;
    }

    _setLoading(true);
    _clearError();
    await _socialMediaSubscription?.cancel();

    try {
      _socialMediaSubscription = _repository.getSocialMediaLinks(_userId!).listen((data) {
        _socialMediaList = data;
        _setLoading(false);
      }, onError: (error, stackTrace) {
        _logger.severe("Error al cargar enlaces de redes sociales", error, stackTrace);
        _setError("Error al cargar enlaces de redes sociales: $error");
        _setLoading(false);
      });
    } catch (e, stackTrace) {
      _logger.severe("Excepción al iniciar la carga de enlaces de redes sociales", e, stackTrace);
      _setError("Error al cargar enlaces de redes sociales: $e");
      _setLoading(false);
    }
  }

  // Métodos para agregar, actualizar y eliminar enlaces de redes sociales
  Future<void> addSocialMedia(SocialMediaModel socialMedia) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return;
    }
    _setLoading(true);
    _clearError();
    try {
      await _repository.addSocialMedia(_userId!, socialMedia);
      _logger.info("Enlace de red social agregado.");
      await fetchSocialMediaLinks();
    } catch (e, stackTrace) {
      _logger.severe("Error al agregar enlace de red social", e, stackTrace);
      _setError("Error al agregar enlace de red social: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Método para actualizar un enlace de red social
  Future<void> updateSocialMedia(SocialMediaModel socialMedia) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return;
    }
    _setLoading(true);
    _clearError();
    try {
      await _repository.updateSocialMedia(_userId!, socialMedia);
      _logger.info("Enlace de red social actualizado.");
      await fetchSocialMediaLinks();
    } catch (e, stackTrace) {
      _logger.severe("Error al actualizar enlace de red social", e, stackTrace);
      _setError("Error al actualizar enlace de red social: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Método para eliminar un enlace de red social
  Future<void> deleteSocialMedia(String docId) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return;
    }
    _setLoading(true);
    _clearError();
    try {
      await _repository.deleteSocialMedia(_userId!, docId);
      _logger.info("Enlace de red social eliminado.");
      await fetchSocialMediaLinks();
    } catch (e, stackTrace) {
      _logger.severe("Error al eliminar enlace de red social", e, stackTrace);
      _setError("Error al eliminar enlace de red social: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Métodos privados
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Métodos privados
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Métodos privados
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}