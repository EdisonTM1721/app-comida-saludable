import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo de datos para representar el perfil de un negocio/emprendedor
class BusinessProfileModel {
  String? id;
  String? userId;
  String name;
  String? profileImageUrl;
  String? description;
  String? address;
  String? openingHours;
  String? paymentMethods;
  Map<String, String> socialMediaLinks;

  // Constructor
  BusinessProfileModel({
    this.id,
    this.userId,
    this.name = '',
    this.profileImageUrl,
    this.description,
    this.address,
    this.openingHours,
    this.paymentMethods,
    this.socialMediaLinks = const {},
  });

  // Método para convertir el modelo en un mapa de Firestore
  factory BusinessProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return BusinessProfileModel(
      id: doc.id,
      userId: data?['userId'] as String?,
      name: data?['name'] as String? ?? '',
      profileImageUrl: data?['profileImageUrl'] as String?,
      description: data?['description'] as String?,
      address: data?['address'] as String?,
      openingHours: data?['openingHours'] as String?,
      paymentMethods: data?['paymentMethods'] as String?,
      socialMediaLinks: Map<String, String>.from(data?['socialMediaLinks'] as Map? ?? {}),
    );
  }

  // Método para convertir el modelo en un mapa de Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) 'userId': userId,
      'name': name,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (description != null) 'description': description,
      if (address != null) 'address': address,
      if (openingHours != null) 'openingHours': openingHours,
      if (paymentMethods != null) 'paymentMethods': paymentMethods,
      'socialMediaLinks': socialMediaLinks,
    };
  }
  // Metodo para clonar el modelo
  BusinessProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? profileImageUrl,
    String? description,
    String? address,
    String? openingHours,
    String? paymentMethods,
    Map<String, String>? socialMediaLinks,
  }) {

    // Se usa un operador de fusión nula para cada campo
    return BusinessProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      description: description ?? this.description,
      address: address ?? this.address,
      openingHours: openingHours ?? this.openingHours,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
    );
  }
}