import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/models/entrepreneur/social_media_model.dart';

final Logger _logger = Logger('SocialMediaRepository');

// Clase para el repositorio de redes sociales
class SocialMediaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Usar una función para la ruta de la colección
  CollectionReference<Map<String, dynamic>> _getCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('social_media');
  }

  // Agregar una nueva red social
  Future<void> addSocialMedia(String userId, SocialMediaModel socialMedia) async {
    try {
      await _getCollection(userId).add(socialMedia.toFirestore());
    } catch (e, stackTrace) {
      _logger.severe('Error al añadir red social: $e', e, stackTrace);
      rethrow;
    }
  }

  // Actualizar una red social
  Future<void> updateSocialMedia(String userId, SocialMediaModel socialMedia) async {
    if (socialMedia.id == null) {
      throw Exception('ID del documento es nulo para actualizar.');
    }
    try {
      await _getCollection(userId).doc(socialMedia.id).update(socialMedia.toFirestore());
    } catch (e, stackTrace) {
      _logger.severe('Error al actualizar red social: $e', e, stackTrace);
      rethrow;
    }
  }

  // Eliminar una red social
  Future<void> deleteSocialMedia(String userId, String docId) async {
    try {
      await _getCollection(userId).doc(docId).delete();
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar red social: $e', e, stackTrace);
      rethrow;
    }
  }

  // Obtener todas las redes sociales
  Stream<List<SocialMediaModel>> getSocialMediaLinks(String userId) {
    try {
      // Usar _getCollection(userId)
      return _getCollection(userId).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => SocialMediaModel.fromFirestore(doc)).toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener redes sociales: $e', e, stackTrace);
      rethrow;
    }
  }
}