import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:emprendedor/data/models/order_model.dart';
import 'package:emprendedor/data/repositories/order_repository.dart';

final Logger _logger = Logger('OrderController');

class OrderController extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  OrderModel? _selectedOrder;
  OrderModel? get selectedOrder => _selectedOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _businessUserId;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;

  Future<void> setBusinessUserId(String? businessUserId) async {
    if (_businessUserId == businessUserId) return;

    _businessUserId = businessUserId;

    if (_businessUserId != null) {
      await fetchOrders();
    } else {
      _disposeController();
    }
  }

  void _disposeController() {
    _ordersSubscription?.cancel();
    _orders = [];
    _selectedOrder = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  double get totalVentas {
    return _orders.fold(0.0, (sum, order) => sum + order.totalPrice);
  }

  int get totalPedidos {
    return _orders.length;
  }

  int get activeOrders {
    return _orders
        .where(
          (order) =>
      order.status != OrderStatus.delivered &&
          order.status != OrderStatus.cancelled,
    )
        .length;
  }

  Future<void> fetchOrders() async {
    _logger.info('fetchOrders: Iniciando carga de pedidos...');

    if (_businessUserId == null) {
      _setError('El ID del negocio no está disponible.');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _ordersSubscription?.cancel();

      _ordersSubscription = _orderRepository
          .getOrdersForBusiness(_businessUserId!)
          .listen(
            (ordersData) {
          _orders = ordersData;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error, stackTrace) {
          _logger.severe('Error al cargar pedidos', error, stackTrace);
          _setError('Error al cargar pedidos: $error');
          _setLoading(false);
        },
      );
    } catch (e, stackTrace) {
      _logger.severe('Excepción al iniciar la carga de pedidos', e, stackTrace);
      _setError('Error al iniciar la carga de pedidos: $e');
      _setLoading(false);
    }
  }

  Future<void> fetchOrderDetails(String orderId) async {
    if (_businessUserId == null) {
      _setError('El ID del negocio no está disponible.');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _selectedOrder = await _orderRepository.getOrderByIdForBusiness(
        orderId,
        _businessUserId!,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe('Error al cargar detalles del pedido', e, stackTrace);
      _setError('Error al cargar detalles del pedido: $e');
      _setLoading(false);
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (_businessUserId == null) {
      _setError('El ID del negocio no está disponible.');
      return false;
    }

    _clearError();

    try {
      await _orderRepository.updateOrderStatusForBusiness(
        orderId,
        newStatus,
        _businessUserId!,
      );
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar estado del pedido', e, stackTrace);
      _setError('Error al actualizar estado del pedido: $e');
      return false;
    }
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }
}