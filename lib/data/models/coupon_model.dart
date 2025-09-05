import 'package:cloud_firestore/cloud_firestore.dart';

// Definición pública de la enumeración CouponStatus
enum CouponStatus {
  active,
  expired,
}

// Funciones de ayuda públicas para la conversión de la enumeración
String couponStatusToString(CouponStatus status) {
  switch (status) {
    case CouponStatus.active:
      return 'active';
    case CouponStatus.expired:
      return 'expired';
  }
}

// Función de ayuda pública para la conversión de String a CouponStatus
CouponStatus stringToCouponStatus(String? statusStr) {
  switch (statusStr?.toLowerCase()) {
    case 'expired':
      return CouponStatus.expired;
    case 'active':
    default:
      return CouponStatus.active;
  }
}

// Definición de la clase CouponModel
class CouponModel {
  final String? id;
  final String code;
  final String promotionId;
  final double discountValue;
  final Timestamp validityDate;
  final double minimumPurchase;
  final CouponStatus status;
  final bool isUsed;

  // Constructor de la clase CouponModel
  CouponModel({
    this.id,
    required this.code,
    required this.promotionId,
    required this.discountValue,
    required this.validityDate,
    this.minimumPurchase = 0.0,
    required this.status,
    this.isUsed = false,
  });

  // Factory constructor para crear una instancia desde un mapa
  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: data['code'] ?? '',
      promotionId: data['promotionId'] ?? '',
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      validityDate: data['validityDate'] ?? Timestamp.now(),
      minimumPurchase: (data['minimumPurchase'] ?? 0.0).toDouble(),
      status: stringToCouponStatus(data['status']),
      isUsed: data['isUsed'] ?? false,
    );
  }

  // Metodo para convertir la instancia en un mapa
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'promotionId': promotionId,
      'discountValue': discountValue,
      'validityDate': validityDate,
      'minimumPurchase': minimumPurchase,
      'status': couponStatusToString(status),
      'isUsed': isUsed,
    };
  }
}