import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emprendedor/data/models/nutritionist/nutritionist_profile_model.dart';
import 'package:emprendedor/presentation/controllers/client/appointment_controller.dart';

class ScheduleAppointmentPage extends StatefulWidget {
  const ScheduleAppointmentPage({super.key});

  @override
  State<ScheduleAppointmentPage> createState() => _ScheduleAppointmentPageState();
}

class _ScheduleAppointmentPageState extends State<ScheduleAppointmentPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentController>().loadNutritionists();
    });
  }

  Future<void> _pickDate(AppointmentController controller) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (selected != null) {
      controller.setSelectedDate(selected);
    }
  }

  Future<void> _pickTime(AppointmentController controller) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (selected != null) {
      controller.setSelectedTime(selected);
    }
  }

  Future<void> _scheduleAppointment(
      AppointmentController controller,
      NutritionistProfileModel nutritionist,
      ) async {
    final success = await controller.scheduleAppointment(nutritionist);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita agendada correctamente'),
        ),
      );
      Navigator.of(context).pop();
    } else if (controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppointmentController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar cita'),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())

      // 🔥 ESTADO VACÍO MEJORADO
          : controller.nutritionists.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  size: 60,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin nutricionistas disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Por ahora no hay profesionales registrados.\nIntenta nuevamente más tarde.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )

      // 🔥 LISTA NORMAL
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.nutritionists.length,
        itemBuilder: (context, index) {
          final nutritionist = controller.nutritionists[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nutritionist.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nutritionist.specialty?.isNotEmpty == true
                        ? nutritionist.specialty!
                        : 'Especialidad no especificada',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nutritionist.consultationMode?.isNotEmpty == true
                        ? 'Modalidad: ${nutritionist.consultationMode}'
                        : 'Modalidad no especificada',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nutritionist.professionalDescription?.isNotEmpty == true
                        ? nutritionist.professionalDescription!
                        : 'Sin descripción profesional.',
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () => _pickDate(controller),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      controller.selectedDate == null
                          ? 'Elegir fecha'
                          : DateFormat('dd/MM/yyyy')
                          .format(controller.selectedDate!),
                    ),
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () => _pickTime(controller),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      controller.selectedTime == null
                          ? 'Elegir hora'
                          : controller.selectedTime!.format(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: controller.notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Motivo o notas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isSaving
                          ? null
                          : () => _scheduleAppointment(
                        controller,
                        nutritionist,
                      ),
                      child: Text(
                        controller.isSaving
                            ? 'Guardando...'
                            : 'Confirmar cita',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}