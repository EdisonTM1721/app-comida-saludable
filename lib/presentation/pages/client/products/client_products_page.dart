import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emprendedor/data/models/entrepreneur/product_model.dart';
import 'package:emprendedor/data/repositories/entrepreneur/product_repository.dart';
import 'package:emprendedor/presentation/controllers/client/cart_controller.dart';
import 'package:emprendedor/presentation/pages/client/cart/cart_page.dart';

class ClientProductsPage extends StatelessWidget {
  const ClientProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ProductRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comidas saludables'),
        actions: [
          Consumer<CartController>(
            builder: (context, cart, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Ver carrito',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CartPage(),
                        ),
                      );
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          cart.itemCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: repo.getAvailableProductsForClients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error al cargar productos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay productos disponibles por el momento.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProductImage(imageUrl: product.imageUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (product.category.isNotEmpty)
                              Text(
                                product.category,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (product.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                product.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (product.ingredients.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Ingredientes: ${product.ingredients.join(', ')}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            if (product.approxCalories != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Calorías aprox.: ${product.approxCalories!.toStringAsFixed(0)} kcal',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Builder(
                                  builder: (scaffoldContext) {
                                    return ElevatedButton.icon(
                                      onPressed: () {
                                        scaffoldContext
                                            .read<CartController>()
                                            .addProduct(product);

                                        ScaffoldMessenger.of(scaffoldContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${product.name} agregado al carrito',
                                            ),
                                            duration:
                                            const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        size: 18,
                                      ),
                                      label: const Text('Agregar'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.fastfood,
          size: 36,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl!,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.broken_image,
              size: 36,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}