import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';

// Nueva página de inicio
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Construir la página
  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);
    final orderController = Provider.of<OrderController>(context);

    // Obtener las estadísticas de la tienda
    double totalVentas = orderController.totalVentas;
    int pedidosActivos = orderController.activeOrders;

    // Obtener el producto más vendido
    final topSellingProduct = productController.topSellingProduct;

    // Construir la página
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hola, Emprendedor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Mostrar las estadísticas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ventas', style: TextStyle(fontSize: 18)),
                    Text('\$${totalVentas.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Mostrar el número de pedidos activos
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pedidos activos', style: TextStyle(fontSize: 18)),
                    Text('$pedidosActivos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Mostrar el producto más vendido
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Productos más vendidos', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    if (topSellingProduct != null)
                      ListTile(
                        leading: topSellingProduct.imageUrl != null && topSellingProduct.imageUrl!.isNotEmpty
                            ? Image.network(topSellingProduct.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                            : Container(width: 50, height: 50, color: Colors.grey),
                        title: Text(topSellingProduct.name),
                        subtitle: Text('\$${topSellingProduct.price.toStringAsFixed(2)}'),
                      )
                    else
                      const Text('No hay productos más vendidos aún.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}