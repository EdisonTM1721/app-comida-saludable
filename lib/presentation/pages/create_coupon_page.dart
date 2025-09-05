import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/data/models/coupon_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/promotion_model.dart';

// Nueva página para crear un cupón
class CreateCouponPage extends StatefulWidget {
  final String promotionId;

  // Constructor de la nueva página
  const CreateCouponPage({super.key, required this.promotionId});

  // Metodo para crear una nueva instancia de la página
  @override
  // CORREGIDO: Devolver la clase de estado pública
  CreateCouponPageState createState() => CreateCouponPageState();
}

// Estado de la nueva página
// CORREGIDO: Hacer la clase de estado pública (quitar el guion bajo '_')
class CreateCouponPageState extends State<CreateCouponPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _couponCodeController = TextEditingController();
  final TextEditingController _minPurchaseController = TextEditingController(text: '0.0');
  DateTime? _validityDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  // Limpiar los controladores al salir de la página
  @override
  void dispose() {
    _couponCodeController.dispose();
    _minPurchaseController.dispose();
    super.dispose();
  }

  // Metodo para seleccionar la fecha
  Future<void> _selectDate(BuildContext context) async {

    final DateTime? picked = await showDatePicker(
      context: context, // Usar el context pasado
      initialDate: _validityDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    // DESPUÉS del await, comprobar 'mounted'.
    if (!mounted || picked == null) return;
    setState(() {
      _validityDate = picked;
    });
  }

  // Metodo para enviar el formulario
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

    final promotionController = Provider.of<PromotionController>(context, listen: false);
    PromotionModel? promotion;

    try {

      promotion = promotionController.promotions.firstWhere((p) => p.id == widget.promotionId);

      final newCoupon = CouponModel(
        code: _couponCodeController.text.trim(),
        promotionId: widget.promotionId,
        discountValue: promotion.discountValue,
        validityDate: Timestamp.fromDate(_validityDate!),
        minimumPurchase: double.tryParse(_minPurchaseController.text) ?? 0.0,
        status: CouponStatus.active,
      );

      await promotionController.createCoupon(newCoupon);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cupón creado exitosamente!')),
      );
      Navigator.of(context).pop();

    } catch (error) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear cupón: $error')),
      );
    } finally {
      // DESPUÉS de todo (incluyendo awaits implícitos), comprobar 'mounted'
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  // Construir la página
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cupón')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Crea un cupón para la promoción seleccionada.'),
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
                decoration: const InputDecoration(labelText: 'Monto Mínimo de Compra (opcional)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  // Corregido: value puede ser null aquí.
                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Ingresa un número válido.';
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
