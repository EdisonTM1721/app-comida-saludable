import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

// Nueva clase para el servicio de Firebase
class FirebaseService {
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  // Puedes añadir métodos de inicialización si es necesario
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }
}