import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/shared/user_model.dart';

enum OrderStatus {
  pending,
  preparing,
  shipped,
  delivered,
  cancelled,
}

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

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double priceAtPurchase;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtPurchase,
    this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      priceAtPurchase: (map['priceAtPurchase'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }

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

class OrderModel {
  final String? id;
  final int? orderNumber;
  final String userId;
  final String businessUserId;
  final List<OrderItem> items;
  final double totalPrice;
  final OrderStatus status;
  final String shippingAddress;
  final String paymentMethod;
  final double? latitude;
  final double? longitude;
  final UserModel customerInfo;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Timestamp? deliveredAt;
  final String? couponId;
  final bool? isFeaturedProduct;

  OrderModel({
    this.id,
    this.orderNumber,
    required this.userId,
    required this.businessUserId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.latitude,
    this.longitude,
    required this.customerInfo,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.couponId,
    this.isFeaturedProduct,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OrderModel(
      id: doc.id,
      orderNumber: (data['orderNumber'] as num?)?.toInt(),
      userId: data['userId'] ?? '',
      businessUserId: data['businessUserId'] ?? '',
      items: (data['items'] as List<dynamic>?)
          ?.map(
            (itemMap) =>
            OrderItem.fromMap(itemMap as Map<String, dynamic>),
      )
          .toList() ??
          [],
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      status: stringToOrderStatus(data['status']),
      shippingAddress: data['shippingAddress'] ?? 'N/A',
      paymentMethod: data['paymentMethod'] ?? 'No especificado',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      customerInfo: UserModel.fromEmbeddedData(
        data['customerInfo'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      deliveredAt: data['deliveredAt'],
      couponId: data['couponId'],
      isFeaturedProduct: data['isFeaturedProduct'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'userId': userId,
      'businessUserId': businessUserId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': orderStatusToString(status),
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'latitude': latitude,
      'longitude': longitude,
      'customerInfo': customerInfo.toEmbeddedData(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deliveredAt': deliveredAt,
      'couponId': couponId,
      'isFeaturedProduct': isFeaturedProduct,
    };
  }
}