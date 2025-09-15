import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/widgets/category_filter_widget.dart';
import 'package:emprendedor/presentation/widgets/product_list_item.dart';
import 'package:emprendedor/presentation/pages/product_form_page.dart';

// Lista de productos
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductController>(
        builder: (context, controller, child) {
          // 1. Mostrar siempre el filtro de categorías arriba
          return Column(
            children: [
              const CategoryFilterWidget(),

              if (controller.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),

              // 2. Manejo de errores
              if (controller.errorMessage != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar productos: ${controller.errorMessage}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => controller.fetchProducts(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // 3. Si no hay productos, mostrar mensaje amigable
              else if (controller.products.isEmpty && !controller.isLoading)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay productos en esta categoría.\n¡Prueba con otra o agrega uno nuevo!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // 4. Si hay productos, mostrar lista
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.products.length,
                    itemBuilder: (context, index) {
                      final product = controller.products[index];
                      return ProductListItem(product: product);
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProductFormPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
