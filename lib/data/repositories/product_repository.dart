import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:emprendedor/core/constants/app_constants.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:logging/logging.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger('ProductRepository');

  // =========================
  // CONSULTAS PARA EMPRENDEDOR
  // =========================

  Stream<List<ProductModel>> getProducts(String userId) {
    try {
      return _firestore
          .collection(AppConstants.productsCollection)
          .where('userId', isEqualTo: userId)
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

  Stream<List<ProductModel>> getProductsByCategory(
      String userId,
      String category,
      ) {
    try {
      if (category.isEmpty || category.toLowerCase() == 'todas') {
        return getProducts(userId);
      }

      return _firestore
          .collection(AppConstants.productsCollection)
          .where('userId', isEqualTo: userId)
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

  Future<List<ProductModel>> getProductsByIds(
      List<String> productIds,
      String userId,
      ) async {
    if (productIds.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('userId', isEqualTo: userId)
          .where(FieldPath.documentId, whereIn: productIds)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      _logger.severe('Error getting products by IDs: $productIds', e, stackTrace);
      rethrow;
    }
  }

  Future<List<String>> getCategories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('userId', isEqualTo: userId)
          .get();

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

  // =========================
  // CONSULTAS PARA CLIENTE
  // =========================

  Stream<List<ProductModel>> getAvailableProductsForClients() {
    try {
      return _firestore
          .collection(AppConstants.productsCollection)
          .where('status', isEqualTo: ProductStatus.available.name)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
      });
    } catch (e, stackTrace) {
      _logger.severe(
        'Error getting available products for clients',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Stream<List<ProductModel>> getAvailableProductsByCategoryForClients(
      String category,
      ) {
    try {
      if (category.isEmpty || category.toLowerCase() == 'todas') {
        return getAvailableProductsForClients();
      }

      return _firestore
          .collection(AppConstants.productsCollection)
          .where('status', isEqualTo: ProductStatus.available.name)
          .where('category', isEqualTo: category)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
      });
    } catch (e, stackTrace) {
      _logger.severe(
        'Error getting available products by category for clients',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<List<String>> getAvailableCategoriesForClients() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('status', isEqualTo: ProductStatus.available.name)
          .get();

      final categories = snapshot.docs
          .map((doc) => (doc.data())['category'] as String?)
          .where((category) => category != null && category.isNotEmpty)
          .map((category) => category!)
          .toSet()
          .toList();

      categories.sort();
      return ['Todas', ...categories];
    } catch (e, stackTrace) {
      _logger.severe(
        'Error fetching available categories for clients',
        e,
        stackTrace,
      );
      return ['Todas'];
    }
  }

  // =========================
  // CRUD DE PRODUCTOS
  // =========================

  Future<void> addProduct(
      ProductModel product,
      File? imageFile,
      String userId,
      ) async {
    try {
      String? imageUrl;

      if (imageFile != null) {
        final fileName =
            'product_images/$userId/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final ref = _storage.ref().child(fileName);
        final snapshot = await ref.putFile(imageFile);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await _firestore.collection(AppConstants.productsCollection).add(
        product.copyWith(
          imageUrl: imageUrl ?? product.imageUrl,
          userId: userId,
        ).toFirestore(),
      );

      _logger.info('Producto "${product.name}" agregado exitosamente.');
    } catch (e, stackTrace) {
      _logger.severe('Error adding product', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateProduct(
      ProductModel product,
      File? imageFile,
      String userId,
      ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .get();

      if (!doc.exists || doc.data()?['userId'] != userId) {
        _logger.warning(
          'Intento de actualizar un producto no autorizado: ${product.id} por el usuario $userId',
        );
        throw Exception('No está autorizado para actualizar este producto.');
      }

      String? imageUrl = product.imageUrl;

      if (imageFile != null) {
        if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
          try {
            await _storage.refFromURL(product.imageUrl!).delete();
          } catch (e) {
            _logger.warning(
              'No se pudo eliminar la imagen antigua de: ${product.id}',
            );
          }
        }

        final fileName =
            'product_images/$userId/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final ref = _storage.ref().child(fileName);
        final uploadTask = ref.putFile(imageFile);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .update(
        product.copyWith(
          imageUrl: imageUrl,
          userId: userId,
        ).toFirestore(),
      );

      _logger.info('Producto "${product.name}" actualizado exitosamente.');
    } catch (e, stackTrace) {
      _logger.severe('Error updating product', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteProduct(
      String productId,
      String? imageUrl,
      String userId,
      ) async {
    try {
      final productDoc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (productDoc.exists && productDoc.data()?['userId'] == userId) {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            _logger.warning(
              'No se pudo eliminar la imagen del producto $productId.',
            );
          }
        }

        await _firestore
            .collection(AppConstants.productsCollection)
            .doc(productId)
            .delete();

        _logger.info('Producto "$productId" eliminado exitosamente.');
      } else {
        _logger.warning(
          'Intento de eliminar un producto no autorizado: $productId por el usuario $userId',
        );
        throw Exception('No está autorizado para eliminar este producto.');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error deleting product', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateFeaturedStatus(
      String productId,
      bool isFeatured,
      String userId,
      ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (doc.exists && doc.data()?['userId'] == userId) {
        await _firestore
            .collection(AppConstants.productsCollection)
            .doc(productId)
            .update({'isFeatured': isFeatured});

        _logger.info(
          'Estado destacado del producto "$productId" actualizado a $isFeatured.',
        );
      } else {
        _logger.warning(
          'Intento de actualizar el estado destacado de un producto no autorizado: $productId por el usuario $userId',
        );
        throw Exception('No está autorizado para actualizar este producto.');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error updating featured status', e, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleProductStatus(
      String productId,
      ProductStatus currentStatus,
      String userId,
      ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (doc.exists && doc.data()?['userId'] == userId) {
        final newStatus = currentStatus == ProductStatus.available
            ? ProductStatus.unavailable
            : ProductStatus.available;

        await _firestore
            .collection(AppConstants.productsCollection)
            .doc(productId)
            .update({'status': newStatus.name});

        _logger.info(
          'Estado del producto "$productId" cambiado a ${newStatus.name}.',
        );
      } else {
        _logger.warning(
          'Intento de cambiar el estado de un producto no autorizado: $productId por el usuario $userId',
        );
        throw Exception('No está autorizado para cambiar el estado de este producto.');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error toggling product status', e, stackTrace);
      rethrow;
    }
  }
}