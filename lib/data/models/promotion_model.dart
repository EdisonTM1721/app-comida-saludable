import 'package:cloud_firestore/cloud_firestore.dart';

// Enum para los tipos de descuento.
enum DiscountType {
  percentage,
  fixed,
}

// Extensión para obtener el nombre legible del tipo de descuento.
extension DiscountTypeExtension on DiscountType {
  String get displayName {
    switch (this) {
      case DiscountType.percentage:
        return 'Porcentaje';
      case DiscountType.fixed:
        return 'Valor Fijo';
    }
  }
}

// Enum para los estados de la promoción.
enum PromotionStatus {
  active,
  scheduled,
  expired,
}

// Extensión para obtener el nombre legible del estado de la promoción.
extension PromotionStatusExtension on PromotionStatus {
  String get displayName {
    switch (this) {
      case PromotionStatus.active:
        return 'Activa';
      case PromotionStatus.scheduled:
        return 'Programada';
      case PromotionStatus.expired:
        return 'Expirada';
    }
  }
}

// Clase del modelo de promoción.
class PromotionModel {
  String? id;
  final String name;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final Timestamp startDate;
  final Timestamp endDate;
  final PromotionStatus status;
  final String userId;

  // Constructor de la clase.
  PromotionModel({
    this.id,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.userId,
  });

  // Constructor de fábrica para crear una instancia desde un documento de Firestore.
  factory PromotionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PromotionModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      discountType: DiscountType.values.firstWhere(
            (e) => e.toString().split('.').last == data['discountType'],
        orElse: () => DiscountType.percentage,
      ),
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      startDate: data['startDate'] as Timestamp,
      endDate: data['endDate'] as Timestamp,
      status: PromotionStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
        orElse: () => PromotionStatus.scheduled,
      ),
      userId: data['userId'] as String,
    );
  }

  // Método para convertir la instancia en un mapa para Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'discountType': discountType.toString().split('.').last,
      'discountValue': discountValue,
      'startDate': startDate,
      'endDate': endDate,
      'status': status.toString().split('.').last,
      'userId': userId,
    };
  }

  // Método para crear una copia del objeto con valores opcionalmente cambiados.
  PromotionModel copyWith({
    String? id,
    String? name,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    Timestamp? startDate,
    Timestamp? endDate,
    PromotionStatus? status,
    String? userId,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      userId: userId ?? this.userId,
    );
  }
}
