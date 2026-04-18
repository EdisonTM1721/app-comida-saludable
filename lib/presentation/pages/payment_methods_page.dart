import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emprendedor/data/models/payment_method_model.dart';
import 'package:emprendedor/presentation/controllers/payment_method_controller.dart';

enum NotificationType { success, error, warning, info }

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await context.read<PaymentMethodController>().setUserId(user.uid);
      }
    });
  }

  Future<void> _refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await context.read<PaymentMethodController>().setUserId(user.uid);
      await context.read<PaymentMethodController>().fetchPaymentMethods();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaymentMethodController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (controller.isLoading && controller.paymentMethods.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (controller.errorMessage != null)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(child: Text(controller.errorMessage!)),
                    ],
                  ),
                ),
              )
            else if (controller.paymentMethods.isNotEmpty)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.paymentMethods.length,
                      itemBuilder: (context, index) {
                        final item = controller.paymentMethods[index];
                        IconData icon;
                        switch (item.name) {
                          case 'Efectivo':
                            icon = Icons.money;
                            break;
                          case 'Tarjeta de Crédito':
                            icon = Icons.credit_card;
                            break;
                          case 'Tarjeta de Débito':
                            icon = Icons.credit_card_outlined;
                            break;
                          case 'Transferencia Bancaria':
                            icon = Icons.account_balance;
                            break;
                          case 'PayPal':
                            icon = Icons.payment;
                            break;
                          default:
                            icon = Icons.public;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(icon, color: Colors.teal),
                            title: Text(item.name),
                            subtitle: Text(_formatDetails(item.details)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _editPaymentMethod(context, controller, index);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    controller.deletePaymentMethod(item.id!);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      children: const [
                        SizedBox(height: 160),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aún no tienes métodos de pago creados.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Pulsa el botón "+" para crear tu primer método de pago y empezar a gestionar tus pagos.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, controller),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions(BuildContext context, PaymentMethodController controller) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.money, color: Colors.green),
                title: const Text('Efectivo'),
                onTap: () {
                  controller.addPaymentMethod(PaymentMethodModel(name: 'Efectivo'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('Tarjeta de Crédito'),
                onTap: () {
                  controller.addPaymentMethod(
                    PaymentMethodModel(name: 'Tarjeta de Crédito'),
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card_outlined, color: Colors.blueGrey),
                title: const Text('Tarjeta de Débito'),
                onTap: () {
                  controller.addPaymentMethod(
                    PaymentMethodModel(name: 'Tarjeta de Débito'),
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.teal),
                title: const Text('Transferencia Bancaria'),
                onTap: () {
                  controller.addPaymentMethod(
                    PaymentMethodModel(
                      name: 'Transferencia Bancaria',
                      details: {},
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.indigo),
                title: const Text('PayPal'),
                onTap: () {
                  controller.addPaymentMethod(PaymentMethodModel(name: 'PayPal'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editPaymentMethod(
      BuildContext context,
      PaymentMethodController controller,
      int index,
      ) {
    final item = controller.paymentMethods[index];
    if (item.name == 'Transferencia Bancaria') {
      _editBankTransferDetails(context, controller, item);
    } else {
      final TextEditingController detailsController =
      TextEditingController(text: item.details ?? '');
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Editar detalles de ${item.name}'),
            content: TextField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: 'Detalles adicionales',
                hintText: 'Ej: solo pagos mayores a \$5',
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () {
                  final updatedItem = item.copyWith(details: detailsController.text);
                  controller.updatePaymentMethod(updatedItem);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _editBankTransferDetails(
      BuildContext context,
      PaymentMethodController controller,
      PaymentMethodModel item,
      ) {
    final Map<String, dynamic> currentData =
    item.details is Map ? item.details : {};
    final TextEditingController bankNameController =
    TextEditingController(text: currentData['banco'] ?? '');
    final TextEditingController accountNumberController =
    TextEditingController(text: currentData['numero_cuenta'] ?? '');
    final TextEditingController idCardController =
    TextEditingController(text: currentData['cedula'] ?? '');
    final TextEditingController emailController =
    TextEditingController(text: currentData['correo'] ?? '');
    final TextEditingController ownerNameController =
    TextEditingController(text: currentData['propietario'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Detalles de Transferencia Bancaria'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ownerNameController,
                  decoration: const InputDecoration(labelText: 'Nombre del titular'),
                ),
                TextField(
                  controller: bankNameController,
                  decoration: const InputDecoration(labelText: 'Nombre del Banco'),
                ),
                TextField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(labelText: 'Número de Cuenta'),
                ),
                TextField(
                  controller: idCardController,
                  decoration: const InputDecoration(labelText: 'Cédula'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                final updatedDetails = {
                  'propietario': ownerNameController.text,
                  'banco': bankNameController.text,
                  'numero_cuenta': accountNumberController.text,
                  'cedula': idCardController.text,
                  'correo': emailController.text,
                };
                final updatedItem = item.copyWith(details: updatedDetails);
                controller.updatePaymentMethod(updatedItem);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDetails(dynamic details) {
    if (details is Map) {
      String formatted = '';
      details.forEach((key, value) {
        if (value.isNotEmpty) {
          final formattedKey = key.toString().replaceAll('_', ' ');
          formatted +=
          '${formattedKey[0].toUpperCase()}${formattedKey.substring(1)}: $value\n';
        }
      });
      return formatted.trim();
    }
    return details ?? 'Añadir detalles';
  }
}