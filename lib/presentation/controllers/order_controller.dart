import 'package:flutter/material.dart';
import 'package:emprendedor/data/models/order_model.dart';
import 'package:emprendedor/data/repositories/order_repository.dart';

// Clase para el controlador de pedidos
class OrderController extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();

  // Lista de pedidos
  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  // Pedido seleccionado
  OrderModel? _selectedOrder;
  OrderModel? get selectedOrder => _selectedOrder;

  // Estado de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Mensaje de error
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Constructor
  OrderController() {
    fetchOrders();
  }

  // Getter para el total de ventas
  double get totalVentas {
    return _orders.fold(0.0, (sum, order) => sum + order.totalPrice);
  }

  // Getter para el total de pedidos
  int get totalPedidos {
    return _orders.length;
  }
  int get activeOrders {
    return _orders.where((order) => order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled).length;
  }

  // Getter para el total de pedidos cancelados
  Future<void> fetchOrders() async {
    _setLoading(true);
    _clearError();
    try {
      _orderRepository.getOrders().listen((ordersData) {
        _orders = ordersData;
        _setLoading(false);
        notifyListeners();
      }, onError: (error) {
        _setError("Error al cargar pedidos: $error");
        _setLoading(false);
      });
    } catch (e) {
      _setError("Error al iniciar la carga de pedidos: $e");
      _setLoading(false);
    }
  }

  // Obtener detalles del pedido
  Future<void> fetchOrderDetails(String orderId) async {
    _setLoading(true);
    _clearError();
    try {
      _selectedOrder = await _orderRepository.getOrderById(orderId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError("Error al cargar detalles del pedido: $e");
      _setLoading(false);
    }
  }

  // Actualizar el estado del pedido
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _clearError();
    try {
      await _orderRepository.updateOrderStatus(orderId, newStatus);
      return true;
    } catch (e) {
      _setError("Error al actualizar estado del pedido: $e");
      return false;
    }
  }

  // Eliminar un pedido
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  // Manejo de errores
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Limpiar el mensaje de error
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Limpiar el pedido seleccionado
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }
}