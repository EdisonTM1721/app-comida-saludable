import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/nutritionist_profile_model.dart';

class NutritionistProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'nutritionists';

  Future<void> createNutritionistProfile(
      NutritionistProfileModel profile,
      ) async {
    await _firestore
        .collection(_collection)
        .doc(profile.userId)
        .set(profile.toMap());
  }

  Future<NutritionistProfileModel?> getNutritionistProfile(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();

    if (!doc.exists || doc.data() == null) return null;

    return NutritionistProfileModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateNutritionistProfile(
      NutritionistProfileModel profile,
      ) async {
    await _firestore
        .collection(_collection)
        .doc(profile.userId)
        .update(profile.toMap());
  }

  Future<void> saveNutritionistProfile(
      NutritionistProfileModel profile,
      ) async {
    await _firestore
        .collection(_collection)
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }
}