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
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      priceAtPurchase: (map['priceAtPurchase'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'priceAtPurchase': priceAtPurchase,
    };

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      data['imageUrl'] = imageUrl;
    }

    return data;
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
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return OrderModel(
      id: doc.id,
      orderNumber: (data['orderNumber'] as num?)?.toInt(),
      userId: data['userId']?.toString() ?? '',
      businessUserId: data['businessUserId']?.toString() ?? '',
      items: (data['items'] as List<dynamic>?)
          ?.map(
            (itemMap) => OrderItem.fromMap(
          Map<String, dynamic>.from(itemMap as Map),
        ),
      )
          .toList() ??
          [],
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: stringToOrderStatus(data['status']?.toString()),
      shippingAddress: data['shippingAddress']?.toString() ?? 'N/A',
      paymentMethod: data['paymentMethod']?.toString() ?? 'No especificado',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      customerInfo: UserModel.fromEmbeddedData(
        Map<String, dynamic>.from(
          (data['customerInfo'] as Map?) ?? <String, dynamic>{},
        ),
      ),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
      deliveredAt: data['deliveredAt'] is Timestamp
          ? data['deliveredAt'] as Timestamp
          : null,
      couponId: data['couponId']?.toString(),
      isFeaturedProduct: data['isFeaturedProduct'] as bool?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'orderNumber': orderNumber,
      'userId': userId,
      'businessUserId': businessUserId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': orderStatusToString(status),
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'customerInfo': customerInfo.toEmbeddedData(),
      'createdAt': createdAt,
    };

    if (latitude != null) {
      data['latitude'] = latitude;
    }

    if (longitude != null) {
      data['longitude'] = longitude;
    }

    if (updatedAt != null) {
      data['updatedAt'] = updatedAt;
    }

    if (deliveredAt != null) {
      data['deliveredAt'] = deliveredAt;
    }

    if (couponId != null && couponId!.trim().isNotEmpty) {
      data['couponId'] = couponId;
    }

    if (isFeaturedProduct != null) {
      data['isFeaturedProduct'] = isFeaturedProduct;
    }

    return data;
  }

  String get formattedOrderNumber {
    if (orderNumber == null) return '#----';
    return '#${orderNumber.toString().padLeft(4, '0')}';
  }

  bool get hasOrderNumber => orderNumber != null;
}