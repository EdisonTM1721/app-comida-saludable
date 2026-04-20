import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/client/client_profile_model.dart';

class ClientProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'clients';

  Future<void> createClientProfile(ClientProfileModel profile) async {
    await _firestore
        .collection(_collection)
        .doc(profile.userId)
        .set(profile.toMap());
  }

  Future<ClientProfileModel?> getClientProfile(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();

    if (!doc.exists || doc.data() == null) return null;

    return ClientProfileModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateClientProfile(ClientProfileModel profile) async {
    await _firestore
        .collection(_collection)
        .doc(profile.userId)
        .update(profile.toMap());
  }

  Future<void> saveClientProfile(ClientProfileModel profile) async {
    await _firestore
        .collection(_collection)
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }
}