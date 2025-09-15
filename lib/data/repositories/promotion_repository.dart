import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/core/constants/app_constants.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/data/models/coupon_model.dart';

// Clase para el repositorio de promociones
class PromotionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('PromotionRepository');

  // Obtener todas las promociones
  Stream<List<PromotionModel>> getPromotions(String userId) {
    try {
      return _firestore
          .collection(AppConstants.promotionsCollection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => PromotionModel.fromFirestore(doc))
            .toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error getting promotions stream', e, stackTrace);
      rethrow;
    }
  }

  // Crear una nueva promoción
  Future<void> createPromotion(PromotionModel promotion, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.promotionsCollection)
          .add(promotion.copyWith(userId: userId).toFirestore());
      _logger.info('Promoción "${promotion.name}" agregada exitosamente.');
    } catch (e, stackTrace) {
      _logger.severe('Error creating promotion', e, stackTrace);
      rethrow;
    }
  }

  // Actualizar una promoción
  Future<void> updatePromotion(PromotionModel promotion, String userId) async {
    try {
      final doc = await _firestore.collection(AppConstants.promotionsCollection).doc(promotion.id).get();
      if (!doc.exists || doc.data()?['userId'] != userId) {
        _logger.warning("Intento de actualizar una promoción no autorizada: ${promotion.id} por el usuario $userId");
        throw Exception("No está autorizado para actualizar esta promoción.");
      }
      await _firestore
          .collection(AppConstants.promotionsCollection)
          .doc(promotion.id)
          .update(promotion.copyWith(userId: userId).toFirestore());
      _logger.info('Promoción "${promotion.name}" actualizada exitosamente.');
    } catch (e, stackTrace) {
      _logger.severe('Error updating promotion', e, stackTrace);
      rethrow;
    }
  }

  // Eliminar una promoción
  Future<void> deletePromotion(String promotionId, String userId) async {
    try {
      final doc = await _firestore.collection(AppConstants.promotionsCollection).doc(promotionId).get();
      if (doc.exists && doc.data()?['userId'] == userId) {
        await _firestore
            .collection(AppConstants.promotionsCollection)
            .doc(promotionId)
            .delete();
        _logger.info('Promoción "$promotionId" eliminada exitosamente.');
      } else {
        _logger.warning("Intento de eliminar una promoción no autorizada: $promotionId por el usuario $userId");
        throw Exception("No está autorizado para eliminar esta promoción.");
      }
    } catch (e, stackTrace) {
      _logger.severe('Error deleting promotion', e, stackTrace);
      rethrow;
    }
  }

  // Ahora el método verifica la propiedad del usuario antes de devolver el stream de cupones.
  Stream<List<CouponModel>> getCouponsForPromotion(String promotionId, String userId) {
    try {
      return _firestore
          .collection(AppConstants.promotionsCollection)
          .doc(promotionId)
          .snapshots()
          .asyncExpand((promoSnapshot) {
        if (!promoSnapshot.exists || promoSnapshot.data()?['userId'] != userId) {
          _logger.warning("Acceso no autorizado a cupones de la promoción: $promotionId");
          return Stream.error(Exception("No está autorizado para ver estos cupones."));
        }
        return _firestore
            .collection(AppConstants.promotionsCollection)
            .doc(promotionId)
            .collection(AppConstants.couponsSubcollection)
            .snapshots()
            .map((couponSnapshot) =>
            couponSnapshot.docs.map((doc) => CouponModel.fromFirestore(doc)).toList());
      });
    } catch (e, stackTrace) {
      _logger.severe('Error getting coupons for promotion $promotionId', e, stackTrace);
      rethrow;
    }
  }

  // Crear un nuevo cupón
  Future<void> createCoupon(CouponModel coupon, String userId) async {
    try {
      final promoDoc = await _firestore.collection(AppConstants.promotionsCollection).doc(coupon.promotionId).get();
      if (!promoDoc.exists || promoDoc.data()?['userId'] != userId) {
        _logger.warning("Intento de crear un cupón en una promoción no autorizada: ${coupon.promotionId} por el usuario $userId");
        throw Exception("No está autorizado para crear cupones en esta promoción.");
      }
      await _firestore
          .collection(AppConstants.promotionsCollection)
          .doc(coupon.promotionId)
          .collection(AppConstants.couponsSubcollection)
          .add(coupon.toFirestore());
      _logger.info('Cupón "${coupon.code}" agregado exitosamente a la promoción "${coupon.promotionId}".');
    } catch (e, stackTrace) {
      _logger.severe('Error creating coupon', e, stackTrace);
      rethrow;
    }
  }

  // Actualizar un cupón
  Future<void> updateCoupon(CouponModel coupon, String userId) async {
    try {
      final promoDoc = await _firestore.collection(AppConstants.promotionsCollection).doc(coupon.promotionId).get();
      if (!promoDoc.exists || promoDoc.data()?['userId'] != userId) {
        _logger.warning("Intento de actualizar un cupón en una promoción no autorizada: ${coupon.promotionId} por el usuario $userId");
        throw Exception("No está autorizado para actualizar cupones en esta promoción.");
      }
      await _firestore
          .collection(AppConstants.promotionsCollection)
          .doc(coupon.promotionId)
          .collection(AppConstants.couponsSubcollection)
          .doc(coupon.id)
          .update(coupon.toFirestore());
      _logger.info('Cupón "${coupon.code}" actualizado exitosamente.');
    } catch (e, stackTrace) {
      _logger.severe('Error updating coupon', e, stackTrace);
      rethrow;
    }
  }

  // Eliminar un cupón
  Future<void> deleteCoupon(String promotionId, String couponId, String userId) async {
    try {
      final promoDoc = await _firestore.collection(AppConstants.promotionsCollection).doc(promotionId).get();
      if (!promoDoc.exists || promoDoc.data()?['userId'] != userId) {
        _logger.warning("Intento de eliminar un cupón en una promoción no autorizada: $promotionId por el usuario $userId");
        throw Exception("No está autorizado para eliminar cupones en esta promoción.");
      }
      await _firestore
          .collection(AppConstants.promotionsCollection)
          .doc(promotionId)
          .collection(AppConstants.couponsSubcollection)
          .doc(couponId)
          .delete();
      _logger.info('Cupón "$couponId" eliminado exitosamente.');
    } catch (e, stackTrace) {
      _logger.severe('Error deleting coupon', e, stackTrace);
      rethrow;
    }
  }
}