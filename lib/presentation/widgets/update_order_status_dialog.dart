import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/order_model.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/order_controller.dart';

class UpdateOrderStatusDialog extends StatefulWidget {
  final String orderId;
  final OrderStatus currentStatus;

  const UpdateOrderStatusDialog({
    super.key,
    required this.orderId,
    required this.currentStatus,
  });

  @override
  State<UpdateOrderStatusDialog> createState() =>
      _UpdateOrderStatusDialogState();
}

class _UpdateOrderStatusDialogState extends State<UpdateOrderStatusDialog> {
  late OrderStatus _selectedStatus;
  bool _isUpdating = false;

  final List<OrderStatus> _statusOptions = const [
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  Future<void> _updateStatus() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    final orderController = context.read<OrderController>();
    final success = await orderController.updateOrderStatus(
      widget.orderId,
      _selectedStatus,
    );

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado del pedido actualizado.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${orderController.errorMessage ?? "No se pudo actualizar."}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualizar estado del pedido'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<OrderStatus>(
            decoration: const InputDecoration(
              labelText: 'Nuevo estado',
              border: OutlineInputBorder(),
            ),
            value: _selectedStatus,
            items: _statusOptions.map((status) {
              return DropdownMenuItem<OrderStatus>(
                value: status,
                child: Text(getOrderStatusDisplayString(status)),
              );
            }).toList(),
            onChanged: _isUpdating
                ? null
                : (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedStatus = newValue;
                });
              }
            },
          ),
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isUpdating || _selectedStatus == widget.currentStatus
              ? null
              : _updateStatus,
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}