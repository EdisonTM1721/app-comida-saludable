import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/product_controller.dart';

// Nueva clase para el widget de filtro de categorías
class CategoryFilterWidget extends StatelessWidget {
  const CategoryFilterWidget({super.key});

  // Metodo para construir el widget de filtro de categorías
  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);

    // Contenido del widget
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Filtrar por Categoría',
          border: OutlineInputBorder(),
        ),
        initialValue: productController.selectedCategory,
        items: productController.categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            productController.setSelectedCategory(newValue);
          }
        },
      ),
    );
  }
}