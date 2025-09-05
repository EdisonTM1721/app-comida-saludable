import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';
import 'package:emprendedor/presentation/widgets/order_list_item.dart';

// Nueva página para la gestión de pedidos
class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  // Metodo para crear una nueva instancia de la página
  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

// Estado de la nueva página
class _OrderListPageState extends State<OrderListPage> {
  @override
  void initState() {
    super.initState();
  }

  // Construir la página
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null && controller.orders.isEmpty) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${controller.errorMessage}\nPor favor, intenta de nuevo.', textAlign: TextAlign.center),
                )
            );
          }
          if (controller.orders.isEmpty) {
            return const Center(
              child: Text(
                'No hay pedidos para mostrar.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Mostrar la lista de pedidos
          return RefreshIndicator(
            onRefresh: () => controller.fetchOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: controller.orders.length,
              itemBuilder: (context, index) {
                final order = controller.orders[index];
                return OrderListItem(order: order);
              },
            ),
          );
        },
      ),
    );
  }
}