import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/product_model.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';

// Nueva página para agregar o editar un producto
class ProductFormPage extends StatefulWidget {
  final ProductModel? productToEdit;

  // Constructor de la nueva página
  const ProductFormPage({super.key, this.productToEdit});

  // Metodo para crear una nueva instancia de la página
  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

// Estado de la nueva página
class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _ingredientsController;
  late TextEditingController _caloriesController;

  // Nueva variable para la categoría
  String? _selectedCategory;
  ProductStatus _selectedStatus = ProductStatus.available;
  String? _currentImageUrl;

  // Lista de categorías predefinidas
  final List<String> _exampleCategories = ['Ensaladas', 'Sopas', 'Sudados', 'Bebidas', 'Postres'];

  // Inicialización del estado
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

    // Si el producto tiene una categoría definida, la agregamos a la lista
    if (widget.productToEdit?.category != null && !_exampleCategories.contains(widget.productToEdit!.category)) {
      _exampleCategories.add(widget.productToEdit!.category);
    }
    if (_selectedCategory == null && _exampleCategories.isNotEmpty) {
      _selectedCategory = _exampleCategories.first;
    }

    // Limpieza del nuevo controlador
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ProductController>(context, listen: false).clearSelectedImage();
      }
    });
  }

  // Limpieza del estado
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  // Metodo para seleccionar una imagen
  Future<void> _pickImage(ImageSource source, ProductController controller) async {
    await controller.pickImage(source);
  }

  // Metodo para enviar el formulario
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría.')),
      );
      return;
    }

    // Obtener los valores del formulario
    _formKey.currentState!.save();

    final productController = Provider.of<ProductController>(context, listen: false);

    // Obtener el valor calórico, asegurando que sea un número válido
    final double? approxCalories = double.tryParse(_caloriesController.text.trim());

    // Crear el producto
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

    // Guardar el producto
    bool success;
    if (widget.productToEdit == null) {
      success = await productController.addProduct(product);
    } else {
      success = await productController.updateProduct(product);
    }

    // Mostrar mensaje de éxito o error
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto ${widget.productToEdit == null ? "agregado" : "actualizado"} con éxito')),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${productController.errorMessage ?? "No se pudo guardar el producto"}')),
      );
    }
  }

  // Construir la página
  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);

    // Si el producto tiene una imagen, la mostramos
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
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (builder) {
                      return SafeArea(
                        child: Wrap(
                          children: <Widget>[
                            ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Galería'),
                                onTap: () {
                                  _pickImage(ImageSource.gallery, Provider.of<ProductController>(context, listen: false));
                                  Navigator.of(context).pop();
                                }),
                            ListTile(
                              leading: const Icon(Icons.photo_camera),
                              title: const Text('Cámara'),
                              onTap: () {
                                _pickImage(ImageSource.camera, Provider.of<ProductController>(context, listen: false));
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Consumer<ProductController>(
                  builder: (context, controller, child) {
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
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
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
                  },
                ),
              ),
              if (productController.selectedImageFile != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                TextButton.icon(
                  icon: const Icon(Icons.clear, color: Colors.redAccent),
                  label: const Text('Quitar Imagen', style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                    productController.clearSelectedImage();
                    setState(() {
                      _currentImageUrl = null;
                    });
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre del producto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingresa un número válido';
                  }
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
              if (_exampleCategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedCategory ?? 'empty_category_key'),
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: _exampleCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona una categoría';
                    }
                    return null;
                  },
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
                key: ValueKey(_selectedStatus),
                initialValue: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                items: ProductStatus.values.map((ProductStatus status) {
                  return DropdownMenuItem<ProductStatus>(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (ProductStatus? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: productController.isLoading
                    ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Icon(Icons.save),
                label: Text(widget.productToEdit == null ? 'Guardar Producto' : 'Actualizar Producto'),
                onPressed: productController.isLoading ? null : _submitForm,
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

  //Metodo para construir una imagen de relleno
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