import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/stats_model.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/stats_controller.dart';
import 'package:emprendedor/presentation/widgets/sales_chart_widget.dart';
import 'package:emprendedor/presentation/widgets/top_items_list_widget.dart';
import 'package:emprendedor/presentation/widgets/common/app_empty_state.dart';
import 'package:emprendedor/presentation/widgets/common/app_error_state.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final statsController = Provider.of<StatsController>(context);

    return Scaffold(
      body: Builder(
        builder: (BuildContext scaffoldContext) {
          final overview = statsController.statisticsOverview;

          if (statsController.isLoading && overview == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (statsController.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(
                  content: Text('Error: ${statsController.errorMessage}'),
                  backgroundColor: Colors.red,
                ),
              );
            });
          }

// ❌ ERROR (opcional más visual)
          if (statsController.errorMessage != null && overview == null) {
            return AppErrorState(
              message: statsController.errorMessage!,
              onRetry: () => statsController.fetchStatistics(),
            );
          }

// 📭 VACÍO
          if (overview == null ||
              (overview.dailySales.isEmpty && overview.topProducts.isEmpty)) {
            return AppEmptyState(
              icon: Icons.bar_chart,
              title: 'Aún no tienes estadísticas disponibles.',
              message:
              'Las ventas y pedidos aparecerán aquí cuando comiences a recibir pedidos.',
              action: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
                onPressed: () => statsController.fetchStatistics(),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateRangePicker(context, statsController),
                const SizedBox(height: 16),
                _buildIntervalSelector(context, statsController),
                const SizedBox(height: 8),
                const Text(
                  'Ventas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SalesChartWidget(),
                const SizedBox(height: 24),
                PeakHoursWidget(statsController: statsController),
                const SizedBox(height: 24),
                TopItemsListWidget<TopProductStat>(
                  title: 'Productos Más Vendidos',
                  items: overview.topProducts,
                  type: TopListType.products,
                  itemBuilder: (context, product) {
                    return ListTile(
                      leading: product.productImageUrl != null &&
                          product.productImageUrl!.isNotEmpty
                          ? SizedBox(
                        width: 40,
                        height: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            product.productImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                          ),
                        ),
                      )
                          : const Icon(Icons.fastfood, size: 30),
                      title: Text(
                        product.productName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('Vendidos: ${product.quantitySold}'),
                      trailing: Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 2,
                          locale: 'es_ES',
                        ).format(product.totalRevenue),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TopItemsListWidget<FrequentCustomerStat>(
                  title: 'Clientes Frecuentes',
                  items: overview.frequentCustomers,
                  type: TopListType.customers,
                  itemBuilder: (context, customer) {
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          customer.customerName.isNotEmpty
                              ? customer.customerName[0].toUpperCase()
                              : 'C',
                        ),
                      ),
                      title: Text(
                        customer.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('Pedidos: ${customer.totalOrders}'),
                      trailing: Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 2,
                          locale: 'es_ES',
                        ).format(customer.totalSpent),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Último cálculo: ${DateFormat('dd MMM yyyy, hh:mm a', 'es_ES').format(overview.lastCalculated.toDate())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangePicker(
      BuildContext context,
      StatsController controller,
      ) {
    final range = controller.selectedDateRange;
    String rangeText = 'Seleccionar Rango de Fechas';

    if (range != null) {
      rangeText =
      "${DateFormat('dd/MM/yy', 'es_ES').format(range.start)} - ${DateFormat('dd/MM/yy', 'es_ES').format(range.end)}";
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.date_range, color: Colors.teal),
        title: const Text(
          'Rango de Fechas para Estadísticas',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(rangeText),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context,
            initialDateRange:
            controller.selectedDateRange ??
                DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                ),
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 1)),
            locale: const Locale('es', 'ES'),
          );

          if (picked != null) {
            controller.setSelectedDateRange(picked);
          }
        },
      ),
    );
  }

  Widget _buildIntervalSelector(
      BuildContext context,
      StatsController controller,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Intervalo del Gráfico de Ventas:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            SegmentedButton<SalesInterval>(
              segments: const <ButtonSegment<SalesInterval>>[
                ButtonSegment<SalesInterval>(
                  value: SalesInterval.daily,
                  label: Text('Diario'),
                  icon: Icon(Icons.calendar_view_day),
                ),
                ButtonSegment<SalesInterval>(
                  value: SalesInterval.weekly,
                  label: Text('Semanal'),
                  icon: Icon(Icons.calendar_view_week),
                ),
                ButtonSegment<SalesInterval>(
                  value: SalesInterval.monthly,
                  label: Text('Mensual'),
                  icon: Icon(Icons.calendar_month),
                ),
              ],
              selected: <SalesInterval>{controller.selectedSalesInterval},
              onSelectionChanged: (Set<SalesInterval> newSelection) {
                controller.setSelectedSalesInterval(newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.teal.withValues(alpha: 0.2),
                selectedForegroundColor: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PeakHoursWidget extends StatelessWidget {
  final StatsController statsController;

  const PeakHoursWidget({
    super.key,
    required this.statsController,
  });

  @override
  Widget build(BuildContext context) {
    final peakHours = statsController.peakSalesHours;

    if (peakHours.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedHours = peakHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3Hours = sortedHours.take(3);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recomendaciones: Horarios de Mayor Venta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aprovecha para promocionar tus productos o lanzar ofertas en estas horas para maximizar tus ventas.',
            ),
            const SizedBox(height: 16),
            ...top3Hours.map((entry) {
              final hour = entry.key;
              final salesCount = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      '$hour:00 - ${hour + 1}:00',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Pedidos: $salesCount',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}