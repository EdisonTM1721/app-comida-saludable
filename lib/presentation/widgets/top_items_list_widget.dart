import 'package:flutter/material.dart';

// Nueva clase para el widget de lista de productos o clientes
enum TopListType { products, customers }

// Nueva clase para el widget de lista de productos o clientes
class TopItemsListWidget<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final TopListType type;
  final Widget Function(BuildContext context, T item) itemBuilder;

  // Constructor de la clase
  const TopItemsListWidget({
    super.key,
    required this.title,
    required this.items,
    required this.type,
    required this.itemBuilder,
  });

  // Metodo para construir el widget de lista de productos o clientes
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("No hay datos de ${type == TopListType.products ? 'productos' : 'clientes'} para mostrar."),
            ],
          ),
        ),
      );
    }

    // Si hay datos, construir el widget de lista
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) => itemBuilder(context, items[index]),
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          ],
        ),
      ),
    );
  }
}