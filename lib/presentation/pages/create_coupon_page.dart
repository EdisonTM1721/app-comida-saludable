import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/data/models/coupon_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/promotion_model.dart';

// Nueva página para crear un cupón
class CreateCouponPage extends StatefulWidget {
  final PromotionModel promotion;

  // Constructor de la nueva página
  const CreateCouponPage({super.key, required this.promotion});

  // Metodo para crear una nueva instancia de la página
  @override
  CreateCouponPageState createState() => CreateCouponPageState();
}

// Estado de la nueva página
class CreateCouponPageState extends State<CreateCouponPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _couponCodeController = TextEditingController();
  final TextEditingController _minPurchaseController = TextEditingController(text: '0');
  DateTime? _validityDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

  }

  // Limpieza de controladores en dispose
  @override
  void dispose() {
    _couponCodeController.dispose();
    _minPurchaseController.dispose();
    super.dispose();
  }

  // Selecciona la fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validityDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _validityDate = picked;
    });
  }

  // Envía el formulario
  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false) || _validityDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos requeridos.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() { _isSubmitting = true; });

    try {
      // Usamos widget.promotion.id que ya está disponible
      if (widget.promotion.id == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: El ID de la promoción no está disponible.')),
        );
        setState(() { _isSubmitting = false; });
        return;
      }

      // Crea un nuevo cupón
      final newCoupon = CouponModel(
        code: _couponCodeController.text.trim(),
        promotionId: widget.promotion.id!, // Correcto, usa el id del objeto promotion
        discountValue: widget.promotion.discountValue, // Correcto
        validityDate: Timestamp.fromDate(_validityDate!),
        minimumPurchase: double.tryParse(_minPurchaseController.text) ?? 0.0,
        status: CouponStatus.active,
        isUsed: false,
      );

      // Llama a la función para crear el cupón
      final promotionController = context.read<PromotionController>();
      final bool success = await promotionController.createCoupon(newCoupon);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cupón creado exitosamente!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(promotionController.errorMessage ?? 'Error al crear cupón.')),
        );
      }

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $error')),
      );
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  // Construye el widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Cupón para ${widget.promotion.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Crea un cupón para la promoción "${widget.promotion.name}". El descuento será de ${widget.promotion.discountValue}%.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _couponCodeController,
                decoration: const InputDecoration(labelText: 'Código del Cupón'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un código para el cupón.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _validityDate == null
                      ? 'Fecha de Vencimiento'
                      : 'Válido hasta: ${_validityDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isSubmitting ? null : () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minPurchaseController,
                decoration: const InputDecoration(
                  labelText: 'Monto Mínimo de Compra',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {

                    return null;
                  }
                  final number = double.tryParse(value);
                  if (number == null) {
                    return 'Ingresa un número válido.';
                  }
                  if (number < 0) {
                    return 'El monto no puede ser negativo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Crear Cupón'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
