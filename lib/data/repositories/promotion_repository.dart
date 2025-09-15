import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/core/constants/app_constants.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/data/models/coupon_model.dart';

class PromotionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('PromotionRepository');

  // ==========================
  // PROMOCIONES
  // ==========================

  Stream<List<PromotionModel>> getPromotions(String userId) {
    return _firestore
        .collection(AppConstants.promotionsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => PromotionModel.fromFirestore(doc)).toList());
  }

  Future<void> createPromotion(PromotionModel promotion, String userId) async {
    await _firestore
        .collection(AppConstants.promotionsCollection)
        .add(promotion.copyWith(userId: userId).toFirestore());
    _logger.info('Promoción "${promotion.name}" creada.');
  }

  Future<void> updatePromotion(PromotionModel promotion, String userId) async {
    final docRef = _firestore.collection(AppConstants.promotionsCollection).doc(promotion.id);
    final doc = await docRef.get();

    if (!doc.exists || doc.data()?['userId'] != userId) {
      throw Exception("No autorizado para actualizar esta promoción.");
    }

    await docRef.update(promotion.copyWith(userId: userId).toFirestore());
    _logger.info('Promoción "${promotion.name}" actualizada.');
  }

  Future<void> deletePromotion(String promotionId, String userId) async {
    final docRef = _firestore.collection(AppConstants.promotionsCollection).doc(promotionId);
    final doc = await docRef.get();

    if (!doc.exists || doc.data()?['userId'] != userId) {
      throw Exception("No autorizado para eliminar esta promoción.");
    }

    await docRef.delete();
    _logger.info('Promoción "$promotionId" eliminada.');
  }

  // ==========================
  // CUPONES
  // ==========================

  Stream<List<CouponModel>> getCouponsForPromotion(String promotionId, String userId) {
    return _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(promotionId)
        .snapshots()
        .asyncExpand((promoSnapshot) {
      if (!promoSnapshot.exists || promoSnapshot.data()?['userId'] != userId) {
        return Stream.error(Exception("No autorizado para ver los cupones de esta promoción."));
      }
      return _firestore
          .collection(AppConstants.promotionsCollection)
          .doc(promotionId)
          .collection(AppConstants.couponsSubcollection)
          .snapshots()
          .map((snapshot) =>
          snapshot.docs.map((doc) => CouponModel.fromFirestore(doc)).toList());
    });
  }

  Future<void> createCoupon(CouponModel coupon, String userId) async {
    final promoDoc = await _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(coupon.promotionId)
        .get();

    if (!promoDoc.exists || promoDoc.data()?['userId'] != userId) {
      throw Exception("No autorizado para crear cupones en esta promoción.");
    }

    await _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(coupon.promotionId)
        .collection(AppConstants.couponsSubcollection)
        .add(coupon.toFirestore());

    _logger.info('Cupón "${coupon.code}" creado en la promoción "${coupon.promotionId}".');
  }

  Future<void> updateCoupon(CouponModel coupon, String userId) async {
    final promoDoc = await _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(coupon.promotionId)
        .get();

    if (!promoDoc.exists || promoDoc.data()?['userId'] != userId) {
      throw Exception("No autorizado para actualizar cupones en esta promoción.");
    }

    await _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(coupon.promotionId)
        .collection(AppConstants.couponsSubcollection)
        .doc(coupon.id)
        .update(coupon.toFirestore());

    _logger.info('Cupón "${coupon.code}" actualizado.');
  }

  Future<void> deleteCoupon(String promotionId, String couponId, String userId) async {
    final promoDoc = await _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(promotionId)
        .get();

    if (!promoDoc.exists || promoDoc.data()?['userId'] != userId) {
      throw Exception("No autorizado para eliminar cupones en esta promoción.");
    }

    await _firestore
        .collection(AppConstants.promotionsCollection)
        .doc(promotionId)
        .collection(AppConstants.couponsSubcollection)
        .doc(couponId)
        .delete();

    _logger.info('Cupón "$couponId" eliminado de la promoción "$promotionId".');
  }
}
