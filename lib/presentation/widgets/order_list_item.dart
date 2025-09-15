import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:emprendedor/data/models/order_model.dart';
import 'package:emprendedor/presentation/pages/order_detail_page.dart';
import 'package:emprendedor/presentation/widgets/update_order_status_dialog.dart';

// Nueva clase para el widget de lista de pedidos
class OrderListItem extends StatelessWidget {
  final OrderModel order;

  // Constructor de la clase
  const OrderListItem({super.key, required this.order});

  // Metodo para construir el widget de lista de pedidos
  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Contenido del widget
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(orderId: order.id!),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con ID y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.id?.substring(0, 6) ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Chip(
                    label: Text(
                      getOrderStatusDisplayString(order.status),
                      style: TextStyle(
                        color: _getTextColorForBackground(_getStatusColor(order.status)),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: _getStatusColor(order.status),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Cliente y Dirección
              Text('Cliente: ${order.customerInfo.name}', style: const TextStyle(fontSize: 14)),
              Text('Dirección: ${order.shippingAddress}', style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 4),

              // Productos
              Text(
                'Productos: ${order.items.map((item) => item.productName).join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),

              const SizedBox(height: 4),

              // Total
              Text(
                'Total: \$${order.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 8),

              // Fecha
              Text(
                'Fecha: ${dateFormat.format(order.createdAt.toDate())}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

              const SizedBox(height: 12),

              // Botón actualizar estado
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Actualizar Estado'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return UpdateOrderStatusDialog(
                          orderId: order.id!,
                          currentStatus: order.status,
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Obtener el texto para el estado del pedido
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      }
  }

  // Calcular color de texto para contraste con fondo
  Color _getTextColorForBackground(Color bgColor) {

    // Usa la fórmula de luminancia para decidir entre negro o blanco
    return bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
