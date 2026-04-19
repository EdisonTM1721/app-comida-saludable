import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/data/models/coupon_model.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/promotion_controller.dart';

class CreateCouponPage extends StatefulWidget {
  final PromotionModel promotion;

  const CreateCouponPage({super.key, required this.promotion});

  @override
  CreateCouponPageState createState() => CreateCouponPageState();
}

class CreateCouponPageState extends State<CreateCouponPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _couponCodeController = TextEditingController();
  final TextEditingController _minPurchaseController = TextEditingController(text: '0');
  DateTime? _validityDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _couponCodeController.dispose();
    _minPurchaseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validityDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (!mounted || picked == null) return;
    setState(() => _validityDate = picked);
  }

  Future<void> _submitForm() async {
    final controller = context.read<PromotionController>();

    if (!controller.hasUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado.')),
      );
      return;
    }

    if (_isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false) || _validityDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos requeridos.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.promotion.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: ID de promoción no disponible.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final newCoupon = CouponModel(
        code: _couponCodeController.text.trim(),
        promotionId: widget.promotion.id!,
        discountValue: widget.promotion.discountValue,
        validityDate: Timestamp.fromDate(_validityDate!),
        minimumPurchase: double.tryParse(_minPurchaseController.text) ?? 0.0,
        status: CouponStatus.active,
        isUsed: false,
        userId: controller.userId, // ✅ agregado
      );

      final success = await controller.createCoupon(newCoupon);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Cupón creado exitosamente!' : 'Error: ${controller.errorMessage ?? "Ocurrió un error."}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Cupón para ${widget.promotion.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _couponCodeController,
                decoration: const InputDecoration(labelText: 'Código del Cupón'),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa un código.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minPurchaseController,
                decoration: const InputDecoration(labelText: 'Compra mínima'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Fecha de validez: ${_validityDate?.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isSubmitting ? null : () => _selectDate(context),
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
