import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/data/models/coupon_model.dart';
import 'package:emprendedor/data/repositories/promotion_repository.dart';
import 'package:logging/logging.dart';

// El controlador ahora acepta el userId en su constructor
class PromotionController extends ChangeNotifier {
  String? _userId;
  final PromotionRepository _promotionRepository = PromotionRepository();
  final Logger _logger = Logger('PromotionController');

  // Lista de promociones
  List<PromotionModel> _promotions = [];
  List<PromotionModel> get promotions => _promotions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Constructor vacío
  PromotionController();

  // Nuevo método para inicializar el controlador con el userId
  Future<void> setUserId(String userId) async {
    if (_userId == userId) {
      return; // Evita recargar si el usuario es el mismo
    }
    _userId = userId;
    await fetchPromotions();
  }

  // Método para obtener las promociones del usuario desde Firestore
  Future<void> fetchPromotions() async {
    // AÑADIDO: Verificación de seguridad
    if (_userId == null) {
      _promotions = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _promotionRepository.getPromotions(_userId!).listen((promos) {
        _promotions = promos;
        _isLoading = false;
        notifyListeners();
      }, onError: (error, stackTrace) {
        _logger.severe('Error al obtener el stream de promociones', error, stackTrace);
        _errorMessage = 'Error de Firebase: $error';
        _isLoading = false;
        notifyListeners();
      });
    } on FirebaseException catch (e) {
      _errorMessage = 'Error de Firebase: ${e.message}';
      _promotions = [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _promotions = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para crear o actualizar una promoción
  Future<bool> createOrUpdatePromotion(PromotionModel promotion) async {
    if (_userId == null) {
      _errorMessage = "Usuario no autenticado, no se puede guardar la promoción.";
      notifyListeners();
      return false;
    }
    try {
      if (promotion.id == null) {
        await _promotionRepository.createPromotion(promotion, _userId!);
      } else {
        await _promotionRepository.updatePromotion(promotion, _userId!);
      }
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = 'Error de Firebase: ${e.message}';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      notifyListeners();
      return false;
    }
  }

  // Nuevo método para crear un cupón para una promoción
  Future<bool> createCoupon(CouponModel coupon) async {
    if (_userId == null) {
      _errorMessage = "Usuario no autenticado, no se puede crear el cupón.";
      notifyListeners();
      return false;
    }
    try {
      await _promotionRepository.createCoupon(coupon, _userId!);
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = 'Error de Firebase: ${e.message}';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      notifyListeners();
      return false;
    }
  }

  // Método para eliminar una promoción
  Future<bool> deletePromotion(String promotionId) async {
    if (_userId == null) {
      _errorMessage = "Usuario no autenticado, no se puede eliminar la promoción.";
      notifyListeners();
      return false;
    }
    try {
      await _promotionRepository.deletePromotion(promotionId, _userId!);
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = 'Error de Firebase: ${e.message}';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      notifyListeners();
      return false;
    }
  }
}