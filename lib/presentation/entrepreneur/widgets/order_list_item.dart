import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:emprendedor/data/models/shared/order_model.dart';
import 'package:emprendedor/presentation/pages/entrepreneur/orders/order_detail_page.dart';
import 'package:emprendedor/presentation/entrepreneur/widgets/update_order_status_dialog.dart';

class OrderListItem extends StatelessWidget {
  final OrderModel order;

  const OrderListItem({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: order.id == null
            ? null
            : () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  OrderDetailPage(orderId: order.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 CABECERA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Pedido ${order.formattedOrderNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      getOrderStatusDisplayString(order.status),
                      style: TextStyle(
                        color: _getTextColorForBackground(statusColor),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: statusColor,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 👤 CLIENTE
              Text(
                'Cliente: ${order.customerInfo.name}',
                style: const TextStyle(fontSize: 14),
              ),

              // 📍 DIRECCIÓN
              Text(
                'Dirección: ${order.shippingAddress}',
                style: const TextStyle(fontSize: 14),
              ),

              // 💳 PAGO
              Text(
                'Pago: ${order.paymentMethod}',
                style: const TextStyle(fontSize: 14),
              ),

              if (order.latitude != null && order.longitude != null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '📍 Ubicación disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 6),

              // 🛒 PRODUCTOS
              Text(
                'Productos: ${order.items.map((e) => e.productName).join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 6),

              // 💰 TOTAL
              Text(
                'Total: \$${order.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 8),

              // 📅 FECHA
              Text(
                'Fecha: ${dateFormat.format(order.createdAt.toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 12),

              // 🔧 BOTÓN
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Actualizar estado'),
                  onPressed: order.id == null
                      ? null
                      : () async {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return UpdateOrderStatusDialog(
                          orderId: order.id!,
                          currentStatus: order.status,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Color _getTextColorForBackground(Color bgColor) {
    return bgColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }
}