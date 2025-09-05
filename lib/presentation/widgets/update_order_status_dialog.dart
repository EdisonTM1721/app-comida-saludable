import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/order_model.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';

// Nueva clase para el diálogo de actualización de estado del pedido
class UpdateOrderStatusDialog extends StatefulWidget {
  final String orderId;
  final OrderStatus currentStatus;

  // Constructor de la clase
  const UpdateOrderStatusDialog({
    super.key,
    required this.orderId,
    required this.currentStatus,
  });

  // Metodo para construir el diálogo de actualización de estado del pedido
  @override
  State<UpdateOrderStatusDialog> createState() => _UpdateOrderStatusDialogState();
}

// Nueva clase para el estado del diálogo de actualización de estado del pedido
class _UpdateOrderStatusDialogState extends State<UpdateOrderStatusDialog> {
  late OrderStatus _selectedStatus;
  bool _isUpdating = false;

  // Lista de los posibles estados del pedido
  final List<OrderStatus> _statusOptions = [
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  // Metodo para construir el diálogo de actualización de estado del pedido
  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  // Metodo para actualizar el estado del pedido
  Future<void> _updateStatus() async {
    if (_isUpdating) return;
    setState(() {
      _isUpdating = true;
    });

    // Actualizar el estado del pedido
    final orderController = Provider.of<OrderController>(context, listen: false);
    final success = await orderController.updateOrderStatus(widget.orderId, _selectedStatus);

    // Actualizar la interfaz de usuario
    if (mounted) {
      setState(() {
        _isUpdating = false;
      });
      if (success) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado del pedido actualizado.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${orderController.errorMessage ?? "No se pudo actualizar."}')),
        );
      }
    }
  }

  // Metodo para construir el diálogo de actualización de estado del pedido
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualizar Estado del Pedido'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<OrderStatus>(
            decoration: const InputDecoration(
              labelText: 'Nuevo Estado',
              border: OutlineInputBorder(),
            ),
            value: _selectedStatus,
            items: _statusOptions.map((OrderStatus status) { // Use defined order
              return DropdownMenuItem<OrderStatus>(
                value: status,
                child: Text(getOrderStatusDisplayString(status)),
              );
            }).toList(),
            onChanged: (OrderStatus? newValue) {
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
      actions: <Widget>[
        TextButton(
          child: const Text('Cancelar'),
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          onPressed: _isUpdating || _selectedStatus == widget.currentStatus ? null : _updateStatus,
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}
