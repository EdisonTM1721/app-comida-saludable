import 'package:flutter/material.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final List<Map<String, dynamic>> _paymentMethods = [
    // La lista inicia vacía para que solo se muestren los métodos agregados por el usuario.
  ];

  void _addPaymentMethod(String methodName) {
    setState(() {
      _paymentMethods.add({'name': methodName, 'details': ''});
    });
  }

  void _showAddOptions(BuildContext context) {
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
                  _addPaymentMethod('Efectivo');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('Tarjeta de Crédito'),
                onTap: () {
                  _addPaymentMethod('Tarjeta de Crédito');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card_outlined, color: Colors.blueGrey),
                title: const Text('Tarjeta de Débito'),
                onTap: () {
                  _addPaymentMethod('Tarjeta de Débito');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.teal),
                title: const Text('Transferencia Bancaria'),
                onTap: () {
                  _addPaymentMethod('Transferencia Bancaria');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.indigo),
                title: const Text('PayPal'),
                onTap: () {
                  _addPaymentMethod('PayPal');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editPaymentMethod(int index, String currentDetails) {
    if (_paymentMethods[index]['name'] == 'Transferencia Bancaria') {
      _editBankTransferDetails(index);
    } else {
      final TextEditingController detailsController = TextEditingController(text: currentDetails);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Editar detalles de ${_paymentMethods[index]['name']}'),
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
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () {
                  setState(() {
                    _paymentMethods[index]['details'] = detailsController.text;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _editBankTransferDetails(int index) {
    final Map<String, dynamic> currentData = _paymentMethods[index]['details'] is Map ? _paymentMethods[index]['details'] : {};
    final TextEditingController bankNameController = TextEditingController(text: currentData['banco'] ?? '');
    final TextEditingController accountNumberController = TextEditingController(text: currentData['numero_cuenta'] ?? '');
    final TextEditingController idCardController = TextEditingController(text: currentData['cedula'] ?? '');
    final TextEditingController emailController = TextEditingController(text: currentData['correo'] ?? '');
    final TextEditingController ownerNameController = TextEditingController(text: currentData['propietario'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                setState(() {
                  _paymentMethods[index]['details'] = {
                    'propietario': ownerNameController.text,
                    'banco': bankNameController.text,
                    'numero_cuenta': accountNumberController.text,
                    'cedula': idCardController.text,
                    'correo': emailController.text,
                  };
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deletePaymentMethod(int index) {
    setState(() {
      _paymentMethods.removeAt(index);
    });
  }

  String _formatDetails(dynamic details) {
    if (details is Map) {
      String formatted = '';
      details.forEach((key, value) {
        if (value.isNotEmpty) {
          formatted += '${key.toString().replaceAll('_', ' ')}: $value\n';
        }
      });
      return formatted.trim();
    }
    return details ?? 'Añadir detalles';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_paymentMethods.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final item = _paymentMethods[index];
                    IconData icon;
                    switch (item['name']) {
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
                        title: Text(item['name']),
                        subtitle: Text(_formatDetails(item['details'])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editPaymentMethod(index, item['details'] ?? '');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deletePaymentMethod(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'Aquí se gestionarán los métodos de pago',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddOptions(context),
              icon: const Icon(Icons.add),
              label: const Text('Añadir Método de Pago'),
            ),
          ],
        ),
      ),
    );
  }
}
