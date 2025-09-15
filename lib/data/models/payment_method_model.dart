// Archivo: domain/models/payment_method_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodModel {
  final String? id;
  final String name;
  final dynamic details;
  final String? userId; // ⭐ Campo 'userId' añadido ⭐

  PaymentMethodModel({
    this.id,
    required this.name,
    this.details,
    this.userId, // ⭐ 'userId' añadido al constructor ⭐
  });

  factory PaymentMethodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethodModel(
      id: doc.id,
      name: data['name'] ?? '',
      details: data['details'],
      userId: data['userId'], // ⭐ Leyendo 'userId' desde Firestore ⭐
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'details': details,
      'userId': userId, // ⭐ 'userId' incluido en los datos de Firestore ⭐
    };
  }

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
      userId: userId ?? this.userId, // ⭐ 'userId' incluido en copyWith ⭐
    );
  }
}