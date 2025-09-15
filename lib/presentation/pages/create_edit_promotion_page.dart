import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';

class CreateEditPromotionPage extends StatefulWidget {
  final PromotionModel? promotionToEdit;

  const CreateEditPromotionPage({super.key, this.promotionToEdit});

  @override
  CreateEditPromotionPageState createState() => CreateEditPromotionPageState();
}

class CreateEditPromotionPageState extends State<CreateEditPromotionPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountValueController;
  late DiscountType _discountType;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmitting = false;

  bool get isEditing => widget.promotionToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.promotionToEdit?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.promotionToEdit?.description ?? '');
    _discountValueController = TextEditingController(
        text: widget.promotionToEdit?.discountValue.toString() ?? '');
    _discountType =
        widget.promotionToEdit?.discountType ?? DiscountType.percentage;
    _startDate = widget.promotionToEdit?.startDate.toDate() ?? DateTime.now();
    _endDate = widget.promotionToEdit?.endDate.toDate() ??
        DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (!mounted || picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate.subtract(const Duration(days: 30));
        }
      }
    });
  }

  Future<void> _submitForm() async {
    final controller =
    Provider.of<PromotionController>(context, listen: false);

    if (!controller.hasUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario no autenticado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, completa todos los campos requeridos.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final promotion = PromotionModel(
        id: widget.promotionToEdit?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        discountType: _discountType,
        discountValue: double.tryParse(_discountValueController.text) ?? 0.0,
        startDate: Timestamp.fromDate(_startDate),
        endDate: Timestamp.fromDate(_endDate),
        status: PromotionStatus.active,
        userId: controller.userId!,
      );

      final success = await controller.createOrUpdatePromotion(promotion);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Promoción ${isEditing ? "actualizada" : "creada"} con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Error al guardar promoción.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Promoción' : 'Crear Promoción')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la Promoción'),
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
                  suffixText: _discountType == DiscountType.percentage ? '%' : '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa un valor.';
                  final parsedValue = double.tryParse(value);
                  if (parsedValue == null || parsedValue < 0) return 'Ingresa un número válido y positivo.';
                  if (_discountType == DiscountType.percentage && parsedValue > 100) return 'El porcentaje no puede ser mayor a 100.';
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
                      onChanged: (value) => value != null ? setState(() => _discountType = value) : null,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<DiscountType>(
                      title: const Text('Monto Fijo'),
                      value: DiscountType.fixed,
                      groupValue: _discountType,
                      onChanged: (value) => value != null ? setState(() => _discountType = value) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Fecha de Inicio: ${_startDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isSubmitting ? null : () => _selectDate(context, isStart: true),
              ),
              ListTile(
                title: Text('Fecha de Fin: ${_endDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isSubmitting ? null : () => _selectDate(context, isStart: false),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(isEditing ? 'Actualizar Promoción' : 'Crear Promoción'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
