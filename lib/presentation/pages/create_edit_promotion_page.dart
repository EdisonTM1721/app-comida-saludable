import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';

// Nueva página para crear o editar una promoción
class CreateEditPromotionPage extends StatefulWidget {
  final PromotionModel? promotionToEdit;

  // Constructor de la nueva página
  const CreateEditPromotionPage({super.key, this.promotionToEdit});

  // Método para crear una nueva instancia de la página
  @override
  // CORREGIDO: Devolver la clase de estado pública
  CreateEditPromotionPageState createState() => CreateEditPromotionPageState();
}

// Estado de la nueva página
// CORREGIDO: Hacer la clase de estado pública
class CreateEditPromotionPageState extends State<CreateEditPromotionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  DiscountType _discountType = DiscountType.percentage; // Asegúrate de que DiscountType esté definido o importado
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // Verificar si la página está en modo de edición
  bool get isEditing => widget.promotionToEdit != null;

  // Inicializar los controladores y los valores iniciales
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.promotionToEdit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.promotionToEdit?.description ?? '');
    _discountValueController = TextEditingController(text: widget.promotionToEdit?.discountValue.toString() ?? '');
    if (isEditing && widget.promotionToEdit != null) {
      _discountType = widget.promotionToEdit!.discountType;
      // ASUMIENDO que widget.promotionToEdit!.startDate y endDate SON de tipo Timestamp
      _startDate = widget.promotionToEdit!.startDate.toDate(); // Sin check ni cast
      _endDate = widget.promotionToEdit!.endDate.toDate();     // Sin check ni cast
    }
  }

  // Limpiar los controladores al salir de la página
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  // Metodo para seleccionar la fecha
  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime.now() : _startDate; // Asegurar que la fecha de fin no sea antes que la de inicio
    final lastDate = DateTime(2030);

    // 'context' es el del BuildContext del ListTile, válido antes del await.
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    // DESPUÉS del await, comprobar 'mounted'.
    if (!mounted || picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      } else {
        _endDate = picked;
        // Opcional: asegurar que la fecha de fin no sea anterior a la de inicio
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate.subtract(const Duration(days: 30)); // O alguna otra lógica
        }
      }
    });
  }

  // Metodo para enviar el formulario
  void _submitForm() async { // Nota: El método es void, pero tiene async operations. Considerar Future<void>.
    // No hay await antes de esta validación. 'context' es el del State.
    if (!(_formKey.currentState?.validate() ?? false)) {
      // No se necesita `if (mounted)` aquí si no hubo await previo en esta función
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos requeridos.')),
      );
      return;
    }

    // 'context' es el del State, usado para Provider ANTES del await.
    final controller = Provider.of<PromotionController>(context, listen: false);

    // Crear el objeto PromotionModel a partir de los datos del formulario
    final promotion = PromotionModel(
      id: widget.promotionToEdit?.id, // Puede ser null si es una nueva promoción
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      discountType: _discountType,
      discountValue: double.tryParse(_discountValueController.text) ?? 0.0, // Más seguro con tryParse
      startDate: Timestamp.fromDate(_startDate),
      endDate: Timestamp.fromDate(_endDate),
      status: PromotionStatus.active, // Asegúrate de que PromotionStatus esté definido o importado
    );

    // AWAIT para la operación del controlador
    bool success = false;
    String? submissionError;

    try {
      success = isEditing
          ? await controller.updatePromotion(promotion)
          : await controller.createPromotion(promotion);
    } catch (e) {
      submissionError = e.toString(); // Captura un error genérico si el controlador no lo maneja
    }

    // DESPUÉS del await, comprobar 'mounted'
    if (!mounted) return;

    // Usar el 'context' actual del State (que está 'mounted')
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promoción ${isEditing ? "actualizada" : "creada"} con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${submissionError ?? controller.errorMessage ?? "Ocurrió un error."}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Construir la página
  @override
  Widget build(BuildContext context) {
    // Este 'context' es el del método build.
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Promoción' : 'Crear Promoción'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la Promoción'),
                // Corregido: Validator puede tomar un String? nullable
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa un nombre.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountValueController,
                decoration: InputDecoration(
                  labelText: 'Valor del Descuento',
                  suffixText: _discountType == DiscountType.percentage ? '%' : '€',
                ),
                keyboardType: TextInputType.number,
                // Corregido: Validator puede tomar un String? nullable
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa un valor.';
                  if (double.tryParse(value) == null) return 'Ingresa un número válido.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<DiscountType>(
                      title: const Text('Porcentaje'),
                      value: DiscountType.percentage,
                      groupValue: _discountType,
                      // Corregido: onChanged puede recibir un valor nullable
                      onChanged: (DiscountType? value) {
                        if (value != null) {
                          setState(() => _discountType = value);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<DiscountType>(
                      title: const Text('Monto Fijo'),
                      value: DiscountType.fixedAmount,
                      groupValue: _discountType,
                      // Corregido: onChanged puede recibir un valor nullable
                      onChanged: (DiscountType? value) {
                        if (value != null) {
                          setState(() => _discountType = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Fecha de Inicio: ${_startDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                // Pasar el 'context' del build a _selectDate.
                // _selectDate maneja el 'mounted' después de su propio await.
                onTap: () => _selectDate(context, isStart: true),
              ),
              ListTile(
                title: Text('Fecha de Fin: ${_endDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStart: false),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                // _submitForm maneja su propio mounted y context.
                onPressed: _submitForm,
                child: Text(isEditing ? 'Actualizar Promoción' : 'Crear Promoción'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

