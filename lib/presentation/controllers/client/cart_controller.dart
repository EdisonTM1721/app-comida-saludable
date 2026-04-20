import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:emprendedor/data/models/shared/cart_item_model.dart';
import 'package:emprendedor/data/models/shared/order_model.dart';
import 'package:emprendedor/data/models/entrepreneur/product_model.dart';
import 'package:emprendedor/data/models/shared/user_model.dart';
import 'package:emprendedor/data/repositories/shared/order_repository.dart';

class CartController extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};
  final OrderRepository _orderRepository = OrderRepository();

  bool _isProcessingOrder = false;
  bool get isProcessingOrder => _isProcessingOrder;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<CartItemModel> get items => _items.values.toList();

  double get total {
    return _items.values.fold(0, (sum, item) => sum + item.total);
  }

  int get itemCount {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  void addProduct(ProductModel product) {
    if (product.id == null) return;

    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id!] = CartItemModel(
        productId: product.id!,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        productOwnerId: product.userId,
      );
    }

    _clearError();
    notifyListeners();
  }

  void removeProduct(String productId) {
    _items.remove(productId);
    _clearError();
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity++;
      _clearError();
      notifyListeners();
    }
  }

  void decreaseQuantity(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items[productId]!.quantity--;
    } else {
      _items.remove(productId);
    }

    _clearError();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> confirmOrder({
    required String shippingAddress,
    required String paymentMethod,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    double? latitude,
    double? longitude,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _setError('No hay usuario autenticado.');
      return false;
    }

    if (_items.isEmpty) {
      _setError('El carrito está vacío.');
      return false;
    }

    if (shippingAddress.trim().isEmpty) {
      _setError('Debes ingresar una dirección de envío.');
      return false;
    }

    if (paymentMethod.trim().isEmpty) {
      _setError('Debes seleccionar un método de pago.');
      return false;
    }

    _setProcessing(true);
    _setError(null);

    try {
      final firstProduct = _items.values.first;
      final businessUserId = firstProduct.productOwnerId?.trim();

      if (businessUserId == null || businessUserId.isEmpty) {
        throw Exception('No se pudo determinar el emprendedor del pedido.');
      }

      final hasMixedBusinesses = _items.values.any(
            (item) => (item.productOwnerId?.trim() ?? '') != businessUserId,
      );

      if (hasMixedBusinesses) {
        throw Exception(
          'Solo puedes confirmar productos de un mismo emprendedor por pedido.',
        );
      }

      final orderItems = _items.values.map((item) {
        return OrderItem(
          productId: item.productId,
          productName: item.name,
          quantity: item.quantity,
          priceAtPurchase: item.price,
          imageUrl: item.imageUrl,
        );
      }).toList();

      final order = OrderModel(
        userId: user.uid,
        businessUserId: businessUserId,
        items: orderItems,
        totalPrice: total,
        status: OrderStatus.pending,
        shippingAddress: shippingAddress.trim(),
        paymentMethod: paymentMethod.trim(),
        latitude: latitude,
        longitude: longitude,
        customerInfo: UserModel(
          id: user.uid,
          name: customerName.trim().isEmpty ? 'Cliente' : customerName.trim(),
          email: customerEmail.trim().isEmpty
              ? 'sin-correo@local.app'
              : customerEmail.trim(),
          phoneNumber: customerPhone?.trim().isEmpty == true
              ? null
              : customerPhone?.trim(),
        ),
        createdAt: Timestamp.now(),
      );

      await _orderRepository.addOrder(order);

      clearCart();
      _setProcessing(false);
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        'FirebaseException confirmOrder: code=${e.code}, message=${e.message}',
      );

      _setError(
        e.message?.trim().isNotEmpty == true
            ? e.message!
            : 'Ocurrió un error con Firestore (${e.code}).',
      );
      _setProcessing(false);
      return false;
    } catch (e, stackTrace) {
      debugPrint('Error confirmOrder: $e');
      debugPrintStack(stackTrace: stackTrace);

      _setError(
        e.toString().replaceFirst('Exception: ', ''),
      );
      _setProcessing(false);
      return false;
    }
  }

  void _setProcessing(bool value) {
    if (_isProcessingOrder == value) return;
    _isProcessingOrder = value;
    notifyListeners();
  }

  void _setError(String? value) {
    if (_errorMessage == value) return;
    _errorMessage = value;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
  }
}