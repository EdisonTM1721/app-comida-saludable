import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:emprendedor/presentation/controllers/entrepreneur/order_controller.dart';
import 'package:emprendedor/presentation/entrepreneur/widgets/order_list_item.dart';

// 👇 NUEVOS IMPORTS
import 'package:emprendedor/presentation/shared/widgets/common/app_empty_state.dart';
import 'package:emprendedor/presentation/shared/widgets/common/app_error_state.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  bool _initialized = false;

  Future<void> _loadOrders() async {
    final controller = context.read<OrderController>();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await controller.setBusinessUserId(user.uid);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OrderController>(
        builder: (context, controller, child) {

          // 🔄 LOADING
          if (controller.isLoading && controller.orders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ❌ ERROR
          if (controller.errorMessage != null &&
              controller.orders.isEmpty) {
            return AppErrorState(
              message: controller.errorMessage!,
              onRetry: _loadOrders,
            );
          }

          // 📭 VACÍO
          if (controller.orders.isEmpty) {
            return RefreshIndicator(
              color: Colors.orange,
              onRefresh: _loadOrders,
              child: const AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Aún no tienes pedidos recibidos.',
                message:
                'Cuando un cliente realice una compra, el pedido aparecerá aquí para que puedas gestionarlo.',
              ),
            );
          }

          // 📋 LISTA
          return RefreshIndicator(
            color: Colors.orange,
            onRefresh: _loadOrders,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: controller.orders.length,
              itemBuilder: (context, index) {
                final order = controller.orders[index];
                return OrderListItem(order: order);
              },
            ),
          );
        },
      ),
    );
  }
}