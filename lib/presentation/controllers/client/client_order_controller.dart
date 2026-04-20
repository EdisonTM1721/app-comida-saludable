import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/models/shared/order_model.dart';
import 'package:emprendedor/data/repositories/shared/order_repository.dart';

final Logger _logger = Logger('ClientOrderController');

class ClientOrderController extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  OrderModel? _selectedOrder;
  OrderModel? get selectedOrder => _selectedOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _userId;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;

  Future<void> setUserId(String? userId) async {
    if (_userId == userId) return;

    await _ordersSubscription?.cancel();
    _ordersSubscription = null;

    _userId = userId;

    if (_userId == null) {
      _resetState(notify: true);
      return;
    }

    await fetchOrders();
  }

  Future<void> fetchOrders() async {
    _logger.info('Cargando pedidos del cliente...');

    if (_userId == null) {
      _setState(
        errorMessage: 'Usuario no autenticado. No se pueden cargar pedidos.',
        isLoading: false,
      );
      return;
    }

    _setState(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await _ordersSubscription?.cancel();

      _ordersSubscription = _orderRepository.getOrders(_userId!).listen(
            (ordersData) {
          _orders = ordersData;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error, stackTrace) {
          _logger.severe(
            'Error al cargar pedidos del cliente',
            error,
            stackTrace,
          );
          _setState(
            errorMessage: 'Error al cargar pedidos: $error',
            isLoading: false,
          );
        },
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Excepción al iniciar carga de pedidos del cliente',
        e,
        stackTrace,
      );
      _setState(
        errorMessage: 'Error al iniciar carga de pedidos: $e',
        isLoading: false,
      );
    }
  }

  Future<void> fetchOrderDetails(String orderId) async {
    if (_userId == null) {
      _setState(
        errorMessage: 'Usuario no autenticado. No se puede cargar el pedido.',
        isLoading: false,
      );
      return;
    }

    _setState(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final order = await _orderRepository.getOrderById(orderId, _userId!);

      if (order == null) {
        _selectedOrder = null;
        _setState(
          errorMessage: 'El pedido no existe o no tienes permiso para verlo.',
          isLoading: false,
        );
        return;
      }

      _selectedOrder = order;
      _setState(
        isLoading: false,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al cargar detalle del pedido', e, stackTrace);
      _selectedOrder = null;
      _setState(
        errorMessage: 'Error al cargar detalle del pedido: $e',
        isLoading: false,
      );
    }
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  void _resetState({bool notify = false}) {
    _orders = [];
    _selectedOrder = null;
    _errorMessage = null;
    _isLoading = false;

    if (notify) {
      notifyListeners();
    }
  }

  void _setState({
    bool? isLoading,
    String? errorMessage,
    bool notify = true,
  }) {
    final loadingChanged = isLoading != null && _isLoading != isLoading;
    final errorChanged = _errorMessage != errorMessage;

    if (isLoading != null) {
      _isLoading = isLoading;
    }

    _errorMessage = errorMessage;

    if (notify && (loadingChanged || errorChanged)) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _resetState(notify: false);
    super.dispose();
  }
}