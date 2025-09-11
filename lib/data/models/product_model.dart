import 'package:cloud_firestore/cloud_firestore.dart';

// Definición de la enumeración ProductStatus
enum ProductStatus { available, unavailable }

// Extensión para la enumeración ProductStatus
extension ProductStatusExtension on ProductStatus {
  String get displayName {
    switch (this) {
      case ProductStatus.available:
        return 'Disponible';
      case ProductStatus.unavailable:
        return 'No Disponible';
    }
  }
}

// Definición de la clase ProductModel
class ProductModel {
  final String? id;
  final String name;
  final double price;
  final String? imageUrl;
  final ProductStatus status;
  final String category;
  final String description;
  final List<String> ingredients;
  final bool isFeatured;
  final double? approxCalories;
  final String? userId; // Agregado el campo userId al modelo

  // Constructor de la clase
  ProductModel({
    this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.status,
    required this.category,
    required this.description,
    required this.ingredients,
    this.isFeatured = false,
    this.approxCalories,
    this.userId, // El campo userId es opcional en el constructor
  });

  // Factory constructor para crear una instancia desde un mapa
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num? ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] as String?,
      status: (data['status'] as String? ?? 'unavailable') == 'available'
          ? ProductStatus.available
          : ProductStatus.unavailable,
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ingredients: List<String>.from(data['ingredients'] as List? ?? []),
      isFeatured: data['isFeatured'] as bool? ?? false,
      approxCalories: (data['approxCalories'] as num?)?.toDouble(),
      userId: data['userId'] as String?, // Obtener el userId del documento
    );
  }

  // Metodo para convertir la instancia en un mapa
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'status': status.name,
      'category': category,
      'description': description,
      'ingredients': ingredients,
      'isFeatured': isFeatured,
      'userId': userId, // Guardar el userId en el mapa
      if (approxCalories != null) 'approxCalories': approxCalories,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    ProductStatus? status,
    String? category,
    String? description,
    List<String>? ingredients,
    bool? isFeatured,
    double? approxCalories,
    String? userId, // Agregado el parámetro userId para la copia
  }) {
    // Si no se proporciona un id, usar el id actual
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      category: category ?? this.category,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      isFeatured: isFeatured ?? this.isFeatured,
      approxCalories: approxCalories ?? this.approxCalories,
      userId: userId ?? this.userId, // Copiar el userId o usar el nuevo
    );
  }
}
