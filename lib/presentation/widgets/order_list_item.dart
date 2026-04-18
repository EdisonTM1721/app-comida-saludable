import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:emprendedor/data/models/order_model.dart';
import 'package:emprendedor/presentation/pages/entrepreneur/orders/order_detail_page.dart';
import 'package:emprendedor/presentation/widgets/update_order_status_dialog.dart';

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
      child: InkWell(
        onTap: order.id == null
            ? null
            : () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(orderId: order.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Pedido #${(order.orderNumber ?? 0).toString().padLeft(4, '0')}',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                'Cliente: ${order.customerInfo.name}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Dirección: ${order.shippingAddress}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Pago: ${order.paymentMethod}',
                style: const TextStyle(fontSize: 14),
              ),

              if (order.latitude != null && order.longitude != null)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'Ubicación disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              Text(
                'Productos: ${order.items.map((item) => item.productName).join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),

              Text(
                'Total: \$${order.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Fecha: ${dateFormat.format(order.createdAt.toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Actualizar estado'),
                  onPressed: order.id == null
                      ? null
                      : () async {
                    await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return UpdateOrderStatusDialog(
                          orderId: order.id!,
                          currentStatus: order.status,
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
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
    return bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}