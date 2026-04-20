import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emprendedor/data/models/entrepreneur/product_model.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/product_controller.dart';

class ProductFormPage extends StatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormPage({super.key, this.productToEdit});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _caloriesController;

  String? _selectedCategory;
  ProductStatus _selectedStatus = ProductStatus.available;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    final product = widget.productToEdit;

    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product != null ? product.price.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _ingredientsController = TextEditingController(
      text: product?.ingredients.join(', ') ?? '',
    );
    _caloriesController = TextEditingController(
      text: product?.approxCalories?.toStringAsFixed(0) ?? '',
    );

    _selectedCategory = product?.category;
    _selectedStatus = product?.status ?? ProductStatus.available;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<ProductController>();
      controller.clearSelectedImage();
      await controller.initUser();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct(ProductController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final double? price = double.tryParse(_priceController.text.trim());
    final double? calories = _caloriesController.text.trim().isEmpty
        ? null
        : double.tryParse(_caloriesController.text.trim());

    final product = ProductModel(
      id: widget.productToEdit?.id,
      name: _nameController.text.trim(),
      price: price ?? 0.0,
      imageUrl: widget.productToEdit?.imageUrl,
      status: _selectedStatus,
      category: _selectedCategory ?? 'Todas',
      description: _descriptionController.text.trim(),
      ingredients: _ingredientsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      isFeatured: widget.productToEdit?.isFeatured ?? false,
      approxCalories: calories,
      userId: controller.userId,
    );

    final success = widget.productToEdit == null
        ? await controller.addProduct(product)
        : await controller.updateProduct(product);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productToEdit == null ? 'Agregar Producto' : 'Editar Producto',
        ),
      ),
      body: controller.userId == null && controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  label: 'Nombre',
                  icon: Icons.fastfood_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: _inputDecoration(
                  label: 'Precio',
                  icon: Icons.attach_money,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el precio';
                  }

                  final price = double.tryParse(value.trim());
                  if (price == null || price < 0) {
                    return 'Ingresa un precio válido';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration(
                  label: 'Descripción',
                  icon: Icons.description_outlined,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ingredientsController,
                decoration: _inputDecoration(
                  label: 'Ingredientes (separados por coma)',
                  icon: Icons.list_alt_outlined,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: _inputDecoration(
                  label: 'Calorías aproximadas',
                  icon: Icons.local_fire_department_outlined,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }

                  final calories = double.tryParse(value.trim());
                  if (calories == null || calories < 0) {
                    return 'Ingresa un valor válido';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: controller.categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : null,
                items: controller.categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: _inputDecoration(
                  label: 'Categoría',
                  icon: Icons.category_outlined,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProductStatus>(
                value: _selectedStatus,
                items: ProductStatus.values
                    .map(
                      (status) => DropdownMenuItem<ProductStatus>(
                    value: status,
                    child: Text(status.displayName),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
                decoration: _inputDecoration(
                  label: 'Estado',
                  icon: Icons.toggle_on_outlined,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.isLoading
                      ? null
                      : controller.pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Seleccionar imagen'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (controller.selectedImageFile != null)
                Text(
                  'Archivo seleccionado: ${controller.selectedImageFile!.path.split('/').last}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (widget.productToEdit?.imageUrl != null &&
                  widget.productToEdit!.imageUrl!.isNotEmpty)
                const Text(
                  'Se mantendrá la imagen actual del producto',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () => _saveProduct(controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.productToEdit == null
                        ? 'Agregar Producto'
                        : 'Actualizar Producto',
                  ),
                ),
              ),
              if (controller.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
              if (controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}