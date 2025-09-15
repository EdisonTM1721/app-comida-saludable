import 'package:cloud_firestore/cloud_firestore.dart';

// Enumeración del estado del cupón
enum CouponStatus {
  active,
  expired,
}

// Conversión enum <-> String
String couponStatusToString(CouponStatus status) {
  switch (status) {
    case CouponStatus.active:
      return 'active';
    case CouponStatus.expired:
      return 'expired';
  }
}

CouponStatus stringToCouponStatus(String? statusStr) {
  switch (statusStr?.toLowerCase()) {
    case 'expired':
      return CouponStatus.expired;
    case 'active':
    default:
      return CouponStatus.active;
  }
}

// Modelo de Cupón
class CouponModel {
  final String? id;
  final String code;
  final String promotionId;
  final double discountValue;
  final Timestamp validityDate;
  final double minimumPurchase;
  final CouponStatus status;
  final bool isUsed;
  final String? userId;

  CouponModel({
    this.id,
    required this.code,
    required this.promotionId,
    required this.discountValue,
    required this.validityDate,
    this.minimumPurchase = 0.0,
    required this.status,
    this.isUsed = false,
    this.userId,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: data['code'] ?? '',
      promotionId: data['promotionId'] ?? '',
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      validityDate: data['validityDate'] ?? Timestamp.now(),
      minimumPurchase: (data['minimumPurchase'] ?? 0.0).toDouble(),
      status: stringToCouponStatus(data['status']),
      isUsed: data['isUsed'] ?? false,
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'promotionId': promotionId,
      'discountValue': discountValue,
      'validityDate': validityDate,
      'minimumPurchase': minimumPurchase,
      'status': couponStatusToString(status),
      'isUsed': isUsed,
      'userId': userId,
    };
  }

  CouponModel copyWith({
    String? id,
    String? code,
    String? promotionId,
    double? discountValue,
    Timestamp? validityDate,
    double? minimumPurchase,
    CouponStatus? status,
    bool? isUsed,
    String? userId,
  }) {
    return CouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      promotionId: promotionId ?? this.promotionId,
      discountValue: discountValue ?? this.discountValue,
      validityDate: validityDate ?? this.validityDate,
      minimumPurchase: minimumPurchase ?? this.minimumPurchase,
      status: status ?? this.status,
      isUsed: isUsed ?? this.isUsed,
      userId: userId ?? this.userId,
    );
  }
}
