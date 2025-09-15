import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/repositories/payment_method_repository.dart';
import 'package:emprendedor/data/models/payment_method_model.dart';

class PaymentMethodController extends ChangeNotifier {
  final Logger _logger = Logger('PaymentMethodController');
  final PaymentMethodRepository _repository = PaymentMethodRepository();

  List<PaymentMethodModel> _paymentMethods = [];
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<PaymentMethodModel>>? _paymentMethodsSubscription;
  String? _userId;

  // ⭐ CORRECCIÓN: El método ahora es asincrónico y devuelve un Future<void> ⭐
  Future<void> setUserId(String? userId) async {
    if (_userId == userId) {
      return;
    }
    _userId = userId;
    if (userId != null) {
      await fetchPaymentMethods();
    }
  }

  @override
  void dispose() {
    _paymentMethodsSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchPaymentMethods() async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return;
    }

    _setLoading(true);
    _clearError();
    await _paymentMethodsSubscription?.cancel();

    try {
      _paymentMethodsSubscription = _repository.getPaymentMethods(_userId!).listen((data) {
        _paymentMethods = data;
        _setLoading(false);
      }, onError: (error, stackTrace) {
        _logger.severe("Error al cargar métodos de pago", error, stackTrace);
        _setError("Error al cargar métodos de pago: $error");
        _setLoading(false);
      });
    } catch (e, stackTrace) {
      _logger.severe("Excepción al iniciar la carga de métodos de pago", e, stackTrace);
      _setError("Error al cargar métodos de pago: $e");
      _setLoading(false);
    }
  }

  Future<void> addPaymentMethod(PaymentMethodModel paymentMethod) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return;
    }
    _setLoading(true);
    _clearError();
    try {
      await _repository.addPaymentMethod(_userId!, paymentMethod);
      _logger.info("Método de pago agregado.");
    } catch (e, stackTrace) {
      _logger.severe("Error al agregar método de pago", e, stackTrace);
      _setError("Error al agregar método de pago: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePaymentMethod(PaymentMethodModel paymentMethod) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return;
    }
    _setLoading(true);
    _clearError();
    try {
      await _repository.updatePaymentMethod(_userId!, paymentMethod);
      _logger.info("Método de pago actualizado.");
    } catch (e, stackTrace) {
      _logger.severe("Error al actualizar método de pago", e, stackTrace);
      _setError("Error al actualizar método de pago: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePaymentMethod(String docId) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return;
    }
    _setLoading(true);
    _clearError();
    try {
      await _repository.deletePaymentMethod(_userId!, docId);
      _logger.info("Método de pago eliminado.");
    } catch (e, stackTrace) {
      _logger.severe("Error al eliminar método de pago", e, stackTrace);
      _setError("Error al eliminar método de pago: $e");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}