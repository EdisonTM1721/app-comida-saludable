import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/pages/product_form_page.dart';

// Nueva clase para el widget de lista de productos
class ProductListItem extends StatelessWidget {
  final ProductModel product;

  // Constructor de la clase
  const ProductListItem({super.key, required this.product});

  // Metodo para construir el widget de lista de productos
  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context, listen: false);

    // Contenido del widget
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de la imagen del producto
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  product.imageUrl!,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    );
                  },
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(Icons.fastfood, size: 60, color: Colors.grey[400]),
              ),
            const SizedBox(height: 12.0),

            // Detalles del producto
            Text(
              product.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4.0),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 4.0),
            if (product.approxCalories != null)
              Text(
                'Calorías: ${product.approxCalories!.toStringAsFixed(0)} kcal',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            const SizedBox(height: 4.0),
            Text(
              'Categoría: ${product.category}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Estado: ${product.status.displayName}',
              style: TextStyle(
                fontSize: 14,
                color: product.status == ProductStatus.available ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12.0),

            // Botones de acción y switch de destacado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Destacado', style: TextStyle(fontSize: 14)),
                    Switch(
                      value: product.isFeatured,
                      onChanged: (newValue) {
                        productController.toggleFeaturedStatus(product.id!, newValue);
                      },
                      activeThumbColor: Colors.amber,
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductFormPage(productToEdit: product),
                          ),
                        );
                      },
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: Icon(
                        product.status == ProductStatus.available ? Icons.toggle_off : Icons.toggle_on,
                        color: product.status == ProductStatus.available ? Colors.orange : Colors.green,
                      ),
                      onPressed: () {
                        productController.toggleProductStatus(product.id!, product.status);
                      },
                      tooltip: product.status == ProductStatus.available ? 'Desactivar' : 'Activar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirmar Eliminación'),
                              content: Text('¿Estás seguro de que deseas eliminar "${product.name}"?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancelar'),
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                ),
                                TextButton(
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm == true) {
                          await productController.deleteProduct(product.id!, product.imageUrl);
                        }
                      },
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}