import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:emprendedor/data/repositories/product_repository.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Clase para controlar los productos
class ProductController extends ChangeNotifier {
  final Logger _logger = Logger('ProductController');
  final ProductRepository _productRepository = ProductRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Propiedades privadas
  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  // Propiedades públicas
  final List<String> _categories = [
    'Todas',
    'Bebidas',
    'Ensaladas',
    'Sopas',
    'Postres',
    'Platos fuertes',
  ];
  List<String> get categories => _categories;

  // Propiedades públicas
  String _selectedCategory = 'Todas';
  String get selectedCategory => _selectedCategory;

  // Propiedades públicas
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Propiedades públicas
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Propiedades públicas
  File? _selectedImageFile;
  File? get selectedImageFile => _selectedImageFile;

  // Propiedades públicas
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  // Propiedades públicas
  String? _userId;
  String? get userId => _userId;

  // Constructor
  ProductController();

  // Métodos públicos
  void setSelectedImage(File? file) {
    _selectedImageFile = file;
    notifyListeners();
  }

  // Métodos privados
  // CORRECCIÓN: Aceptar un String? para manejar el caso de logout
  Future<void> setUserId(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    if (_userId != null) {
      await fetchProducts();
    } else {
      // Limpia los productos y cancela la suscripción cuando no hay usuario
      _products = [];
      _productsSubscription?.cancel();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Método de gestión de ciclo de vida
  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  // Métodos privados
  Future<void> fetchProducts({String? category}) async {
    if (_userId == null) {
      _setError("Usuario no autenticado. No se pueden cargar productos.");
      _products = []; // Limpia la lista de productos
      _setLoading(false);
      return;
    }

    _setLoading(true);
    _clearError();
    final categoryToFetch = category ?? _selectedCategory;
    await _productsSubscription?.cancel();
    try {
      final Stream<List<ProductModel>> productStream =
      categoryToFetch == 'Todas' || categoryToFetch.isEmpty
          ? _productRepository.getProducts(_userId!)
          : _productRepository.getProductsByCategory(_userId!, categoryToFetch);

      _productsSubscription = productStream.listen((productsData) {
        _products = productsData;
        _setLoading(false);
        notifyListeners();
      }, onError: (error, stackTrace) {
        _logger.severe(
            "Error al cargar productos para la categoría '$categoryToFetch'",
            error,
            stackTrace);
        _setError("Error al cargar productos: $error");
        _setLoading(false);
      });
    } catch (e, stackTrace) {
      _logger.severe(
          "Excepción al iniciar la carga de productos para la categoría '$categoryToFetch'",
          e,
          stackTrace);
      _setError("Error al cargar productos: $e");
      _setLoading(false);
    }
  }

  // Métodos públicos
  void setSelectedCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    fetchProducts(category: category);
  }

  // Métodos públicos
  void clearSelectedImage() {
    _selectedImageFile = null;
    notifyListeners();
  }

  // Métodos públicos
  Future<bool> addProduct(ProductModel product) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.addProduct(product, _selectedImageFile, _userId!);
      clearSelectedImage();
      _logger.info("Producto '${product.name}' agregado.");
      _setLoading(false);
      return true;
    } catch (e, stackTrace) {
      _logger.severe("Error al agregar producto", e, stackTrace);
      _setError("Error al agregar producto: $e");
      _setLoading(false);
      return false;
    }
  }

  // Métodos públicos
  Future<bool> updateProduct(ProductModel product) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.updateProduct(product, _selectedImageFile, _userId!);
      if (_selectedImageFile != null) clearSelectedImage();
      _logger.info("Producto '${product.id} - ${product.name}' actualizado.");
      _setLoading(false);
      return true;
    } catch (e, stackTrace) {
      _logger.severe("Error al actualizar producto '${product.id} - ${product.name}'", e, stackTrace);
      _setError("Error al actualizar producto: $e");
      _setLoading(false);
      return false;
    }
  }

  // Métodos públicos
  Future<void> toggleFeaturedStatus(String productId, bool newStatus) async {
    if (_userId == null) return;
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.updateFeaturedStatus(productId, newStatus, _userId!);
      _logger.info("Estado 'isFeatured' del producto '$productId' cambiado a $newStatus.");
    } catch (e, stackTrace) {
      _logger.severe("Error al cambiar estado 'isFeatured' para el producto '$productId'", e, stackTrace);
      _setError("Error al destacar producto: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Métodos públicos
  Future<void> deleteProduct(String productId, String? imageUrl) async {
    if (_userId == null) return;
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.deleteProduct(productId, imageUrl, _userId!);
      _logger.info("Producto con ID '$productId' eliminado.");
      _setLoading(false);
    } catch (e, stackTrace) {
      _logger.severe("Error al eliminar producto", e, stackTrace);
      _setError("Error al eliminar producto: $e");
      _setLoading(false);
    }
  }

  // Métodos públicos
  Future<void> toggleProductStatus(String productId, ProductStatus currentStatus) async {
    if (_userId == null) return;
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.toggleProductStatus(productId, currentStatus, _userId!);
      _logger.info("Estado del producto '$productId' cambiado.");
    } catch (e, stackTrace) {
      _logger.severe("Error al cambiar estado del producto", e, stackTrace);
      _setError("Error al cambiar estado del producto: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Métodos públicos
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  // Métodos públicos
  void _setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    notifyListeners();
  }

  // Métodos públicos
  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}