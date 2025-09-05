import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:emprendedor/data/repositories/product_repository.dart';
import 'package:logging/logging.dart';

// Clase para el controlador de productos
class ProductController extends ChangeNotifier {
  final Logger _logger = Logger('ProductController');
  final ProductRepository _productRepository = ProductRepository();

  // Lista de productos
  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  // Lista de categorías
  List<String> _categories = ['Todas'];
  List<String> get categories => _categories;
  String _selectedCategory = 'Todas';
  String get selectedCategory => _selectedCategory;

  // Estado de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Mensaje de error
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Imagen seleccionada
  File? _selectedImageFile;
  File? get selectedImageFile => _selectedImageFile;

  // Suscripción a los productos
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  // Constructor
  ProductController() {
    fetchProducts();
    fetchCategories();
  }

  // Destructor
  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  // Metodo para obtener el producto más vendido
  ProductModel? get topSellingProduct {
    return _products.isNotEmpty ? _products.first : null;
  }

  // Metodo para obtener el producto más vendido
  Future<void> fetchProducts({String? category}) async {
    _setLoading(true);
    _clearError();
    final categoryToFetch = category ?? _selectedCategory;
    await _productsSubscription?.cancel();
    try {
      final Stream<List<ProductModel>> productStream =
      categoryToFetch == 'Todas' || categoryToFetch.isEmpty
          ? _productRepository.getProducts()
          : _productRepository.getProductsByCategory(categoryToFetch);
      _productsSubscription = productStream.listen((productsData) {
        _products = productsData;
        _setLoading(false);
        notifyListeners();
      }, onError: (error, stackTrace) {
        _logger.severe("Error al cargar productos para la categoría '$categoryToFetch'", error, stackTrace);
        _setError("Error al cargar productos: $error");
        _setLoading(false);
      });
    } catch (e, stackTrace) {
      _logger.severe("Excepción al iniciar la carga de productos para la categoría '$categoryToFetch'", e, stackTrace);
      _setError("Error al cargar productos: $e");
      _setLoading(false);
    }
  }

  // Metodo para obtener las categorías
  Future<void> fetchCategories() async {
    try {
      final categoriesData = await _productRepository.getCategories();
      if (categoriesData.isNotEmpty && !categoriesData.contains('Todas')) {
        _categories = ['Todas', ...categoriesData];
      } else if (categoriesData.isEmpty && _categories.length > 1) {
        _categories = ['Todas'];
      } else {
        _categories = categoriesData.isEmpty ? ['Todas'] : categoriesData;
      }
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe("Error fetching categories in controller", e, stackTrace);
    }
  }

  // Metodo para establecer la categoría seleccionada
  void setSelectedCategory(String category) {
    if (_selectedCategory == category) {
      return;
    }
    _selectedCategory = category;
    notifyListeners();
    fetchProducts(category: category);
  }

  // Metodo para seleccionar una imagen
  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        _selectedImageFile = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _logger.severe("Error al seleccionar imagen", e, stackTrace);
      _setError("Error al seleccionar imagen: $e");
    }
  }

  // Metodo para limpiar la imagen seleccionada
  void clearSelectedImage() {
    _selectedImageFile = null;
    notifyListeners();
  }

  // Metodo para agregar un producto
  Future<bool> addProduct(ProductModel product) async {
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.addProduct(product, _selectedImageFile);
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

  // Metodo para actualizar un producto
  Future<bool> updateProduct(ProductModel product) async {
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.updateProduct(product, _selectedImageFile);
      if (_selectedImageFile != null) {
        clearSelectedImage();
      }
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

  // Metodo para cambiar el estado 'isFeatured' de un producto
  Future<void> toggleFeaturedStatus(String productId, bool newStatus) async {
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.updateFeaturedStatus(productId, newStatus);
      _logger.info("Estado 'isFeatured' del producto '$productId' cambiado a $newStatus.");
    } catch (e, stackTrace) {
      _logger.severe("Error al cambiar estado 'isFeatured' para el producto '$productId'", e, stackTrace);
      _setError("Error al destacar producto: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Metodo para eliminar un producto
  Future<void> deleteProduct(String productId, String? imageUrl) async {
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.deleteProduct(productId, imageUrl);
      _logger.info("Producto con ID '$productId' eliminado.");
      _setLoading(false);
    } catch (e, stackTrace) {
      _logger.severe("Error al eliminar producto", e, stackTrace);
      _setError("Error al eliminar producto: $e");
      _setLoading(false);
    }
  }

  // Metodo para cambiar el estado de un producto
  Future<void> toggleProductStatus(String productId, ProductStatus currentStatus) async {
    _setLoading(true);
    _clearError();
    try {
      await _productRepository.toggleProductStatus(productId, currentStatus);
      _logger.info("Estado del producto '$productId' cambiado.");
    } catch (e, stackTrace) {
      _logger.severe("Error al cambiar estado del producto", e, stackTrace);
      _setError("Error al cambiar estado del producto: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Metodo para obtener un producto
  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  // Metodo para establecer el mensaje de error
  void _setError(String? message) {
    if (_errorMessage == message) {
      return;
    }
    _errorMessage = message;
    notifyListeners();
  }

  // Metodo para limpiar el mensaje de error
  void _clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }
}