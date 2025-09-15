import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';
import 'package:emprendedor/presentation/widgets/order_list_item.dart';
import 'package:emprendedor/presentation/pages/order_detail_page.dart';

// Nueva página para mostrar la lista de pedidos
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
    // ⭐ CORRECCIÓN: Se envuelve la llamada a `fetchOrders` en un callback.
    // Esto asegura que la función se ejecute DESPUÉS de que el widget se haya construido.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false).fetchOrders();
    });
  }

  // Construir la página
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          // 1. Muestra un indicador de carga si los datos aún no se han cargado.
          if (controller.isLoading && controller.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Si hay un mensaje de error y la lista no está vacía, muestra el error.
          if (controller.errorMessage != null && controller.orders.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${controller.errorMessage}\nPor favor, intenta de nuevo.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // 3. Si la lista está vacía, muestra el mensaje amigable.
          if (controller.orders.isEmpty) {
            return const Center(
              child: Text(
                'No hay pedidos para mostrar.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          }

          // 4. Muestra la lista de pedidos.
          return RefreshIndicator(
            onRefresh: () => controller.fetchOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: controller.orders.length,
              itemBuilder: (context, index) {
                final order = controller.orders[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OrderDetailPage(orderId: order.id!),
                      ),
                    );
                  },
                  child: OrderListItem(order: order),
                );
              },
            ),
          );
        },
      ),
    );
  }
}