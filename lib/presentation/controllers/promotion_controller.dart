import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/data/repositories/promotion_repository.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/models/coupon_model.dart';

// Clase para el controlador de promociones
class PromotionController with ChangeNotifier {
  final Logger _logger = Logger('PromotionController');
  final PromotionRepository _promotionRepository = PromotionRepository();
  List<PromotionModel> _promotions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<PromotionModel> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PromotionController() {
    fetchPromotions();
  }

  // Métodos para interactuar con la base de datos
  Stream<List<PromotionModel>> get promotionsStream =>
      _promotionRepository.getPromotions();

  // Métodos para interactuar con la interfaz de usuario
  Future<void> fetchPromotions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Suscripción al stream de promociones
    _promotionRepository.getPromotions().listen((promos) {
      _promotions = promos;
      _isLoading = false;
      notifyListeners();
    }, onError: (error, stackTrace) {
      _logger.severe("Error fetching promotions", error, stackTrace);
      _errorMessage = "No se pudieron cargar las promociones.";
      _isLoading = false;
      notifyListeners();
    });
  }

  // Métodos para interactuar con la base de datos
  Future<bool> createPromotion(PromotionModel promotion) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _promotionRepository.createPromotion(promotion);
      _logger.info("Promotion '${promotion.name}' created successfully.");
      await fetchPromotions();
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error creating promotion "${promotion.name}"', e, stackTrace);
      _errorMessage = 'No se pudo crear la promoción.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para interactuar con la base de datos
  Future<bool> updatePromotion(PromotionModel promotion) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _promotionRepository.updatePromotion(promotion);
      _logger.info("Promotion '${promotion.name}' updated successfully.");
      await fetchPromotions();
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error updating promotion "${promotion.name}"', e, stackTrace);
      _errorMessage = 'No se pudo actualizar la promoción.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para interactuar con la base de datos
  Future<bool> deletePromotion(String promotionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _promotionRepository.deletePromotion(promotionId);
      _logger.info("Promotion '$promotionId' deleted successfully.");
      await fetchPromotions();
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error deleting promotion "$promotionId"', e, stackTrace);
      _errorMessage = 'No se pudo eliminar la promoción.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para interactuar con la base de datos
  Future<bool> createCoupon(CouponModel coupon) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _promotionRepository.createCoupon(coupon);
      _logger.info("Coupon '${coupon.code}' created successfully for promotion '${coupon.promotionId}'.");
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error creating coupon "${coupon.code}"', e, stackTrace);
      _errorMessage = 'No se pudo crear el cupón.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}