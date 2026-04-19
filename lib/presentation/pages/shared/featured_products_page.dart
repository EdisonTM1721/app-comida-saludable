import 'package:flutter/material.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/product_controller.dart';
import 'package:provider/provider.dart';

// Nueva página para mostrar los productos destacados
class FeaturedProductsPage extends StatelessWidget {
  const FeaturedProductsPage({super.key});

  // Construir la página
  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);

    // Cargar los productos destacados
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos Destacados'),
      ),
      body: productController.isLoading && productController.products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : productController.errorMessage != null
          ? Center(child: Text('Error: ${productController.errorMessage}'))
          : productController.products.isEmpty
          ? const Center(child: Text('No hay productos para mostrar.'))
          : ListView.builder(
          itemCount: productController.products.length,
          itemBuilder: (context, index) {
            final product = productController.products[index];
            return Card(
              child: ListTile(
                title: Text(product.name),
                trailing: Switch(
                    value: product.isFeatured,
                    onChanged: (bool value) {
                      productController.toggleFeaturedStatus(
                        product.id!,
                        value,
                      );
                    }
                ),
              ),
            );
          }
      ),
    );
  }
}