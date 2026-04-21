import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/client/appointment_model.dart';

class AppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'appointments';

  Future<void> createAppointment(AppointmentModel appointment) async {
    await _firestore.collection(_collection).add(appointment.toFirestore());
  }

  Stream<List<AppointmentModel>> getAppointmentsForClient(String clientUserId) {
    return _firestore
        .collection(_collection)
        .where('clientUserId', isEqualTo: clientUserId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList(),
    );
  }

  Future<int> countAppointmentsForClient(String clientUserId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('clientUserId', isEqualTo: clientUserId)
        .get();

    return snapshot.docs.length;
  }
}