import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/models/payment_method_model.dart';

//Importar FirebaseFirestore desde cloud_firestore
final Logger _logger = Logger('PaymentMethodRepository');

class PaymentMethodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Usar una función para la ruta de la colección
  CollectionReference<Map<String, dynamic>> _getCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('payment_methods');
  }

  Stream<List<PaymentMethodModel>> getPaymentMethods(String userId) {
    try {
      // Usar _getCollection(userId)
      return _getCollection(userId).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => PaymentMethodModel.fromFirestore(doc)).toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener métodos de pago: $e', e, stackTrace);
      rethrow;
    }
  }

  // Añadir un nuevo método de pago
  Future<void> addPaymentMethod(String userId, PaymentMethodModel paymentMethod) async {
    try {
      await _getCollection(userId).add(paymentMethod.toFirestore());
    } catch (e, stackTrace) {
      _logger.severe('Error al añadir método de pago: $e', e, stackTrace);
      rethrow;
    }
  }

  // Actualizar un método de pago
  Future<void> updatePaymentMethod(String userId, PaymentMethodModel paymentMethod) async {
    if (paymentMethod.id == null) {
      throw Exception('ID del documento es nulo para actualizar.');
    }
    try {
      await _getCollection(userId).doc(paymentMethod.id).update(paymentMethod.toFirestore());
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar método de pago: $e', e, stackTrace);
      rethrow;
    }
  }

  // Eliminar un método de pago
  Future<void> deletePaymentMethod(String userId, String docId) async {
    try {
      await _getCollection(userId).doc(docId).delete();
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar método de pago: $e', e, stackTrace);
      rethrow;
    }
  }
}