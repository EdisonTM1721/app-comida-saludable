import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emprendedor/data/models/entrepreneur/stats_model.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/order_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/profile_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/stats_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refreshDashboard(BuildContext context) async {
    await Future.wait([
      context.read<ProfileController>().fetchBusinessProfile(),
      context.read<OrderController>().fetchOrders(),
      context.read<StatsController>().fetchStatistics(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProfileController, OrderController, StatsController>(
      builder: (
        context,
        profileController,
        orderController,
        statsController,
        child,
      ) {
        if (profileController.isLoading && !profileController.hasProfile) {
          return const Center(child: CircularProgressIndicator());
        }

        final userName = profileController.businessProfile?.name;
        final greetingText =
            userName?.isNotEmpty == true ? 'Hola, $userName' : 'Hola, Emprendedor';
        final statisticsOverview =
            statsController.statisticsOverview ?? StatisticsOverview.empty();
        final salesData = statisticsOverview.dailySales;
        final latestSales = salesData.isNotEmpty ? salesData.last : null;
        final topProduct = statisticsOverview.topProducts.isNotEmpty
            ? statisticsOverview.topProducts.first
            : null;
        final currencyFormatter = NumberFormat.currency(
          locale: 'es_ES',
          symbol: '\$',
          decimalDigits: 2,
        );
        final dateFormatter = DateFormat('dd MMM', 'es_ES');
        final visibleTopProducts =
            statisticsOverview.topProducts.take(3).toList(growable: false);

        return RefreshIndicator(
          onRefresh: () => _refreshDashboard(context),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F766E),
                      Color(0xFF14B8A6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greetingText,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revisa ventas, pedidos y productos destacados sin salir del panel principal.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              InfoCard(
                title: 'Ventas del periodo',
                value: currencyFormatter.format(latestSales?.salesAmount ?? 0),
                caption: latestSales != null
                    ? 'Último registro: ${dateFormatter.format(latestSales.date)}'
                    : 'Todavía no hay ventas registradas',
                icon: Icons.attach_money_rounded,
                valueColor: Colors.green.shade700,
              ),
              const SizedBox(height: 16),
              InfoCard(
                title: 'Pedidos activos',
                value: '${orderController.activeOrders}',
                caption: '${orderController.totalPedidos} pedidos totales',
                icon: Icons.receipt_long_rounded,
                valueColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Productos más vendidos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (topProduct == null)
                const _EmptyDashboardCard(
                  icon: Icons.trending_up_rounded,
                  message:
                      'Todavía no hay suficientes pedidos entregados para detectar productos destacados.',
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: visibleTopProducts
                          .asMap()
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                top: entry.key == 0 ? 0 : 12,
                              ),
                              child: _TopProductRow(
                                title: entry.value.productName,
                                subtitle: '${entry.value.quantitySold} vendidos',
                                amount: currencyFormatter
                                    .format(entry.value.totalRevenue),
                                compact: entry.key > 0,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              if (profileController.errorMessage != null ||
                  orderController.errorMessage != null ||
                  statsController.errorMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      profileController.errorMessage ??
                          orderController.errorMessage ??
                          statsController.errorMessage ??
                          '',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color? valueColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              caption,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyDashboardCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool compact;

  const _TopProductRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 36 : 48,
          height: compact ? 36 : 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }
}
