import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';
import 'package:emprendedor/presentation/widgets/order_list_item.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          // Mostrar indicador de carga
          if (controller.isLoading && controller.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Mostrar mensaje de error
          if (controller.errorMessage != null && controller.orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Ocurrió un error:\n${controller.errorMessage}\nIntenta de nuevo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          // Mostrar mensaje si no hay pedidos
          if (controller.orders.isEmpty) {
            return const Center(
              child: Text(
                'No tienes pedidos aún.\n¡Haz tu primer pedido de comida!',
                style: TextStyle(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Mostrar la lista de pedidos
          return RefreshIndicator(
            color: Colors.orange,
            onRefresh: () => controller.fetchOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: controller.orders.length,
              itemBuilder: (context, index) {
                final order = controller.orders[index];
                return OrderListItem(
                  order: order, // Solo pasamos el pedido
                );
              },
            ),
          );
        },
      ),
    );
  }
}
