// Archivo: data/repositories/social_media_repository.dart (CORREGIDO)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/models/social_media_model.dart';

final Logger _logger = Logger('SocialMediaRepository');

class SocialMediaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐ CORRECCIÓN: Usar una función para la ruta de la colección
  CollectionReference<Map<String, dynamic>> _getCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('social_media');
  }

  Future<void> addSocialMedia(String userId, SocialMediaModel socialMedia) async {
    try {
      await _getCollection(userId).add(socialMedia.toFirestore());
    } catch (e, stackTrace) {
      _logger.severe('Error al añadir red social: $e', e, stackTrace);
      rethrow;
    }
  }

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

  Future<void> deleteSocialMedia(String userId, String docId) async {
    try {
      await _getCollection(userId).doc(docId).delete();
    } catch (e, stackTrace) {
      _logger.severe('Error al eliminar red social: $e', e, stackTrace);
      rethrow;
    }
  }

  Stream<List<SocialMediaModel>> getSocialMediaLinks(String userId) {
    try {
      // ⭐ CORRECCIÓN: Usar _getCollection(userId)
      return _getCollection(userId).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => SocialMediaModel.fromFirestore(doc)).toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error al obtener redes sociales: $e', e, stackTrace);
      rethrow;
    }
  }
}