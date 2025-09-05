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

  Future<BusinessProfileModel?> getBusinessProfile(String userId) async {

    logger.info('BusinessProfileRepository: Buscando perfil para el usuario ID: $userId');
    try {

      final querySnapshot = await _businessProfilesCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;

        final profile = BusinessProfileModel.fromFirestore(doc);

        logger.info('BusinessProfileRepository: Perfil encontrado con ID de documento: ${doc.id} para userId: $userId');
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

  // Metodo para crear un nuevo perfil de negocio
  Future<BusinessProfileModel?> createBusinessProfile(BusinessProfileModel profile) async {

    if (profile.userId == null || profile.userId!.isEmpty) {
      logger.severe('createBusinessProfile: Se intentó crear perfil sin userId.');
      throw Exception("User ID is required in the profile model to create a profile.");
    }
    try {
      logger.info('createBusinessProfile: Creando perfil para userId: ${profile.userId}');
      final docRef = await _businessProfilesCollection.add(profile.toFirestore());

      // Devolver el perfil con el ID asignado por Firestore
      return profile.copyWith(id: docRef.id);
    } catch (e, stackTrace) {
      logger.severe('createBusinessProfile: Error creando perfil para userId: ${profile.userId}', e, stackTrace);
      rethrow;
    }
  }

  // Metodo para actualizar un perfil de negocio existente
  Future<void> updateBusinessProfile(BusinessProfileModel profile) async {
    if (profile.id == null || profile.id!.isEmpty) {
      logger.severe('updateBusinessProfile: Se intentó actualizar perfil sin ID de documento.');
      throw Exception("Profile document ID is required for update.");
    }
    // 'profile.userId' también debería estar presente y ser correcto.
    if (profile.userId == null || profile.userId!.isEmpty) {
      logger.severe('updateBusinessProfile: Se intentó actualizar perfil (docId: ${profile.id}) sin userId en el modelo.');
      throw Exception("User ID is required in the profile model for update consistency.");
    }
    try {
      logger.info('updateBusinessProfile: Actualizando perfil con ID de documento: ${profile.id} para userId: ${profile.userId}');
      await _businessProfilesCollection.doc(profile.id).update(profile.toFirestore());
    } catch (e, stackTrace) {
      logger.severe('updateBusinessProfile: Error actualizando perfil (docId: ${profile.id})', e, stackTrace);
      rethrow;
    }
  }

  // Metodo para eliminar un perfil de negocio (no se usa en ProfileController pero está aquí)
  Future<void> deleteBusinessProfile(String profileDocId) async {
    if (profileDocId.isEmpty) {
      logger.warning('deleteBusinessProfile: Se intentó eliminar perfil con ID de documento vacío.');
      return;
    }
    try {
      logger.info('deleteBusinessProfile: Eliminando perfil con ID de documento: $profileDocId');
      await _businessProfilesCollection.doc(profileDocId).delete();
    } catch (e, stackTrace) {
      logger.severe('deleteBusinessProfile: Error eliminando perfil (docId: $profileDocId)', e, stackTrace);
      rethrow;
    }
  }
}
