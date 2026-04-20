import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo de datos para representar un método de pago
class PaymentMethodModel {
  final String? id;
  final String name;
  final dynamic details;
  final String? userId;

  // Constructor
  PaymentMethodModel({
    this.id,
    required this.name,
    this.details,
    this.userId,
  });

  // Factory constructor para crear una instancia desde un mapa
  factory PaymentMethodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethodModel(
      id: doc.id,
      name: data['name'] ?? '',
      details: data['details'],
      userId: data['userId'],
    );
  }

  // Metodo para convertir la instancia en un mapa
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'details': details,
      'userId': userId,
    };
  }

  // Metodo para clonar el modelo
  PaymentMethodModel copyWith({
    String? id,
    String? name,
    dynamic details,
    String? userId,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      userId: userId ?? this.userId,
    );
  }
}