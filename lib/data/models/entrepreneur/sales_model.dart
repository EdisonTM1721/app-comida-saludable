import 'package:cloud_firestore/cloud_firestore.dart';

// Clase para representar un modelo de ventas
class SalesModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final Timestamp saleDate;
  final String? customerName;

  // Constructor de la clase
  SalesModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.saleDate,
    this.customerName,
  });

  // Factory constructor para crear una instancia desde un mapa
  factory SalesModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SalesModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: (data['quantity'] as num? ?? 0.0).toDouble(),
      unitPrice: (data['unitPrice'] as num? ?? 0.0).toDouble(),
      saleDate: data['saleDate'] as Timestamp? ?? Timestamp.now(),
      customerName: data['customerName'] as String?,
    );
  }

  // Metodo para convertir la instancia en un mapa
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'saleDate': saleDate,
      'customerName': customerName,
    };
  }
}