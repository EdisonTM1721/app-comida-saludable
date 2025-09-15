import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/core/constants/app_constants.dart';
import 'package:emprendedor/data/models/order_model.dart';
import 'package:logging/logging.dart';

// Crear una instancia de Logger para este repositorio
final Logger logger = Logger('OrderRepository');

// Clase para el repositorio de pedidos
class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todos los pedidos
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

  // Obtener un pedido por su ID
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

  // Actualizar el estado de un pedido
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus, String userId) async {
    try {
      Map<String, dynamic> updateData = {
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
      logger.severe("Error updating order status for order ID: $orderId to $newStatus", e, stackTrace);
      rethrow;
    }
  }

  // Agregar un nuevo pedido
  Future<DocumentReference> addOrder(OrderModel order) async {
    try {
      final data = order.toFirestore();

      if (order.createdAt.seconds == 0) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      data['updatedAt'] = FieldValue.serverTimestamp();

      return await _firestore.collection(AppConstants.ordersCollection).add(data);
    } catch (e, stackTrace) {
      logger.severe("Error adding order for user ID: ${order.userId}", e, stackTrace);
      rethrow;
    }
  }

  // Eliminar un pedido
  Future<void> deleteOrder(String orderId, String userId) async {
    try {
      final orderDoc = await _firestore.collection(AppConstants.ordersCollection).doc(orderId).get();
      if (orderDoc.exists && orderDoc.data()?['userId'] == userId) {
        await _firestore.collection(AppConstants.ordersCollection).doc(orderId).delete();
      } else {
        throw Exception("Order not found or user not authorized to delete this order.");
      }
    } catch (e, stackTrace) {
      logger.severe("Error deleting order by ID: $orderId", e, stackTrace);
      rethrow;
    }
  }
}
