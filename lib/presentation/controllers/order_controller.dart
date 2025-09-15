import 'dart:async';
import 'package:flutter/material.dart';
import 'package:emprendedor/data/models/order_model.dart';
import 'package:emprendedor/data/repositories/order_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('OrderController');

// Clase para controlar los pedidos
class OrderController extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Propiedades privadas
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

  // Constructor
  OrderController();

  // Métodos públicos
  Future<void> setUserId(String userId) async {
    if (_userId == userId) {
      return;
    }
    _userId = userId;

    // Cancelar la suscripción anterior si existe
    await _ordersSubscription?.cancel();
  }

  // Métodos privados
  void disposeController() {
    _ordersSubscription?.cancel();
    _orders = [];
    _selectedOrder = null;
    notifyListeners();
  }

  // Propiedades calculadas
  double get totalVentas {
    return _orders.fold(0.0, (sum, order) => sum + order.totalPrice);
  }

  // Cantidad de pedidos
  int get totalPedidos {
    return _orders.length;
  }

  // Cantidad de pedidos activos
  int get activeOrders {
    return _orders.where((order) => order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled).length;
  }

  // Cantidad de pedidos entregados
  Future<void> fetchOrders() async {
    _logger.info("fetchOrders: Iniciando carga de pedidos...");
    if (_userId == null) {
      _setError("El ID de usuario no está disponible.");
      return;
    }

    // Cancelar la suscripción anterior si existe
    _setLoading(true);
    _clearError();
    try {
      await _ordersSubscription?.cancel();
      _ordersSubscription = _orderRepository.getOrders(_userId!).listen((ordersData) {
        _orders = ordersData;
        _setLoading(false);
        notifyListeners();
      }, onError: (error, stackTrace) {
        _logger.severe("Error al cargar pedidos: ", error, stackTrace);
        _setError("Error al cargar pedidos: $error");
        _setLoading(false);
      });
    } catch (e, stackTrace) {
      _logger.severe("Excepción al iniciar la carga de pedidos: ", e, stackTrace);
      _setError("Error al iniciar la carga de pedidos: $e");
      _setLoading(false);
    }
  }

  // Cargar detalles del pedido
  Future<void> fetchOrderDetails(String orderId) async {
    if (_userId == null) {
      _setError("El ID de usuario no está disponible.");
      return;
    }

    // Cancelar la suscripción anterior si existe
    _setLoading(true);
    _clearError();
    try {
      _selectedOrder = await _orderRepository.getOrderById(orderId, _userId!);
      _setLoading(false);
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe("Error al cargar detalles del pedido: ", e, stackTrace);
      _setError("Error al cargar detalles del pedido: $e");
      _setLoading(false);
    }
  }

  // Actualizar estado del pedido
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (_userId == null) {
      _setError("El ID de usuario no está disponible.");
      return false;
    }

    // Cancelar la suscripción anterior si existe
    _clearError();
    try {
      await _orderRepository.updateOrderStatus(orderId, newStatus, _userId!);
      return true;
    } catch (e, stackTrace) {
      _logger.severe("Error al actualizar estado del pedido: ", e, stackTrace);
      _setError("Error al actualizar estado del pedido: $e");
      return false;
    }
  }

  // Métodos de gestión de estado
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  // Métodos de gestión de errores
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Métodos de gestión de datos
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Métodos de gestión de selección de pedido
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  // Método de gestión de ciclo de vida
  @override
  void dispose() {
    disposeController();
    super.dispose();
  }
}