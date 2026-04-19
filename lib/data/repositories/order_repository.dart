import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/core/constants/app_constants.dart';
import 'package:emprendedor/data/models/order_model.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger('OrderRepository');

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================
  // PEDIDOS DEL CLIENTE
  // =========================

  Stream<List<OrderModel>> getOrders(String userId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  Future<OrderModel?> getOrderById(String orderId, String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists && doc.data()?['userId'] == userId) {
        return OrderModel.fromFirestore(doc);
      }

      return null;
    } catch (e, stackTrace) {
      logger.severe("Error fetching order by ID: $orderId", e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateOrderStatus(
      String orderId,
      OrderStatus newStatus,
      String userId,
      ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists || doc.data()?['userId'] != userId) {
        throw Exception(
          "Pedido no encontrado o usuario no autorizado para actualizarlo.",
        );
      }

      final Map<String, dynamic> updateData = {
        'status': orderStatusToString(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);
    } catch (e, stackTrace) {
      logger.severe(
        "Error updating order status for order ID: $orderId to $newStatus",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // =========================
  // PEDIDOS DEL EMPRENDEDOR
  // =========================

  Stream<List<OrderModel>> getOrdersForBusiness(String businessUserId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('businessUserId', isEqualTo: businessUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  Future<OrderModel?> getOrderByIdForBusiness(
      String orderId,
      String businessUserId,
      ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists && doc.data()?['businessUserId'] == businessUserId) {
        return OrderModel.fromFirestore(doc);
      }

      return null;
    } catch (e, stackTrace) {
      logger.severe(
        "Error fetching business order by ID: $orderId",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updateOrderStatusForBusiness(
      String orderId,
      OrderStatus newStatus,
      String businessUserId,
      ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists || doc.data()?['businessUserId'] != businessUserId) {
        throw Exception(
          "Pedido no encontrado o negocio no autorizado para actualizarlo.",
        );
      }

      final Map<String, dynamic> updateData = {
        'status': orderStatusToString(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);
    } catch (e, stackTrace) {
      logger.severe(
        "Error updating business order status for order ID: $orderId to $newStatus",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // =========================
  // CREAR PEDIDO CON NUMERACIÓN PRO
  // =========================

  Future<DocumentReference> addOrder(OrderModel order) async {
    try {
      final ordersRef = _firestore.collection(AppConstants.ordersCollection);

      // Colección para llevar contador por negocio
      final countersRef = _firestore.collection('order_counters');
      final counterDocRef = countersRef.doc(order.businessUserId);

      return await _firestore.runTransaction((transaction) async {
        final counterSnapshot = await transaction.get(counterDocRef);

        int nextOrderNumber = 1;

        if (counterSnapshot.exists) {
          final currentLastNumber =
          (counterSnapshot.data()?['lastOrderNumber'] ?? 0) as int;
          nextOrderNumber = currentLastNumber + 1;
        }

        final data = order.toFirestore();

        data['orderNumber'] = nextOrderNumber;
        data['updatedAt'] = FieldValue.serverTimestamp();

        if (order.createdAt.seconds == 0) {
          data['createdAt'] = FieldValue.serverTimestamp();
        }

        final newOrderRef = ordersRef.doc();
        transaction.set(newOrderRef, data);

        transaction.set(
          counterDocRef,
          {
            'businessUserId': order.businessUserId,
            'lastOrderNumber': nextOrderNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return newOrderRef;
      });
    } catch (e, stackTrace) {
      logger.severe(
        "Error adding order for user ID: ${order.userId}",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId, String userId) async {
    try {
      final orderDoc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (orderDoc.exists && orderDoc.data()?['userId'] == userId) {
        await _firestore
            .collection(AppConstants.ordersCollection)
            .doc(orderId)
            .delete();
      } else {
        throw Exception(
          "Order not found or user not authorized to delete this order.",
        );
      }
    } catch (e, stackTrace) {
      logger.severe("Error deleting order by ID: $orderId", e, stackTrace);
      rethrow;
    }
  }
}