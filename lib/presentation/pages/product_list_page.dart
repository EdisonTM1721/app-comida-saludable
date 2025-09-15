import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/widgets/category_filter_widget.dart';
import 'package:emprendedor/presentation/widgets/product_list_item.dart';
import 'package:emprendedor/presentation/pages/product_form_page.dart';

// Lista de productos
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  // Construye el widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductController>(
        builder: (context, controller, child) {
          // 1. Si está cargando y no hay datos previos, muestra un indicador de carga.
          if (controller.isLoading && controller.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Si no hay productos después de cargar, muestra un mensaje amigable.
          if (controller.products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No hay productos para mostrar.\n¡Agrega tu primer producto!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Si hay un mensaje de error, lo muestra.
          if (controller.errorMessage != null) {
            return Center(
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
            );
          }

          // 4. Si hay productos, muestra la lista.
          return Column(
            children: [
              const CategoryFilterWidget(),
              if (controller.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
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
          // Llama a ProductFormPage directamente ⭐
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