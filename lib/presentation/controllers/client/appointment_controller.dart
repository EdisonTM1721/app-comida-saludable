import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:emprendedor/data/models/client/appointment_model.dart';
import 'package:emprendedor/data/models/nutritionist/nutritionist_profile_model.dart';
import 'package:emprendedor/data/repositories/client/appointment_repository.dart';
import 'package:emprendedor/data/repositories/client/client_profile_repository.dart';
import 'package:emprendedor/data/repositories/nutritionist/nutritionist_profile_repository.dart';

class AppointmentController extends ChangeNotifier {
  final Logger _logger = Logger('AppointmentController');
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final NutritionistProfileRepository _nutritionistRepository =
  NutritionistProfileRepository();
  final ClientProfileRepository _clientProfileRepository =
  ClientProfileRepository();

  final notesController = TextEditingController();

  List<NutritionistProfileModel> _nutritionists = [];
  List<NutritionistProfileModel> get nutritionists => _nutritionists;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  TimeOfDay? _selectedTime;
  TimeOfDay? get selectedTime => _selectedTime;

  int _appointmentsCount = 0;
  int get appointmentsCount => _appointmentsCount;

  Future<void> loadNutritionists() async {
    _setLoading(true);
    _setError(null);

    try {
      _nutritionists = await _nutritionistRepository.getAllNutritionists();
      _setLoading(false);
    } catch (e, stackTrace) {
      _logger.severe('Error cargando nutricionistas', e, stackTrace);
      _setError('No se pudieron cargar los nutricionistas.');
      _setLoading(false);
    }
  }

  Future<void> loadAppointmentsCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _appointmentsCount =
      await _appointmentRepository.countAppointmentsForClient(user.uid);
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe('Error contando citas', e, stackTrace);
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay time) {
    _selectedTime = time;
    notifyListeners();
  }

  Future<bool> scheduleAppointment(
      NutritionistProfileModel nutritionist,
      ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _setError('No hay usuario autenticado.');
      return false;
    }

    if (_selectedDate == null || _selectedTime == null) {
      _setError('Selecciona fecha y hora para la cita.');
      return false;
    }

    _setSaving(true);
    _setError(null);

    try {
      final clientProfile =
      await _clientProfileRepository.getClientProfile(user.uid);

      final clientName = clientProfile?.name?.trim().isNotEmpty == true
          ? clientProfile!.name
          : (user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : 'Cliente');

      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final appointment = AppointmentModel(
        clientUserId: user.uid,
        clientName: clientName,
        nutritionistUserId: nutritionist.userId,
        nutritionistName: nutritionist.name,
        appointmentDate: Timestamp.fromDate(dateTime),
        consultationMode: nutritionist.consultationMode ?? 'No especificado',
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        status: AppointmentStatus.pending,
        createdAt: Timestamp.now(),
      );

      await _appointmentRepository.createAppointment(appointment);
      await loadAppointmentsCount();

      notesController.clear();
      _selectedDate = null;
      _selectedTime = null;

      _setSaving(false);
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error agendando cita', e, stackTrace);
      _setError('No se pudo agendar la cita.');
      _setSaving(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    if (_isSaving == value) return;
    _isSaving = value;
    notifyListeners();
  }

  void _setError(String? value) {
    if (_errorMessage == value) return;
    _errorMessage = value;
    notifyListeners();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}