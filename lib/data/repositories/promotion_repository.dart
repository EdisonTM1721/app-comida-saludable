
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/core/constants/app_constants.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/data/models/coupon_model.dart';

// Clase para el repositorio de promociones
class PromotionRepository {
  // Declarar e inicializar la instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Promociones
  Future<void> createPromotion(PromotionModel promotion) async {
    await _firestore
        .collection(AppConstants.promotionsCollection)
        .add(promotion.toFirestore());
  }

  // Obtener todas las promociones
  Stream<List<PromotionModel>> getPromotions() {
    return _firestore
        .collection(AppConstants.promotionsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PromotionModel.fromFirestore(doc))
        .toList());
  }

  // Actualizar una promoción
  Future<void> updatePromotion(PromotionModel promotion) async {
    await _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(promotion.id)
        .update(promotion.toFirestore());
  }

  // Eliminar una promoción
  Future<void> deletePromotion(String promotionId) async {
    await _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(promotionId)
        .delete();
  }

  // Cupones
  Future<void> createCoupon(CouponModel coupon) async {
    await _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(coupon.promotionId)
        .collection('coupons')
        .add(coupon.toFirestore());
  }

  // Obtener todos los cupones de una promoción
  Stream<List<CouponModel>> getCouponsByPromotion(String promotionId) {
    return _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(promotionId)
        .collection('coupons')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CouponModel.fromFirestore(doc))
        .toList());
  }
}