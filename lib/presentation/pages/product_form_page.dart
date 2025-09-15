import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

// Formulario para agregar o editar un producto
class ProductFormPage extends StatefulWidget {
  final ProductModel? productToEdit;

  // Construye el widget
  const ProductFormPage({super.key, this.productToEdit});

  // Estado del widget
  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

// Estado del widget
class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _ingredientsController;
  late TextEditingController _caloriesController;

  String? _selectedCategory;
  ProductStatus _selectedStatus = ProductStatus.available;

  bool _loadingUser = true;

  // Inicialización de controladores en initState
  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.productToEdit?.name ?? '');
    _priceController = TextEditingController(
        text: widget.productToEdit?.price.toStringAsFixed(2) ?? '');
    _descriptionController = TextEditingController(text: widget.productToEdit?.description ?? '');
    _ingredientsController = TextEditingController(
        text: widget.productToEdit?.ingredients.join(', ') ?? '');
    _caloriesController = TextEditingController(
        text: widget.productToEdit?.approxCalories?.toStringAsFixed(0) ?? '');

    _selectedCategory = widget.productToEdit?.category;
    _selectedStatus = widget.productToEdit?.status ?? ProductStatus.available;

    // Limpiar imagen seleccionada y establecer userId
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productController = Provider.of<ProductController>(context, listen: false);
      productController.clearSelectedImage();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await productController.setUserId(user.uid);
      } else {
        // No hay usuario autenticado
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay usuario autenticado')),
          );
        }
      }

      if (mounted) {
        setState(() {
          _loadingUser = false;
        });
      }
    });
  }

  // Limpieza de controladores en dispose
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  // Abre la galería para seleccionar una imagen
  Future<void> _pickImage() async {
    final productController = Provider.of<ProductController>(context, listen: false);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      productController.setSelectedImage(File(pickedFile.path));
    }
  }

  // Guarda el producto
  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final productController = Provider.of<ProductController>(context, listen: false);

    final double? price = double.tryParse(_priceController.text);
    final double? calories = double.tryParse(_caloriesController.text);

    final product = ProductModel(
      id: widget.productToEdit?.id,
      name: _nameController.text,
      price: price ?? 0.0,
      description: _descriptionController.text,
      category: _selectedCategory ?? 'Todas',
      ingredients: _ingredientsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      status: _selectedStatus,
      approxCalories: calories,
      isFeatured: widget.productToEdit?.isFeatured ?? false,
      userId: productController.userId,
    );

    final success = widget.productToEdit == null
        ? await productController.addProduct(product)
        : await productController.updateProduct(product);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  // Construye el widget
  @override
  Widget build(BuildContext context) {
    final productController = context.watch<ProductController>();

    if (_loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Muestra el formulario
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productToEdit == null ? 'Agregar Producto' : 'Editar Producto'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(labelText: 'Ingredientes'),
              ),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calorías aproximadas'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: productController.categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Seleccionar Imagen'),
              ),
              const SizedBox(height: 8),
              if (productController.selectedImageFile != null)
                Text(
                  'Archivo seleccionado: ${productController.selectedImageFile!.path.split('/').last}',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(widget.productToEdit == null
                    ? 'Agregar Producto'
                    : 'Actualizar Producto'),
              ),
              if (productController.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
              if (productController.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    productController.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
