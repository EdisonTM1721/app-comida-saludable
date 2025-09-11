import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/data/models/coupon_model.dart';

// El controlador ahora acepta el userId en su constructor
class PromotionController extends ChangeNotifier {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lista de promociones
  List<PromotionModel> _promotions = [];
  List<PromotionModel> get promotions => _promotions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Constructor que recibe el userId
  PromotionController({required this.userId}) {
    fetchPromotions();
  }

  // Método para obtener las promociones del usuario desde Firestore
  Future<void> fetchPromotions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final promotionCollection = _firestore.collection('promotions').doc(userId).collection('user_promotions');
      final querySnapshot = await promotionCollection.get();

      _promotions = querySnapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _errorMessage = 'Error de Firebase: ${e.message}';
      _promotions = [];
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _promotions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para crear o actualizar una promoción
  Future<bool> createOrUpdatePromotion(PromotionModel promotion) async {
    try {
      final promotionCollection = _firestore.collection('promotions').doc(userId).collection('user_promotions');
      if (promotion.id == null) {
        await promotionCollection.add(promotion.toFirestore());
      } else {
        await promotionCollection.doc(promotion.id).update(promotion.toFirestore());
      }
      await fetchPromotions();
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
    try {
      final couponCollection = _firestore
          .collection('promotions')
          .doc(userId)
          .collection('user_promotions')
          .doc(coupon.promotionId)
          .collection('coupons');

      await couponCollection.add(coupon.toFirestore());
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
    try {
      final promotionRef = _firestore.collection('promotions').doc(userId).collection('user_promotions').doc(promotionId);
      await promotionRef.delete();
      await fetchPromotions();
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
