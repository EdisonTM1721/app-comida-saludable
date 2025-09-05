import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/widgets/category_filter_widget.dart';
import 'package:emprendedor/presentation/widgets/product_list_item.dart';
import 'package:emprendedor/presentation/pages/product_form_page.dart';

// Nueva clase para la lista de productos
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  // Metodo para mostrar el panel de opciones de agregar producto
  void _showAddProductOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // Hacemos el fondo del modal transparente
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return SafeArea(
          // Envolvemos el contenido en un Container para darle estilo
          child: Container(
            color: Colors.transparent,
            child: Wrap(
              children: <Widget>[
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const Text('Agregar Nuevo Producto'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProductFormPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Construye la lista de productos
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }

          // Si no hay productos, muestra un mensaje
          return Column(
            children: [
              const CategoryFilterWidget(),
              if (controller.isLoading && controller.products.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
              Expanded(
                child: controller.products.isEmpty
                    ? const Center(
                  child: Text(
                    'No hay productos para mostrar.\n¡Agrega tu primer producto!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
                    : ListView.builder(
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
          _showAddProductOptions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}