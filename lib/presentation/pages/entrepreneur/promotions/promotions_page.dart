import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/promotion_controller.dart';
import 'package:emprendedor/data/models/promotion_model.dart';
import 'package:emprendedor/presentation/pages/entrepreneur/promotions/create_edit_promotion_page.dart';
import 'package:emprendedor/presentation/pages/entrepreneur/promotions/create_coupon_page.dart';
import 'package:emprendedor/presentation/widgets/common/app_empty_state.dart';
import 'package:emprendedor/presentation/widgets/common/app_error_state.dart';
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
                  leading: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                  title: const Text(
                    'Agregar Nueva Promoción',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
    final controller = Provider.of<PromotionController>(context);

    return Scaffold(
      body: RefreshIndicator(
        color: Colors.green,
        onRefresh: () => controller.fetchPromotions(),
        child: _buildPromotionsList(context, controller),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showAddPromotionOptions(context),
        tooltip: 'Crear Promoción',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPromotionsList(
      BuildContext context,
      PromotionController controller,
      ) {
    // 🔄 LOADING
    if (controller.isLoading && controller.promotions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // ❌ ERROR (usando widget global)
    if (controller.errorMessage != null) {
      return AppErrorState(
        message: controller.errorMessage!,
        onRetry: controller.fetchPromotions,
      );
    }

    // 📭 VACÍO (usando widget global)
    if (controller.promotions.isEmpty) {
      return const AppEmptyState(
        icon: Icons.discount_outlined,
        title: 'Aún no tienes promociones',
        message:
        'Crea promociones para atraer clientes y aumentar tus ventas.',
      );
    }

    // 📋 LISTA
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.2),
              child: Icon(
                promotion.discountType == DiscountType.percentage
                    ? Icons.percent
                    : Icons.attach_money,
                color: statusColor,
              ),
            ),
            title: Text(
              promotion.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(promotion.description),
                const SizedBox(height: 4),
                Text(
                  'Tipo: ${promotion.discountType.displayName} - Valor: ${promotion.discountValue}${promotion.discountType == DiscountType.percentage ? '%' : ''}',
                ),
                Text(
                  'Estado: ${promotion.status.displayName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
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
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar'),
                ),
                PopupMenuItem(
                  value: 'create_coupon',
                  child: Text('Crear Cupón'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar'),
                ),
              ],
            ),
            onTap: () => _navigateToEditPromotion(context, promotion),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(
      BuildContext context,
      PromotionController controller,
      PromotionModel promotion,
      ) async {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Promoción'),
          content: Text('¿Seguro que deseas eliminar "${promotion.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (promotion.id == null) return;

                final success =
                await controller.deletePromotion(promotion.id!);

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Promoción eliminada'
                          : 'Error: ${controller.errorMessage}',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}