import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/business_profile_model.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger('BusinessProfileRepository');

class BusinessProfileRepository {
  final _firestore = FirebaseFirestore.instance;

  late final CollectionReference<Map<String, dynamic>> _businessProfilesCollection;

  BusinessProfileRepository() {
    _businessProfilesCollection = _firestore.collection('business_profiles');
  }

  // Ahora obtenemos el documento directamente por su ID, que es el UID del usuario.
  Future<BusinessProfileModel?> getBusinessProfile(String userId) async {
    logger.info('BusinessProfileRepository: Buscando perfil para el usuario ID: $userId');
    try {
      final docSnapshot = await _businessProfilesCollection.doc(userId).get();

      if (docSnapshot.exists) {
        final profile = BusinessProfileModel.fromFirestore(docSnapshot);
        logger.info('BusinessProfileRepository: Perfil encontrado para userId: $userId');
        return profile;
      } else {
        logger.info('BusinessProfileRepository: No se encontró perfil para userId: $userId');
        return null;
      }
    } catch (e, stackTrace) {
      logger.severe('BusinessProfileRepository: Error obteniendo perfil para userId: $userId', e, stackTrace);
      return null;
    }
  }

  // --- CORRECCIÓN CRÍTICA ---
  // El método ahora devuelve el modelo de perfil con el ID asignado.
  Future<BusinessProfileModel> createBusinessProfile(BusinessProfileModel profile) async {
    if (profile.userId == null || profile.userId!.isEmpty) {
      logger.severe('createBusinessProfile: Se intentó crear perfil sin userId.');
      throw Exception("User ID is required in the profile model to create a profile.");
    }
    try {
      logger.info('createBusinessProfile: Creando perfil para userId: ${profile.userId}');
      // Usamos .doc(userId).set() para asegurar que el ID del documento sea el UID del usuario.
      await _businessProfilesCollection.doc(profile.userId).set(profile.toFirestore());
      logger.info('createBusinessProfile: Perfil creado exitosamente para userId: ${profile.userId}');
      // Retornamos el perfil con el ID de documento de Firestore para que el controlador lo use.
      return profile.copyWith(id: profile.userId);
    } catch (e, stackTrace) {
      logger.severe('createBusinessProfile: Error creando perfil para userId: ${profile.userId}', e, stackTrace);
      rethrow;
    }
  }

  // Metodo para actualizar un perfil de negocio existente
  Future<void> updateBusinessProfile(BusinessProfileModel profile) async {
    if (profile.userId == null || profile.userId!.isEmpty) {
      logger.severe('updateBusinessProfile: Se intentó actualizar perfil sin userId en el modelo.');
      throw Exception("User ID is required in the profile model for update consistency.");
    }
    try {
      logger.info('updateBusinessProfile: Actualizando perfil para userId: ${profile.userId}');
      // Usamos .doc(userId) para actualizar el documento correcto.
      await _businessProfilesCollection.doc(profile.userId).update(profile.toFirestore());
    } catch (e, stackTrace) {
      logger.severe('updateBusinessProfile: Error actualizando perfil para userId: ${profile.userId}', e, stackTrace);
      rethrow;
    }
  }

  // Metodo para eliminar un perfil de negocio
  Future<void> deleteBusinessProfile(String userId) async {
    if (userId.isEmpty) {
      logger.warning('deleteBusinessProfile: Se intentó eliminar perfil con ID de usuario vacío.');
      return;
    }
    try {
      logger.info('deleteBusinessProfile: Eliminando perfil para userId: $userId');
      // Usamos .doc(userId) para eliminar el documento correcto.
      await _businessProfilesCollection.doc(userId).delete();
    } catch (e, stackTrace) {
      logger.severe('deleteBusinessProfile: Error eliminando perfil para userId: $userId', e, stackTrace);
      rethrow;
    }
  }
}