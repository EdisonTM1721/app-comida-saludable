import 'package:flutter/material.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/data/models/coupon_model.dart';
import 'package:emprendedor/data/repositories/promotion_repository.dart';

class PromotionController extends ChangeNotifier {
  final PromotionRepository _repository = PromotionRepository();

  List<PromotionModel> promotions = [];
  bool isLoading = false;
  String? errorMessage;

  String? _userId; // Ya no es late

  // Agrega este "getter" para exponer el userId de forma segura
  String? get userId => _userId;

  // ==========================
  // Inicializar userId
  // ==========================
  // Cambia el tipo de parámetro a 'String?'
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    // Llama a fetchPromotions solo si el userId no es nulo
    if (_userId != null) {
      await fetchPromotions();
    }
  }

  bool get hasUserId => _userId != null;

  // ==========================
  // Promociones
  // ==========================
  Stream<List<PromotionModel>> get promotionsStream {
    if (_userId == null) {
      return const Stream.empty(); // Evita usar _userId antes de inicializar
    }
    return _repository.getPromotions(_userId!);
  }

  Future<void> fetchPromotions() async {
    if (_userId == null) return;

    isLoading = true;
    notifyListeners();

    try {
      promotionsStream.listen((data) {
        promotions = data;
        isLoading = false;
        notifyListeners();
      }, onError: (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrUpdatePromotion(PromotionModel promotion) async {
    if (_userId == null) {
      errorMessage = "Usuario no autenticado.";
      return false;
    }
    try {
      if (promotion.id == null) {
        await _repository.createPromotion(promotion, _userId!);
      } else {
        await _repository.updatePromotion(promotion, _userId!);
      }
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deletePromotion(String promotionId) async {
    if (_userId == null) {
      errorMessage = "Usuario no autenticado.";
      return false;
    }
    try {
      await _repository.deletePromotion(promotionId, _userId!);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // ==========================
  // Cupones
  // ==========================
  Stream<List<CouponModel>> getCoupons(String promotionId) {
    if (_userId == null) return const Stream.empty();
    return _repository.getCouponsForPromotion(promotionId, _userId!);
  }

  Future<bool> createCoupon(CouponModel coupon) async {
    if (_userId == null) {
      errorMessage = "Usuario no autenticado.";
      return false;
    }
    try {
      await _repository.createCoupon(coupon, _userId!);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateCoupon(CouponModel coupon) async {
    if (_userId == null) {
      errorMessage = "Usuario no autenticado.";
      return false;
    }
    try {
      await _repository.updateCoupon(coupon, _userId!);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteCoupon(String promotionId, String couponId) async {
    if (_userId == null) {
      errorMessage = "Usuario no autenticado.";
      return false;
    }
    try {
      await _repository.deleteCoupon(promotionId, couponId, _userId!);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }
}