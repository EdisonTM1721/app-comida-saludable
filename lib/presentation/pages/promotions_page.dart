import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/presentation/pages/create_edit_promotion_page.dart';
import 'package:emprendedor/presentation/pages/create_coupon_page.dart';

class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key});

  void _navigateToEditPromotion(BuildContext context, PromotionModel promotion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEditPromotionPage(promotionToEdit: promotion),
      ),
    );
  }

  void _navigateToCreatePromotion(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateEditPromotionPage(promotionToEdit: null),
      ),
    );
  }

  void _navigateToCreateCoupon(BuildContext context, PromotionModel promotion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateCouponPage(promotion: promotion),
      ),
    );
  }

  void _showAddPromotionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Wrap(
              children: <Widget>[
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                  title: const Text('Agregar Nueva Promoción', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToCreatePromotion(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final promotionController = Provider.of<PromotionController>(context);

    return Scaffold(
      body: RefreshIndicator(
        color: Colors.green,
        onRefresh: () => promotionController.fetchPromotions(),
        child: _buildPromotionsList(context, promotionController),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPromotionOptions(context),
        backgroundColor: Colors.green[700],
        tooltip: 'Crear Promoción',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPromotionsList(BuildContext context, PromotionController controller) {
    if (controller.isLoading && controller.promotions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Mensaje de error o permiso denegado
    if (controller.errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Algo salió mal',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mensaje cuando no hay promociones
    if (controller.promotions.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.discount_outlined, size: 80, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Aún no tienes promociones',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                SizedBox(height: 8),
                Text(
                  'Pulsa el botón "+" para crear tu primera promoción y empezar a generar cupones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Lista de promociones
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: controller.promotions.length,
      itemBuilder: (context, index) {
        final promotion = controller.promotions[index];

        Color statusColor;
        switch (promotion.status) {
          case PromotionStatus.active:
            statusColor = Colors.green;
            break;
          case PromotionStatus.scheduled:
            statusColor = Colors.blue;
            break;
          case PromotionStatus.expired:
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.grey;
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.2),
              child: Icon(
                promotion.discountType == DiscountType.percentage ? Icons.percent : Icons.attach_money,
                color: statusColor,
              ),
            ),
            title: Text(
              promotion.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(promotion.description),
                const SizedBox(height: 4),
                Text(
                  'Tipo: ${promotion.discountType.displayName} - Valor: ${promotion.discountValue}${promotion.discountType == DiscountType.percentage ? '%' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Válida: ${promotion.startDate.toDate().toLocal().toString().split(' ')[0]} - ${promotion.endDate.toDate().toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Estado: ${promotion.status.displayName}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: statusColor),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToEditPromotion(context, promotion);
                } else if (value == 'delete') {
                  _showDeleteConfirmDialog(context, controller, promotion);
                } else if (value == 'create_coupon') {
                  if (promotion.id == null) return;
                  _navigateToCreateCoupon(context, promotion);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar Promoción'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'create_coupon',
                  child: ListTile(
                    leading: Icon(Icons.add_card_outlined),
                    title: Text('Crear Cupón'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Eliminar Promoción', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _navigateToEditPromotion(context, promotion),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(
      BuildContext context, PromotionController controller, PromotionModel promotion) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Seguro que deseas eliminar "${promotion.name}"?'),
                const Text('Esta acción no se puede deshacer.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (promotion.id == null) return;
                bool success = await controller.deletePromotion(promotion.id!);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Promoción "${promotion.name}" eliminada.'
                        : 'Error al eliminar: ${controller.errorMessage ?? "Error desconocido"}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
