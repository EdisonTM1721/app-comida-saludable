import 'package:cloud_firestore/cloud_firestore.dart';

// Clase para representar un modelo de redes sociales
class SocialMediaModel {
  final String? id;
  final String name;
  final String url;
  final String? userId;

  // Constructor de la clase
  SocialMediaModel({
    this.id,
    required this.name,
    required this.url,
    this.userId,
  });

  // Factory constructor para crear una instancia desde un mapa
  factory SocialMediaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialMediaModel(
      id: doc.id,
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      userId: doc.reference.parent.parent?.id,
    );
  }

  // Metodo para convertir la instancia en un mapa
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'url': url,

    };
  }

  // Metodo para clonar el modelo
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
      userId: userId ?? this.userId,
    );
  }
}