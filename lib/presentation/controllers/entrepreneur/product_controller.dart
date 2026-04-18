import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:emprendedor/data/repositories/product_repository.dart';

class ProductController extends ChangeNotifier {
  final Logger _logger = Logger('ProductController');
  final ProductRepository _productRepository = ProductRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  final List<String> _categories = [
    'Todas',
    'Bebidas',
    'Ensaladas',
    'Sopas',
    'Postres',
    'Platos fuertes',
  ];
  List<String> get categories => _categories;

  String _selectedCategory = 'Todas';
  String get selectedCategory => _selectedCategory;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  File? _selectedImageFile;
  File? get selectedImageFile => _selectedImageFile;

  StreamSubscription<List<ProductModel>>? _productsSubscription;

  String? _userId;
  String? get userId => _userId;

  ProductController();

  Future<void> initUser() async {
    final user = _auth.currentUser;
    await setUserId(user?.uid);
  }

  Future<void> setUserId(String? userId) async {
    if (_userId == userId) return;

    _userId = userId;

    if (_userId != null) {
      await fetchProducts();
    } else {
      _productsSubscription?.cancel();
      _products = [];
      _selectedImageFile = null;
      _setError(null);
      _setLoading(false);
      notifyListeners();
    }
  }

  void setSelectedImage(File? file) {
    _selectedImageFile = file;
    notifyListeners();
  }

  void clearSelectedImage() {
    if (_selectedImageFile == null) return;
    _selectedImageFile = null;
    notifyListeners();
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setSelectedImage(File(pickedFile.path));
      }
    } catch (e, stackTrace) {
      _logger.severe('Error al seleccionar imagen', e, stackTrace);
      _setError('No se pudo seleccionar la imagen.');
    }
  }

  Future<void> fetchProducts({String? category}) async {
    if (_userId == null) {
      _products = [];
      _setError('Usuario no autenticado. No se pueden cargar productos.');
      _setLoading(false);
      return;
    }

    _setLoading(true);
    _setError(null);

    final categoryToFetch = category ?? _selectedCategory;

    await _productsSubscription?.cancel();

    try {
      final Stream<List<ProductModel>> productStream =
      categoryToFetch == 'Todas' || categoryToFetch.isEmpty
          ? _productRepository.getProducts(_userId!)
          : _productRepository.getProductsByCategory(
        _userId!,
        categoryToFetch,
      );

      _productsSubscription = productStream.listen(
            (productsData) {
          _products = productsData;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error, stackTrace) {
          _logger.severe(
            "Error al cargar productos para la categoría '$categoryToFetch'",
            error,
            stackTrace,
          );
          _setError('Error al cargar productos: $error');
          _setLoading(false);
        },
      );
    } catch (e, stackTrace) {
      _logger.severe(
        "Excepción al iniciar la carga de productos para la categoría '$categoryToFetch'",
        e,
        stackTrace,
      );
      _setError('Error al cargar productos: $e');
      _setLoading(false);
    }
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    notifyListeners();
    fetchProducts(category: category);
  }

  Future<bool> addProduct(ProductModel product) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _productRepository.addProduct(
        product,
        _selectedImageFile,
        _userId!,
      );

      clearSelectedImage();
      _logger.info("Producto '${product.name}' agregado.");
      _setLoading(false);
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error al agregar producto', e, stackTrace);
      _setError('Error al agregar producto: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    if (_userId == null) {
      _setError('Usuario no autenticado.');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _productRepository.updateProduct(
        product,
        _selectedImageFile,
        _userId!,
      );

      if (_selectedImageFile != null) {
        clearSelectedImage();
      }

      _logger.info("Producto '${product.id} - ${product.name}' actualizado.");
      _setLoading(false);
      return true;
    } catch (e, stackTrace) {
      _logger.severe(
        "Error al actualizar producto '${product.id} - ${product.name}'",
        e,
        stackTrace,
      );
      _setError('Error al actualizar producto: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> toggleFeaturedStatus(String productId, bool newStatus) async {
    if (_userId == null) return;

    _setLoading(true);
    _setError(null);

    try {
      await _productRepository.updateFeaturedStatus(
        productId,
        newStatus,
        _userId!,
      );
      _logger.info(
        "Estado 'isFeatured' del producto '$productId' cambiado a $newStatus.",
      );
    } catch (e, stackTrace) {
      _logger.severe(
        "Error al cambiar estado 'isFeatured' para el producto '$productId'",
        e,
        stackTrace,
      );
      _setError('Error al destacar producto: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(String productId, String? imageUrl) async {
    if (_userId == null) return;

    _setLoading(true);
    _setError(null);

    try {
      await _productRepository.deleteProduct(productId, imageUrl, _userId!);
      _logger.info("Producto con ID '$productId' eliminado.");
      _setLoading(false);
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar producto', e, stackTrace);
      _setError('Error al eliminar producto: $e');
      _setLoading(false);
    }
  }

  Future<void> toggleProductStatus(
      String productId,
      ProductStatus currentStatus,
      ) async {
    if (_userId == null) return;

    _setLoading(true);
    _setError(null);

    try {
      await _productRepository.toggleProductStatus(
        productId,
        currentStatus,
        _userId!,
      );
      _logger.info("Estado del producto '$productId' cambiado.");
    } catch (e, stackTrace) {
      _logger.severe('Error al cambiar estado del producto', e, stackTrace);
      _setError('Error al cambiar estado del producto: $e');
    } finally {
      _setLoading(false);
    }
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

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }
}