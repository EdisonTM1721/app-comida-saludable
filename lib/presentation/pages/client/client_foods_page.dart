import 'package:flutter/material.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:emprendedor/data/repositories/product_repository.dart';

class ClientFoodsPage extends StatelessWidget {
  const ClientFoodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ProductRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comidas saludables'),
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
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
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