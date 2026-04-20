import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/product_controller.dart';
import 'package:emprendedor/presentation/shared/widgets/category_filter_widget.dart';
import 'package:emprendedor/presentation/client/widgets/product_list_item.dart';
import 'package:emprendedor/presentation/pages/entrepreneur/products/product_form_page.dart';
// 👇 NUEVOS IMPORTS
import 'package:emprendedor/presentation/shared/widgets/common/app_empty_state.dart';
import 'package:emprendedor/presentation/shared/widgets/common/app_error_state.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              const CategoryFilterWidget(),

              // 🔄 LOADING
              if (controller.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),

              // ❌ ERROR
              if (controller.errorMessage != null)
                Expanded(
                  child: AppErrorState(
                    message:
                    'Error al cargar productos:\n${controller.errorMessage}',
                    onRetry: () => controller.fetchProducts(),
                  ),
                )

              // 📭 VACÍO
              else if (controller.products.isEmpty && !controller.isLoading)
                const Expanded(
                  child: AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No hay productos en esta categoría',
                    message:
                    'Prueba con otra categoría o agrega un producto nuevo.',
                  ),
                )

              // 📋 LISTA
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

      // ➕ BOTÓN
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