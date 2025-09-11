import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';

class ProductFormPage extends StatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormPage({super.key, this.productToEdit});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _ingredientsController;
  late TextEditingController _caloriesController;

  String? _selectedCategory;
  ProductStatus _selectedStatus = ProductStatus.available;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productToEdit?.name ?? '');
    _priceController = TextEditingController(text: widget.productToEdit?.price.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.productToEdit?.description ?? '');
    _ingredientsController = TextEditingController(text: widget.productToEdit?.ingredients.join(', ') ?? '');
    _caloriesController = TextEditingController(text: widget.productToEdit?.approxCalories?.toString() ?? '');

    _selectedCategory = widget.productToEdit?.category;
    _selectedStatus = widget.productToEdit?.status ?? ProductStatus.available;
    _currentImageUrl = widget.productToEdit?.imageUrl;

    // Esta llamada es segura porque `context` ya tiene acceso al Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductController>().clearSelectedImage();
      }
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

  Future<void> _pickImage(ImageSource source) async {
    await context.read<ProductController>().pickImage(source);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Aquí validamos que se haya seleccionado una categoría
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría.')),
      );
      return;
    }

    _formKey.currentState!.save();
    final double? approxCalories = double.tryParse(_caloriesController.text.trim());

    final product = ProductModel(
      id: widget.productToEdit?.id,
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      status: _selectedStatus,
      ingredients: _ingredientsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      imageUrl: _currentImageUrl,
      isFeatured: widget.productToEdit?.isFeatured ?? false,
      approxCalories: approxCalories,
    );

    final productController = context.read<ProductController>();
    bool success;
    if (widget.productToEdit == null) {
      success = await productController.addProduct(product);
    } else {
      success = await productController.updateProduct(product);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Producto ${widget.productToEdit == null ? "agregado" : "actualizado"} con éxito' : 'Error: ${productController.errorMessage ?? "No se pudo guardar el producto"}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductController>();
    final categories = controller.categories;

    // Si `_selectedCategory` es nulo, le asignamos la primera categoría disponible
    // Esto evita el error de que el `value` no coincida con un `item`
    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productToEdit == null ? 'Agregar Producto' : 'Editar Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Galería'),
                          onTap: () {
                            _pickImage(ImageSource.gallery);
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_camera),
                          title: const Text('Cámara'),
                          onTap: () {
                            _pickImage(ImageSource.camera);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                child: _buildImageWidget(controller),
              ),
              if (controller.selectedImageFile != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                TextButton.icon(
                  icon: const Icon(Icons.clear, color: Colors.redAccent),
                  label: const Text('Quitar Imagen', style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                    controller.clearSelectedImage();
                    setState(() => _currentImageUrl = null);
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Por favor ingresa el nombre del producto' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor ingresa el precio';
                  if (double.tryParse(value) == null) return 'Por favor ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Valor Calórico (kcal)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              if (categories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                  validator: (value) => value == null || value.isEmpty ? 'Por favor selecciona una categoría' : null,
                )
              else
                const Text('No hay categorías disponibles. Agrega una o define algunas.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Ingredientes (separados por coma)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Tomate, Lechuga, Queso',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProductStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                items: ProductStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status.displayName))).toList(),
                onChanged: (status) {
                  if (status != null) setState(() => _selectedStatus = status);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: controller.isLoading
                    ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Icon(Icons.save),
                label: Text(widget.productToEdit == null ? 'Guardar Producto' : 'Actualizar Producto'),
                onPressed: controller.isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(ProductController controller) {
    Widget imageWidget;
    if (controller.selectedImageFile != null) {
      imageWidget = Image.file(
        controller.selectedImageFile!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        _currentImageUrl!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    } else {
      imageWidget = _buildImagePlaceholder();
    }
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.0),
        child: imageWidget,
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('Toca para agregar imagen', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}