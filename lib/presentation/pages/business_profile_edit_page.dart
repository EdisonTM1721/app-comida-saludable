import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:emprendedor/data/models/business_profile_model.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('BusinessProfileEditPage');

enum NotificationType { success, error, warning, info }

class BusinessProfileEditPage extends StatefulWidget {
  const BusinessProfileEditPage({super.key});

  @override
  State<BusinessProfileEditPage> createState() => _BusinessProfileEditPageState();
}

class _BusinessProfileEditPageState extends State<BusinessProfileEditPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _openingHoursController;
  // Controladores para los nuevos campos de redes sociales
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;

  File? _selectedImageFile;
  bool _isSaving = false;

  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _openingHoursController = TextEditingController();
    // Inicialización de los nuevos controladores
    _facebookController = TextEditingController();
    _instagramController = TextEditingController();
    _twitterController = TextEditingController();

    final profileController = Provider.of<ProfileController>(context, listen: false);
    final profile = profileController.businessProfile;
    if (profile != null) {
      _nameController.text = profile.name;
      _descriptionController.text = profile.description ?? '';
      _addressController.text = profile.address ?? '';
      _openingHoursController.text = profile.openingHours ?? '';
      _paymentMethods = _getPaymentMethodsList(profile.paymentMethods);

      // Cargar los datos de redes sociales si existen
      if (profile.socialMediaLinks != null) {
        try {
          final Map<String, dynamic> socialMedia = json.decode(profile.socialMediaLinks!);
          _facebookController.text = socialMedia['facebook'] ?? '';
          _instagramController.text = socialMedia['instagram'] ?? '';
          _twitterController.text = socialMedia['twitter'] ?? '';
        } catch (e) {
          _logger.severe('Error al decodificar enlaces de redes sociales: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _openingHoursController.dispose();
    // Liberar los nuevos controladores
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _showCustomNotification({
    required BuildContext context,
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (!mounted) return;

    IconData iconData;
    Color backgroundColor;
    Color iconColor = Colors.white;
    switch (type) {
      case NotificationType.success:
        iconData = Icons.check_circle_outline;
        backgroundColor = Colors.green.shade600;
        break;
      case NotificationType.error:
        iconData = Icons.error_outline;
        backgroundColor = Colors.red.shade600;
        break;
      case NotificationType.warning:
        iconData = Icons.warning_amber_outlined;
        backgroundColor = Colors.orange.shade600;
        break;
      case NotificationType.info:
        iconData = Icons.info_outline;
        backgroundColor = Colors.blue.shade600;
        break;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 48, color: iconColor),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
    await Future.delayed(duration);
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile({bool migratingPaymentMethods = false}) async {
    if (!mounted) return;
    final currentContext = context;
    if (!migratingPaymentMethods && _formKey.currentState?.validate() != true) {
      return;
    }
    setState(() => _isSaving = true);

    final profileController = Provider.of<ProfileController>(currentContext, listen: false);
    final user = _auth.currentUser;
    BusinessProfileModel? currentProfile = profileController.businessProfile;

    if (user == null) {
      if (mounted) {
        _showCustomNotification(
          context: currentContext,
          message: 'Error: Usuario no autenticado.',
          type: NotificationType.error,
          duration: const Duration(seconds: 4),
        );
        setState(() => _isSaving = false);
      }
      return;
    }

    final Map<String, String> socialMediaLinks = {
      'facebook': _facebookController.text.trim(),
      'instagram': _instagramController.text.trim(),
      'twitter': _twitterController.text.trim(),
    };

    final profileDataToSave = (currentProfile ?? BusinessProfileModel(userId: user.uid, name: ''))
        .copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      openingHours: _openingHoursController.text.trim().isEmpty ? null : _openingHoursController.text.trim(),
      paymentMethods: json.encode(_paymentMethods),
      socialMediaLinks: json.encode(socialMediaLinks),
    );

    bool success = await profileController.saveProfile(
      profileDataToSave,
      imageFile: _selectedImageFile,
    );
    if (!mounted) return;

    if (success) {
      _showCustomNotification(
        context: currentContext,
        message: 'Perfil actualizado con éxito',
        type: NotificationType.success,
      );
      setState(() {
        _selectedImageFile = null;
      });
      Navigator.of(currentContext).pop(true);
    } else {
      _showCustomNotification(
        context: currentContext,
        message: 'Error al actualizar el perfil: ${profileController.errorMessage ?? "Intente de nuevo."}',
        type: NotificationType.error,
        duration: const Duration(seconds: 4),
      );
    }
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<bool> _updatePaymentMethods() async {
    if (!mounted) return false;
    final currentContext = context;
    setState(() => _isSaving = true);

    final profileController = Provider.of<ProfileController>(currentContext, listen: false);
    final currentProfile = profileController.businessProfile;

    if (currentProfile == null) {
      if (mounted) { setState(() => _isSaving = false); }
      return false;
    }

    final updatedProfile = currentProfile.copyWith(
      paymentMethods: json.encode(_paymentMethods),
    );

    bool success = await profileController.saveProfile(updatedProfile, imageFile: null);
    if (!mounted) return false;

    if (mounted) { setState(() => _isSaving = false); }
    return success;
  }

  Future<void> _addPaymentMethod() async {
    if (!mounted) return;
    final currentAddMethodContext = context;

    String? selectedMethodName = await showDialog<String>(
      context: currentAddMethodContext,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Añadir método de pago'),
          children: <Widget>[
            SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, 'Efectivo'), child: const ListTile(leading: Icon(Icons.money_outlined, color: Colors.green), title: Text('Efectivo'))),
            SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, 'Tarjeta de Crédito'), child: const ListTile(leading: Icon(Icons.credit_card_outlined, color: Colors.blue), title: Text('Tarjeta de Crédito'))),
            SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, 'Tarjeta de Débito'), child: const ListTile(leading: Icon(Icons.credit_score_outlined, color: Colors.lightBlue), title: Text('Tarjeta de Débito'))),
            SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, 'PayPal'), child: const ListTile(leading: Icon(Icons.paypal_outlined, color: Colors.blueAccent), title: Text('PayPal'))),
            SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, 'Transferencia Bancaria'), child: const ListTile(leading: Icon(Icons.account_balance_outlined, color: Colors.orange), title: Text('Transferencia Bancaria'))),
            SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, 'Pago móvil'), child: const ListTile(leading: Icon(Icons.phone_android_outlined, color: Colors.purple), title: Text('Pago móvil'))),
          ],
        );
      },
    );

    if (!mounted) return;
    if (selectedMethodName != null) {
      final profileController = Provider.of<ProfileController>(currentAddMethodContext, listen: false);

      if (!_paymentMethods.any((method) => method['name'] == selectedMethodName)) {
        setState(() {
          _paymentMethods.add({'name': selectedMethodName, 'details': <String, dynamic>{}});
        });

        bool success = await _updatePaymentMethods();
        if (!mounted) return;

        if (success) {
          _showCustomNotification(
            context: currentAddMethodContext,
            message: '"$selectedMethodName" añadido con éxito.',
            type: NotificationType.success,
          );
        } else {
          _showCustomNotification(
            context: currentAddMethodContext,
            message: 'Error al añadir "$selectedMethodName". ${profileController.errorMessage ?? "Intente de nuevo."}',
            type: NotificationType.error,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        _showCustomNotification(
          context: currentAddMethodContext,
          message: 'El método "$selectedMethodName" ya existe.',
          type: NotificationType.warning,
        );
      }
    }
  }

  Future<void> _editPaymentMethod(Map<String, dynamic> methodToEdit) async {
    if (!mounted) return;
    final String name = methodToEdit['name'] as String;
    final Map<String, dynamic> details = (methodToEdit['details'] is Map<String, dynamic>)
        ? methodToEdit['details'] as Map<String, dynamic>
        : <String, dynamic>{};

    final accountController = TextEditingController(text: details['account'] as String? ?? '');
    final bankController = TextEditingController(text: details['bank'] as String? ?? '');
    final genericDetailController = TextEditingController(text: details['generic'] as String? ?? '');
    final paypalEmailController = TextEditingController(text: details['paypalEmail'] as String? ?? '');

    final currentEditMethodContext = context;

    final bool? saved = await showDialog<bool>(
      context: currentEditMethodContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Configurar "$name"'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name == 'PayPal')
                  TextFormField(
                    controller: paypalEmailController,
                    decoration: const InputDecoration(labelText: 'Correo electrónico de PayPal'),
                    keyboardType: TextInputType.emailAddress,
                  )
                else if (name == 'Transferencia Bancaria' || name == 'Pago móvil')
                  Column(
                    children: [
                      TextFormField(
                        controller: bankController,
                        decoration: const InputDecoration(labelText: 'Nombre del Banco'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: accountController,
                        decoration: InputDecoration(labelText: name == 'Pago móvil' ? 'Número de Teléfono/CI' : 'Número de Cuenta'),
                      ),
                    ],
                  )
                else
                  TextFormField(
                    controller: genericDetailController,
                    decoration: const InputDecoration(labelText: 'Detalles (opcional)'),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      accountController.dispose();
      bankController.dispose();
      genericDetailController.dispose();
      paypalEmailController.dispose();
      return;
    }

    if (saved == true) {
      final profileController = Provider.of<ProfileController>(currentEditMethodContext, listen: false);
      final index = _paymentMethods.indexWhere((m) => m['name'] == name);

      if (index != -1) {
        Map<String, String> newDetailsMap = {};
        if (name == 'Transferencia Bancaria' || name == 'Pago móvil') {
          if (bankController.text.trim().isNotEmpty) newDetailsMap['bank'] = bankController.text.trim();
          if (accountController.text.trim().isNotEmpty) newDetailsMap['account'] = accountController.text.trim();
        } else if (name == 'PayPal') {
          if (paypalEmailController.text.trim().isNotEmpty) newDetailsMap['paypalEmail'] = paypalEmailController.text.trim();
        } else {
          if (genericDetailController.text.trim().isNotEmpty) newDetailsMap['generic'] = genericDetailController.text.trim();
        }

        setState(() {
          _paymentMethods[index]['details'] = newDetailsMap;
        });

        bool success = await _updatePaymentMethods();
        if (!mounted) return;

        if (success) {
          _showCustomNotification(
            context: currentEditMethodContext,
            message: 'Detalles de "$name" actualizados con éxito.',
            type: NotificationType.success,
          );
        } else {
          _showCustomNotification(
            context: currentEditMethodContext,
            message: 'Error al actualizar detalles de "$name". ${profileController.errorMessage ?? "" }',
            type: NotificationType.error,
            duration: const Duration(seconds: 4),
          );
        }
      }
    }

    accountController.dispose();
    bankController.dispose();
    genericDetailController.dispose();
    paypalEmailController.dispose();
  }

  Future<void> _confirmDeleteMethod(Map<String, dynamic> methodToDelete) async {
    if (!mounted) return;
    final currentConfirmContext = context;
    final String methodName = methodToDelete['name'] as String? ?? 'el método';

    final confirmed = await showDialog<bool>(
      context: currentConfirmContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar método de pago'),
          content: Text('¿Estás seguro de que quieres eliminar "$methodName"?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar')
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirmed == true) {
      final profileController = Provider.of<ProfileController>(currentConfirmContext, listen: false);

      setState(() {
        _paymentMethods.removeWhere((m) => m['name'] == methodToDelete['name']);
      });

      bool success = await _updatePaymentMethods();
      if (!mounted) return;

      if(success) {
        _showCustomNotification(
          context: currentConfirmContext,
          message: '"$methodName" eliminado con éxito.',
          type: NotificationType.info,
        );
      } else {
        _showCustomNotification(
          context: currentConfirmContext,
          message: 'Error al eliminar "$methodName". ${profileController.errorMessage ?? "" }',
          type: NotificationType.error,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getPaymentMethodsList(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return decoded.map((item) {
          if (item is Map<String, dynamic>) {
            item['details'] = (item['details'] is Map<String, dynamic>)
                ? item['details'] as Map<String, dynamic>
                : <String, dynamic>{};
            return item;
          }
          return null;
        }).whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      if (jsonString.trim() != "[]" && !jsonString.trim().startsWith("[")) {
        final oldMethods = jsonString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (oldMethods.isNotEmpty) {
          final newMethodsList = oldMethods.map((e) => {'name': e, 'details': <String, dynamic>{}}).toList();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _saveProfile(migratingPaymentMethods: true);
            }
          });
          return newMethodsList;
        }
      }
      _logger.severe('Error al decodificar métodos de pago: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil de Negocio'),
      ),
      body: Consumer<ProfileController>(
        builder: (context, profileController, child) {
          final profile = profileController.businessProfile;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && profile != null) {
              if (_nameController.text != profile.name) {
                _nameController.text = profile.name;
              }
              if (_descriptionController.text != (profile.description ?? '')) {
                _descriptionController.text = profile.description ?? '';
              }
              if (_addressController.text != (profile.address ?? '')) {
                _addressController.text = profile.address ?? '';
              }
              if (_openingHoursController.text != (profile.openingHours ?? '')) {
                _openingHoursController.text = profile.openingHours ?? '';
              }
            }
          });

          if (profileController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!)
                                : (profile?.profileImageUrl != null && profile!.profileImageUrl!.isNotEmpty
                                ? NetworkImage(profile.profileImageUrl!)
                                : null) as ImageProvider?,
                            child: (profile?.profileImageUrl == null || profile!.profileImageUrl!.isEmpty) && _selectedImageFile == null
                                ? Icon(Icons.business_outlined, size: 80, color: Colors.grey[600])
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColorLight.withAlpha(229),
                              radius: 22,
                              child: Icon(Icons.camera_alt_outlined, color: Theme.of(context).primaryColorDark, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Negocio', prefixIcon: Icon(Icons.store_outlined)),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa el nombre de tu negocio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Descripción', prefixIcon: Icon(Icons.description_outlined)),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _openingHoursController,
                    decoration: const InputDecoration(labelText: 'Horarios de Atención', prefixIcon: Icon(Icons.access_time_outlined)),
                  ),
                  const SizedBox(height: 24),
                  // Seccion de Redes Sociales añadida
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Redes Sociales', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _facebookController,
                            decoration: const InputDecoration(labelText: 'Facebook URL', prefixIcon: Icon(Icons.facebook)),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _instagramController,
                            decoration: const InputDecoration(labelText: 'Instagram URL', prefixIcon: Icon(Icons.camera_outlined)),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _twitterController,
                            decoration: const InputDecoration(labelText: 'Twitter URL', prefixIcon: Icon(Icons.alternate_email)), // No hay un icono nativo de Twitter, se usa uno genérico
                            keyboardType: TextInputType.url,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Métodos de Pago Aceptados', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          if (_paymentMethods.isNotEmpty)
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _paymentMethods.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                              itemBuilder: (context, index) {
                                final method = _paymentMethods[index];
                                final name = method['name'] as String? ?? 'Desconocido';
                                final detailsMap = method['details'] as Map<String, dynamic>? ?? {};
                                String detailText = 'Configurar detalles';
                                IconData leadingIcon = Icons.payment_outlined;

                                if (name == 'Efectivo') {
                                  leadingIcon = Icons.money_outlined;
                                  detailText = detailsMap['generic']?.isNotEmpty == true ? detailsMap['generic']! : 'Aceptado';
                                } else if (name == 'Tarjeta de Crédito') {
                                  leadingIcon = Icons.credit_card_outlined;
                                  detailText = detailsMap['generic']?.isNotEmpty == true ? detailsMap['generic']! : 'Aceptada';
                                } else if (name == 'Tarjeta de Débito') {
                                  leadingIcon = Icons.credit_score_outlined;
                                  detailText = detailsMap['generic']?.isNotEmpty == true ? detailsMap['generic']! : 'Aceptada';
                                } else if (name == 'PayPal') {
                                  leadingIcon = Icons.paypal_outlined;
                                  detailText = detailsMap['paypalEmail']?.isNotEmpty == true ? "Email: ${detailsMap['paypalEmail']!}" : 'Configurar Email de PayPal';
                                } else if (name == 'Transferencia Bancaria') {
                                  leadingIcon = Icons.account_balance_outlined;
                                  detailText = detailsMap['bank']?.isNotEmpty == true
                                      ? "Banco: ${detailsMap['bank']!}, Cta: ${detailsMap['account'] ?? 'N/A'}"
                                      : 'Configurar detalles bancarios';
                                } else if (name == 'Pago móvil') {
                                  leadingIcon = Icons.phone_android_outlined;
                                  detailText = detailsMap['bank']?.isNotEmpty == true
                                      ? "Banco: ${detailsMap['bank']!}, Telf/CI: ${detailsMap['account'] ?? 'N/A'}"
                                      : 'Configurar detalles de pago móvil';
                                } else {
                                  detailText = detailsMap['generic']?.isNotEmpty == true ? detailsMap['generic']! : 'Detalles no configurados';
                                }

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
                                  leading: Icon(leadingIcon, color: Theme.of(context).primaryColor, size: 28),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: Text(detailText, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, color: Colors.blueGrey[700], size: 22),
                                        onPressed: () => _editPaymentMethod(method),
                                        tooltip: 'Editar detalles de $name',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.redAccent[400], size: 22),
                                        onPressed: () => _confirmDeleteMethod(method),
                                        tooltip: 'Eliminar $name',
                                      ),
                                    ],
                                  ),
                                  onTap: () => _editPaymentMethod(method),
                                );
                              },
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                              child: Center(
                                child: Text(
                                  'Aún no has añadido métodos de pago.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _addPaymentMethod,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Añadir Nuevo Método'),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_alt_outlined),
                    label: Text(_isSaving ? 'Guardando Cambios...' : 'Guardar Cambios del Perfil'),
                    onPressed: _isSaving ? null : () => _saveProfile(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
