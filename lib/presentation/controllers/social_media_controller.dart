import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/repositories/social_media_repository.dart';
import 'package:emprendedor/data/models/social_media_model.dart';

class SocialMediaController extends ChangeNotifier {
  final Logger _logger = Logger('SocialMediaController');
  final SocialMediaRepository _repository = SocialMediaRepository();

  List<SocialMediaModel> _socialMediaList = [];
  List<SocialMediaModel> get socialMediaList => _socialMediaList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<SocialMediaModel>>? _socialMediaSubscription;
  String? _userId;

  // Corrected method signature
  Future<void> setUserId(String? userId) async {
    if (_userId == userId) {
      return;
    }
    _userId = userId;
    if (userId != null) {
      await fetchSocialMediaLinks();
    }
  }

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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}