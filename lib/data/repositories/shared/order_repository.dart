import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/core/constants/app_constants.dart';
import 'package:emprendedor/data/models/shared/order_model.dart';
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
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<OrderModel?> getOrderById(String orderId, String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();

      if (data == null || data['userId'] != userId) {
        return null;
      }

      return OrderModel.fromFirestore(doc);
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
      final docRef = _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId);

      final doc = await docRef.get();

      if (!doc.exists || doc.data()?['userId'] != userId) {
        throw Exception(
          "Pedido no encontrado o usuario no autorizado.",
        );
      }

      final updateData = <String, dynamic>{
        'status': orderStatusToString(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await docRef.update(updateData);
    } catch (e, stackTrace) {
      logger.severe(
        "Error updating order status: $orderId",
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
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
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

      if (!doc.exists) return null;

      final data = doc.data();

      if (data == null || data['businessUserId'] != businessUserId) {
        return null;
      }

      return OrderModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      logger.severe(
        "Error fetching business order: $orderId",
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
      final docRef = _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId);

      final doc = await docRef.get();

      if (!doc.exists || doc.data()?['businessUserId'] != businessUserId) {
        throw Exception(
          "Pedido no autorizado para este negocio.",
        );
      }

      final updateData = <String, dynamic>{
        'status': orderStatusToString(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await docRef.update(updateData);
    } catch (e, stackTrace) {
      logger.severe(
        "Error updating business order status: $orderId",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // =========================
  // CREAR PEDIDO (NUMERACIÓN PRO CORREGIDA)
  // =========================

  Future<DocumentReference> addOrder(OrderModel order) async {
    try {
      final ordersRef = _firestore.collection(AppConstants.ordersCollection);

      final countersRef = _firestore.collection('order_counters');
      final counterDocRef = countersRef.doc(order.businessUserId);

      return await _firestore.runTransaction((transaction) async {
        final counterSnapshot = await transaction.get(counterDocRef);

        int currentLastNumber = 0;

        if (counterSnapshot.exists) {
          currentLastNumber =
              (counterSnapshot.data()?['lastOrderNumber'] as num?)
                  ?.toInt() ??
                  0;
        }

        final nextOrderNumber = currentLastNumber + 1;

        final data = order.toFirestore();

        // 🔥 FORZAMOS valores correctos SIEMPRE
        data['orderNumber'] = nextOrderNumber;
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();

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
        "Error adding order for user: ${order.userId}",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId, String userId) async {
    try {
      final docRef = _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId);

      final orderDoc = await docRef.get();

      if (!orderDoc.exists || orderDoc.data()?['userId'] != userId) {
        throw Exception("No autorizado para eliminar este pedido.");
      }

      await docRef.delete();
    } catch (e, stackTrace) {
      logger.severe("Error deleting order: $orderId", e, stackTrace);
      rethrow;
    }
  }
}