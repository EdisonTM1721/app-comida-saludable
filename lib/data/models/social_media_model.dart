// Archivo: domain/models/social_media_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SocialMediaModel {
  final String? id;
  final String name;
  final String url;
  final String? userId; // ⭐ Campo userId añadido

  SocialMediaModel({
    this.id,
    required this.name,
    required this.url,
    this.userId, // ⭐ Lo hacemos opcional
  });

  factory SocialMediaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialMediaModel(
      id: doc.id,
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      userId: doc.reference.parent.parent?.id, // ⭐ Extraer el userId
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'url': url,
      // No incluimos el 'userId' aquí porque se usa en la ruta de Firestore
    };
  }

  SocialMediaModel copyWith({
    String? id,
    String? name,
    String? url,
    String? userId,
  }) {
    return SocialMediaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      userId: userId ?? this.userId, // ⭐ Campo userId en copyWith
    );
  }
}