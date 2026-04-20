import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus { available, unavailable }

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
  final String? userId;

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
    this.userId,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ProductModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl']?.toString(),
      status: (data['status'] as String? ?? 'unavailable') == 'available'
          ? ProductStatus.available
          : ProductStatus.unavailable,
      category: data['category']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      ingredients: List<String>.from(data['ingredients'] as List? ?? []),
      isFeatured: data['isFeatured'] as bool? ?? false,
      approxCalories: (data['approxCalories'] as num?)?.toDouble(),
      userId: data['userId']?.toString(),
    );
  }

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
      'userId': userId,
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
    String? userId,
  }) {
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
      userId: userId ?? this.userId,
    );
  }
}