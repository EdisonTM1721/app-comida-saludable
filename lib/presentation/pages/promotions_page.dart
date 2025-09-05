import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/presentation/pages/create_edit_promotion_page.dart';
import 'create_coupon_page.dart';

// Nueva clase para la lista de promociones
class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key});

  // Metodo para navegar a la página de creación o edición de una promoción
  void _navigateToCreatePromotion(BuildContext context, {PromotionModel? promotionToEdit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEditPromotionPage(promotionToEdit: promotionToEdit),
      ),
    );
  }

  // Metodo para navegar a la página de creación de un cupón
  void _navigateToCreateCoupon(BuildContext context, String promotionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateCouponPage(promotionId: promotionId),
      ),
    );
  }

  // Metodo para mostrar el panel de opciones de agregar promoción
  void _showAddPromotionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            color: Colors.transparent,
            child: Wrap(
              children: <Widget>[
                // Barra de agarre para indicar que es deslizable (opcional)
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
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const Text('Agregar Nueva Promoción'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _navigateToCreatePromotion(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Construye la lista de promociones
  @override
  Widget build(BuildContext context) {
    final promotionController = Provider.of<PromotionController>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => promotionController.fetchPromotions(),
        child: _buildPromotionsList(context, promotionController),
      ),
      // CAMBIO: Se usa FloatingActionButton.small() para un botón más pequeño
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showAddPromotionOptions(context),
        tooltip: 'Crear Promoción',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Construye la lista de promociones
  Widget _buildPromotionsList(BuildContext context, PromotionController controller) {
    if (controller.isLoading && controller.promotions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // Si no hay promociones, muestra un mensaje
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
                  _navigateToCreatePromotion(context, promotionToEdit: promotion);
                } else if (value == 'delete') {
                  _showDeleteConfirmDialog(context, controller, promotion);
                } else if (value == 'create_coupon') {
                  if (promotion.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: ID de promoción no disponible.'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  _navigateToCreateCoupon(context, promotion.id!);
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
              _navigateToCreatePromotion(context, promotionToEdit: promotion);
            },
          ),
        );
      },
    );
  }

  // Muestra un diálogo de confirmación para eliminar una promoción
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
                const Text('Esta acción no se puede deshacer y también eliminará los cupones asociados (si la lógica del backend lo maneja).'),
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
                bool success = await controller.deletePromotion(promotion.id!);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Promoción "${promotion.name}" eliminada.'), backgroundColor: Colors.green),
                  );
                } else if (context.mounted) {
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