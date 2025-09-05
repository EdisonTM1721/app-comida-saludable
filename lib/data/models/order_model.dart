import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/user_model.dart';

// Enumeración para representar el estado de un pedido
enum OrderStatus {
  pending,
  preparing,
  shipped,
  delivered,
  cancelled,
}

// Ayudante para convertir OrderStatus a String y viceversa
String orderStatusToString(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'pending';
    case OrderStatus.preparing:
      return 'preparing';
    case OrderStatus.shipped:
      return 'shipped';
    case OrderStatus.delivered:
      return 'delivered';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

// Ayudante para convertir String a OrderStatus
OrderStatus stringToOrderStatus(String? statusStr) {
  switch (statusStr?.toLowerCase()) {
    case 'pending':
      return OrderStatus.pending;
    case 'preparing':
      return OrderStatus.preparing;
    case 'shipped':
      return OrderStatus.shipped;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

// Ayudante para obtener el display string para OrderStatus
String getOrderStatusDisplayString(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pendiente';
    case OrderStatus.preparing:
      return 'En Preparación';
    case OrderStatus.shipped:
      return 'Enviado';
    case OrderStatus.delivered:
      return 'Entregado';
    case OrderStatus.cancelled:
      return 'Cancelado';
  }
}

// Clase para representar un producto en un pedido
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double priceAtPurchase;
  final String? imageUrl;

  // Constructor de la clase
  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtPurchase,
    this.imageUrl,
  });

  // Factory constructor para crear una instancia desde un mapa
    factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      priceAtPurchase: (map['priceAtPurchase'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }

  // Metodo para convertir la instancia en un mapa
    Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'priceAtPurchase': priceAtPurchase,
      'imageUrl': imageUrl,
    };
  }
}

// Clase para representar un pedido
class OrderModel {
  final String? id;
  final String userId;
  final List<OrderItem> items;
  final double totalPrice;
  final OrderStatus status;
  final String shippingAddress;
  final UserModel customerInfo;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Timestamp? deliveredAt;
  final String? couponId;
  final bool? isFeaturedProduct;

  // Constructor de la clase
    OrderModel({
    this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.shippingAddress,
    required this.customerInfo,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.couponId,
    this.isFeaturedProduct,
  });

  // Factory constructor para crear una instancia desde un mapa
    factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>?)
          ?.map((itemMap) => OrderItem.fromMap(itemMap as Map<String, dynamic>))
          .toList() ?? [],
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      status: stringToOrderStatus(data['status']),
      shippingAddress: data['shippingAddress'] ?? 'N/A',
      customerInfo: UserModel.fromEmbeddedData(data['customerInfo'] as Map<String, dynamic>? ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      deliveredAt: data['deliveredAt'],
      couponId: data['couponId'],
      isFeaturedProduct: data['isFeaturedProduct'],
    );
  }

  // Metodo para convertir la instancia en un mapa
    Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': orderStatusToString(status),
      'shippingAddress': shippingAddress,
      'customerInfo': customerInfo.toEmbeddedData(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deliveredAt': deliveredAt,
      'couponId': couponId,
      'isFeaturedProduct': isFeaturedProduct,
    };
  }
}
