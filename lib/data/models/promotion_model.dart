import 'package:cloud_firestore/cloud_firestore.dart';

// Enumeraciones para representar diferentes tipos de descuentos y estados de promociones
enum DiscountType {
  percentage,
  fixedAmount,
}

// Extensión para la enumeración DiscountType
extension DiscountTypeExtension on DiscountType {
  String get displayName {
    switch (this) {
      case DiscountType.percentage:
        return 'Porcentaje';
      case DiscountType.fixedAmount:
        return 'Monto Fijo';
    }
  }
}

// Enumeración para representar diferentes estados de promociones
enum PromotionStatus {
  active,
  inactive,
  scheduled,
  expired,
}

// Extensión para la enumeración PromotionStatus
extension PromotionStatusExtension on PromotionStatus {
  String get displayName {
    switch (this) {
      case PromotionStatus.active:
        return 'Activa';
      case PromotionStatus.inactive:
        return 'Inactiva';
      case PromotionStatus.scheduled:
        return 'Programada';
      case PromotionStatus.expired:
        return 'Expirada';
    }
  }
}

// Funciones de ayuda para la conversión de enumeraciones
String discountTypeToString(DiscountType type) {
  switch (type) {
    case DiscountType.percentage:
      return 'percentage';
    case DiscountType.fixedAmount:
      return 'fixedAmount';
  }
}

// Función de ayuda para la conversión de string a DiscountType
DiscountType stringToDiscountType(String? typeStr) {
  switch (typeStr?.toLowerCase()) {
    case 'fixedamount':
      return DiscountType.fixedAmount;
    case 'percentage':
    default:
      return DiscountType.percentage;
  }
}

// Función de ayuda para la conversión de PromotionStatus a string
String promotionStatusToString(PromotionStatus status) {
  switch (status) {
    case PromotionStatus.active:
      return 'active';
    case PromotionStatus.inactive:
      return 'inactive';
    case PromotionStatus.scheduled:
      return 'scheduled';
    case PromotionStatus.expired:
      return 'expired';
  }
}

// Función de ayuda para la conversión de string a PromotionStatus
PromotionStatus stringToPromotionStatus(String? statusStr) {
  switch (statusStr?.toLowerCase()) {
    case 'inactive':
      return PromotionStatus.inactive;
    case 'active':
      return PromotionStatus.active;
    case 'scheduled':
      return PromotionStatus.scheduled;
    case 'expired':
      return PromotionStatus.expired;
    default:
      return PromotionStatus.inactive;
  }
}

// Clase para representar una promoción
class PromotionModel {
  final String? id;
  final String name;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final Timestamp startDate;
  final Timestamp endDate;
  final PromotionStatus status;

  // Constructor de la clase
  PromotionModel({
    this.id,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  // Factory constructor para crear una instancia desde un mapa
  factory PromotionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PromotionModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      discountType: stringToDiscountType(data['discountType']),
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      status: stringToPromotionStatus(data['status']),
    );
  }

  // Metodo para convertir la instancia en un mapa
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'startDate': startDate,
      'endDate': endDate,
      'status': promotionStatusToString(status),
    };
  }
}