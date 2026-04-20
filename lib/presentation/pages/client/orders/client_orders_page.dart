import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:emprendedor/data/models/shared/order_model.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/order_controller.dart';

class ClientOrdersPage extends StatefulWidget {
  const ClientOrdersPage({super.key});

  @override
  State<ClientOrdersPage> createState() => _ClientOrdersPageState();
}

class _ClientOrdersPageState extends State<ClientOrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderController>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
      ),
      body: Consumer<OrderController>(
        builder: (context, controller, _) {
          final orders = controller.orders;

          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (orders.isEmpty) {
            return const Center(
              child: Text('Aún no tienes pedidos'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    'Pedido #${(order.orderNumber ?? 0).toString().padLeft(4, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: \$${order.totalPrice.toStringAsFixed(2)}'),
                      Text(
                        'Fecha: ${dateFormat.format(order.createdAt.toDate())}',
                      ),
                      Text('Pago: ${order.paymentMethod}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(_getStatus(order.status)),
                    backgroundColor: _getColor(order.status),
                  ),
                  onTap: () {
                    // luego conectamos el detalle del pedido
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.preparing:
        return 'Preparando';
      case OrderStatus.shipped:
        return 'En camino';
      case OrderStatus.delivered:
        return 'Entregado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color _getColor(OrderStatus status) {
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
}