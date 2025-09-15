import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/presentation/pages/create_edit_promotion_page.dart';
import 'package:emprendedor/presentation/pages/create_coupon_page.dart';

// Esta página solo retorna el cuerpo de la vista, sin AppBar ni Scaffold.
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
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Agregar Nueva Promoción'),
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

    return RefreshIndicator(
      onRefresh: () => promotionController.fetchPromotions(),
      child: Stack(
        children: [
          _buildPromotionsList(context, promotionController),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showAddPromotionOptions(context),
              tooltip: 'Crear Promoción',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsList(BuildContext context, PromotionController controller) {
    if (controller.isLoading && controller.promotions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Esta es la lógica clave. Si la lista está vacía, siempre muestra el mensaje amigable.
    // Solo muestra el error si la lista NO está vacía pero hay un error,
    // o si el mensaje de error no está relacionado con los permisos.
    if (controller.promotions.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.discount_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aún no tienes promociones creadas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Pulsa el botón "+" para crear tu primera promoción y empezar a generar cupones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar promociones: ${controller.errorMessage}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: controller.promotions.length,
      itemBuilder: (context, index) {
        final promotion = controller.promotions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: promotion.status == PromotionStatus.active ? Colors.green[100] :
              promotion.status == PromotionStatus.scheduled ? Colors.blue[100] :
              promotion.status == PromotionStatus.expired ? Colors.red[100] :
              Colors.grey[200],
              child: Icon(
                promotion.discountType == DiscountType.percentage ? Icons.percent : Icons.attach_money,
                color: promotion.status == PromotionStatus.active ? Colors.green[700] :
                promotion.status == PromotionStatus.scheduled ? Colors.blue[700] :
                promotion.status == PromotionStatus.expired ? Colors.red[700] :
                Colors.grey[700],
              ),
            ),
            title: Text(promotion.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promotion.description),
                const SizedBox(height: 4),
                Text(
                  'Tipo: ${promotion.discountType.displayName} - Valor: ${promotion.discountValue}${promotion.discountType == DiscountType.percentage ? '%' : ''}',
                ),
                Text(
                  'Válida: ${promotion.startDate.toDate().toLocal().toString().split(' ')[0]} - ${promotion.endDate.toDate().toLocal().toString().split(' ')[0]}',
                ),
                Text('Estado: ${promotion.status.displayName}', style: TextStyle(fontWeight: FontWeight.w500, color: promotion.status == PromotionStatus.active ? Colors.green : Colors.orange)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToEditPromotion(context, promotion);
                } else if (value == 'delete') {
                  _showDeleteConfirmDialog(context, controller, promotion);
                } else if (value == 'create_coupon') {
                  if (promotion.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: ID de promoción no disponible.'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  _navigateToCreateCoupon(context, promotion);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar Promoción')),
                ),
                const PopupMenuItem<String>(
                  value: 'create_coupon',
                  child: ListTile(leading: Icon(Icons.add_card_outlined), title: Text('Crear Cupón')),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Eliminar Promoción', style: TextStyle(color: Colors.red))),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              _navigateToEditPromotion(context, promotion);
            },
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, PromotionController controller, PromotionModel promotion) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Estás seguro de que quieres eliminar la promoción "${promotion.name}"?'),
                const Text('Esta acción no se puede deshacer.'),
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (promotion.id == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: ID de promoción no disponible para eliminar.'), backgroundColor: Colors.red),
                    );
                  }
                  return;
                }
                bool success = await controller.deletePromotion(promotion.id!);
                if (!context.mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Promoción "${promotion.name}" eliminada.'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: ${controller.errorMessage ?? "Error desconocido"}'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}