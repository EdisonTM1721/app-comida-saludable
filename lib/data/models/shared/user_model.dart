import 'package:cloud_firestore/cloud_firestore.dart';

// Clase para representar un modelo de usuario
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;

  // Constructor de la clase
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
  });

  // Factory constructor para crear una instancia desde un mapa
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
    );
  }

  // Metodo para convertir la instancia en un mapa
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
  // Metodo para convertir la instancia en un mapa para la base de datos
  Map<String, dynamic> toEmbeddedData() {
    return {
      'userId': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }

  // Factory constructor para crear una instancia desde un mapa embebido
  factory UserModel.fromEmbeddedData(Map<String, dynamic> data) {
    return UserModel(
      id: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
    );
  }
}