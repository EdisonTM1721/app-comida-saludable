import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/order_model.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';
import 'package:emprendedor/presentation/widgets/update_order_status_dialog.dart';

// Nueva página para mostrar los detalles de un pedido
class OrderDetailPage extends StatefulWidget {
  final String orderId;

  // Constructor de la nueva página
  const OrderDetailPage({super.key, required this.orderId});

  // Metodo para crear una nueva instancia de la página
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

// Estado de la nueva página
class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {

      // Actualizar el estado del pedido
      final controller = Provider.of<OrderController>(context, listen: false);
      controller.clearSelectedOrder();
      controller.fetchOrderDetails(widget.orderId);
    });
  }

  // Construir la página
  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Consumer<OrderController>(
          builder: (context, controller, _) {
            return Text(controller.selectedOrder != null
                ? 'Detalle Pedido #${controller.selectedOrder!.id?.substring(0, 6)}'
                : 'Cargando Pedido...');
          },
        ),
      ),
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          final order = controller.selectedOrder;

          if (controller.isLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null && order == null) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }
          if (order == null) {
            return const Center(child: Text('No se pudo cargar el pedido.'));
          }

          // Mostrar los detalles del pedido
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Información del Pedido'),
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('ID Pedido:', order.id ?? 'N/A'),
                        _buildDetailRow('Estado:', getOrderStatusDisplayString(order.status),
                            valueColor: _getStatusColor(order.status)),
                        _buildDetailRow('Fecha Creación:', dateFormat.format(order.createdAt.toDate())),
                        if (order.updatedAt != null)
                          _buildDetailRow('Última Actualización:', dateFormat.format(order.updatedAt!.toDate())),
                        if (order.deliveredAt != null)
                          _buildDetailRow('Fecha Entrega:', dateFormat.format(order.deliveredAt!.toDate())),
                        _buildDetailRow('Total:', '\$${order.totalPrice.toStringAsFixed(2)}', isBold: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sección de rastreo del paquete de envío
                _buildSectionTitle('Estado del Envío'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _getTrackingStatusText(order.status),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 24),
                        // Progress bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusColumn('Pagado', _getTrackingStepColor(order.status, 'pending')),
                            Expanded(child: Divider(color: _getTrackingStepColor(order.status, 'preparing'))),
                            _buildStatusColumn('Preparando', _getTrackingStepColor(order.status, 'preparing')),
                            Expanded(child: Divider(color: _getTrackingStepColor(order.status, 'shipped'))),
                            _buildStatusColumn('Enviado', _getTrackingStepColor(order.status, 'shipped')),
                            Expanded(child: Divider(color: _getTrackingStepColor(order.status, 'delivered'))),
                            _buildStatusColumn('Entregado', _getTrackingStepColor(order.status, 'delivered')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mostrar los detalles de los productos
                _buildSectionTitle('Productos Solicitados (${order.items.length})'),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? SizedBox(
                          width: 50,
                          height: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(item.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                            ),
                          ),
                        )
                            : const Icon(Icons.fastfood_outlined, size: 30),
                        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('Cantidad: ${item.quantity}\nPrecio Unit.: \$${item.priceAtPurchase.toStringAsFixed(2)}'),
                        trailing: Text('\$${(item.quantity * item.priceAtPurchase).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Mostrar los detalles del cliente
                _buildSectionTitle('Información del Cliente'),
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Nombre:', order.customerInfo.name),
                        _buildDetailRow('Email:', order.customerInfo.email),
                        if (order.customerInfo.phoneNumber != null && order.customerInfo.phoneNumber!.isNotEmpty)
                          _buildDetailRow('Teléfono:', order.customerInfo.phoneNumber!),
                        _buildDetailRow('Dirección Entrega:', order.shippingAddress, maxLines: 3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sync_alt),
                    label: const Text('Actualizar Estado del Pedido'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return UpdateOrderStatusDialog(
                            orderId: order.id!,
                            currentStatus: order.status,
                          );
                        },
                      ).then((_) {
                        Provider.of<OrderController>(context, listen: false)
                            .fetchOrderDetails(widget.orderId);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16)
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Metodo para obtener un color según el estado del rastreo
  Color _getTrackingStepColor(OrderStatus currentStatus, String stepStatus) {
    final statusMap = {
      'pending': 1,
      'preparing': 2,
      'shipped': 3,
      'delivered': 4,
    };
    final currentStep = statusMap[currentStatus.name] ?? 0;
    final step = statusMap[stepStatus] ?? 0;
    return currentStep >= step ? Colors.teal : Colors.grey;
  }

  // Metodo para obtener un texto descriptivo del estado del rastreo
  String _getTrackingStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Su pago ha sido procesado. El pedido está pendiente de confirmación.';
      case OrderStatus.preparing:
        return 'Su pedido está siendo preparado para ser enviado.';
      case OrderStatus.shipped:
        return 'Su pedido ha sido enviado y está en camino.';
      case OrderStatus.delivered:
        return 'Su pedido ha sido entregado exitosamente.';
      case OrderStatus.cancelled:
        return 'El pedido ha sido cancelado.';
      }
  }

  // Metodo para obtener una cadena de texto que representa el estado del pedido
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }

  // Metodo para obtener una cadena de texto que representa el estado del pedido
  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                color: valueColor ?? Colors.black54,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Metodo para obtener un color según el estado del pedido
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade700;
      case OrderStatus.preparing:
        return Colors.blue.shade700;
      case OrderStatus.shipped:
        return Colors.purple.shade700;
      case OrderStatus.delivered:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return Colors.red.shade700;
      }
  }

  // Metodo para construir una columna de estado en el rastreo
  Widget _buildStatusColumn(String title, Color color) {
    return Column(
      children: [
        Icon(
          color == Colors.teal ? Icons.check_circle : Icons.radio_button_unchecked,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
