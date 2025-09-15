import 'dart:async';
import 'package:flutter/material.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/data/models/coupon_model.dart';
import 'package:emprendedor/data/repositories/promotion_repository.dart';

class PromotionController extends ChangeNotifier {
  final PromotionRepository _repository = PromotionRepository();

  List<PromotionModel> promotions = [];
  bool isLoading = false;
  String? errorMessage;

  String? _userId;
  StreamSubscription<List<PromotionModel>>? _subscription;

  String? get userId => _userId;
  bool get hasUserId => _userId != null;

  Future<void> setUserId(String? userId) async {
    _userId = userId;
    if (_userId != null) {
      await fetchPromotions();
    }
  }

  Stream<List<PromotionModel>> get promotionsStream {
    if (_userId == null) return const Stream.empty();
    return _repository.getPromotions(_userId!);
  }

  Future<void> fetchPromotions() async {
    if (_userId == null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _subscription?.cancel();

    _subscription = promotionsStream.listen(
          (data) {
        promotions = data;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ==========================
  // Promociones CRUD
  // ==========================
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
  // Cupones CRUD
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
      final couponWithUser = coupon.copyWith(userId: _userId);
      await _repository.createCoupon(couponWithUser, _userId!);
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
      final couponWithUser = coupon.copyWith(userId: _userId);
      await _repository.updateCoupon(couponWithUser, _userId!);
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
