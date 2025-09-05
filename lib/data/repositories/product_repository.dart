import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:emprendedor/core/constants/app_constants.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:logging/logging.dart';

// Clase para el repositorio de productos
class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger('ProductRepository');

  // Obtener todos los productos
  Stream<List<ProductModel>> getProducts() {
    try {
      return _firestore
          .collection(AppConstants.productsCollection)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error getting products stream', e, stackTrace);
      rethrow;
    }
  }

  // Obtener un producto por su ID
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    try {
      if (category.isEmpty || category.toLowerCase() == 'todas') {
        return getProducts();
      }
      return _firestore
          .collection(AppConstants.productsCollection)
          .where('category', isEqualTo: category)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error getting products by category', e, stackTrace);
      rethrow;
    }
  }

  // Agregar un nuevo producto
  Future<void> addProduct(ProductModel product, File? imageFile) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        final fileName = 'product_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final ref = _storage.ref().child(fileName);
        final snapshot = await ref.putFile(imageFile);
        imageUrl = await snapshot.ref.getDownloadURL();
      }
      await _firestore
          .collection(AppConstants.productsCollection)
          .add(product.copyWith(imageUrl: imageUrl).toFirestore());
      _logger.info('Producto "${product.name}" agregado exitosamente.');
    } catch (e, stackTrace) {
      _logger.severe('Error adding product', e, stackTrace);
      rethrow;
    }
  }

  // Actualizar un producto
  Future<void> updateProduct(ProductModel product, File? imageFile) async {
    try {
      String? imageUrl = product.imageUrl;
      if (imageFile != null) {
        if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
          try {
            await _storage.refFromURL(product.imageUrl!).delete();
          } catch (e) {
            _logger.warning("No se pudo eliminar la imagen antigua de: ${product.id}");
          }
        }
        final fileName = 'product_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final ref = _storage.ref().child(fileName);
        final uploadTask = ref.putFile(imageFile);
        final snapshot = await uploadTask.whenComplete(() => {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .update(product.copyWith(imageUrl: imageUrl).toFirestore());
      _logger.info('Producto "${product.name}" actualizado exitosamente.');
    } catch (e, stackTrace) {
      _logger.severe('Error updating product', e, stackTrace);
      rethrow;
    }
  }

  // Eliminar un producto
  Future<void> deleteProduct(String productId, String? imageUrl) async {
    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          _logger.warning("No se pudo eliminar la imagen del producto $productId.");
        }
      }
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .delete();
      _logger.info('Producto "$productId" eliminado exitosamente.');
    } catch (e, stackTrace) {
      _logger.severe('Error deleting product', e, stackTrace);
      rethrow;
    }
  }

  // Actualizar el estado de un producto
  Future<void> updateFeaturedStatus(String productId, bool isFeatured) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({'isFeatured': isFeatured});
      _logger.info('Estado destacado del producto "$productId" actualizado a $isFeatured.');
    } catch (e, stackTrace) {
      _logger.severe('Error updating featured status', e, stackTrace);
      rethrow;
    }
  }

  // Actualizar el estado de un producto
  Future<void> toggleProductStatus(String productId, ProductStatus currentStatus) async {
    try {
      final newStatus = currentStatus == ProductStatus.available
          ? ProductStatus.unavailable
          : ProductStatus.available;
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({'status': newStatus.name});
      _logger.info('Estado del producto "$productId" cambiado a ${newStatus.name}.');
    } catch (e, stackTrace) {
      _logger.severe('Error toggling product status', e, stackTrace);
      rethrow;
    }
  }

  // Actualizar el stock de un producto
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.productsCollection).get();
      final categories = snapshot.docs
          .map((doc) => (doc.data())['category'] as String?)
          .where((category) => category != null && category.isNotEmpty)
          .map((category) => category!)
          .toSet()
          .toList();
      categories.sort();
      _logger.info('Categorías obtenidas: ${categories.length} categorías.');
      return ['Todas', ...categories];
    } catch (e, stackTrace) {
      _logger.severe('Error fetching categories', e, stackTrace);
      return ['Todas'];
    }
  }
}