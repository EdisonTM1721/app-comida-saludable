import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

String appointmentStatusToString(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return 'pending';
    case AppointmentStatus.confirmed:
      return 'confirmed';
    case AppointmentStatus.completed:
      return 'completed';
    case AppointmentStatus.cancelled:
      return 'cancelled';
  }
}

AppointmentStatus stringToAppointmentStatus(String? value) {
  switch (value) {
    case 'confirmed':
      return AppointmentStatus.confirmed;
    case 'completed':
      return AppointmentStatus.completed;
    case 'cancelled':
      return AppointmentStatus.cancelled;
    case 'pending':
    default:
      return AppointmentStatus.pending;
  }
}

class AppointmentModel {
  final String? id;
  final String clientUserId;
  final String clientName;
  final String nutritionistUserId;
  final String nutritionistName;
  final Timestamp appointmentDate;
  final String consultationMode;
  final String? notes;
  final AppointmentStatus status;
  final Timestamp createdAt;

  AppointmentModel({
    this.id,
    required this.clientUserId,
    required this.clientName,
    required this.nutritionistUserId,
    required this.nutritionistName,
    required this.appointmentDate,
    required this.consultationMode,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AppointmentModel(
      id: doc.id,
      clientUserId: data['clientUserId']?.toString() ?? '',
      clientName: data['clientName']?.toString() ?? '',
      nutritionistUserId: data['nutritionistUserId']?.toString() ?? '',
      nutritionistName: data['nutritionistName']?.toString() ?? '',
      appointmentDate: data['appointmentDate'] is Timestamp
          ? data['appointmentDate'] as Timestamp
          : Timestamp.now(),
      consultationMode: data['consultationMode']?.toString() ?? 'No especificado',
      notes: data['notes']?.toString(),
      status: stringToAppointmentStatus(data['status']?.toString()),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientUserId': clientUserId,
      'clientName': clientName,
      'nutritionistUserId': nutritionistUserId,
      'nutritionistName': nutritionistName,
      'appointmentDate': appointmentDate,
      'consultationMode': consultationMode,
      'notes': notes,
      'status': appointmentStatusToString(status),
      'createdAt': createdAt,
    };
  }
}