import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/stats_model.dart';
import 'package:emprendedor/presentation/controllers/stats_controller.dart';
import 'package:emprendedor/presentation/widgets/sales_chart_widget.dart';
import 'package:emprendedor/presentation/widgets/top_items_list_widget.dart';

// Nueva clase para la página de estadísticas
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  // Método para construir la página de estadísticas
  @override
  Widget build(BuildContext context) {
    final statsController = Provider.of<StatsController>(context);
    final statsOverview = statsController.statisticsOverview;

    return Scaffold(

      // Barra de navegación
      body: Builder(
        builder: (BuildContext scaffoldContext) {
          if (statsController.isLoading && statsOverview == null) {
            return const Center(child: CircularProgressIndicator());
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
          if (statsOverview == null || (statsOverview.dailySales.isEmpty && statsOverview.topProducts.isEmpty)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay datos suficientes para mostrar estadísticas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Intentar Recargar'),
                      onPressed: () => statsController.fetchStatistics(),
                    )
                  ],
                ),
              ),
            );
          }

          // Contenido de la página
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateRangePicker(context, statsController),
                const SizedBox(height: 16),
                _buildIntervalSelector(context, statsController),
                const SizedBox(height: 8),
                const Text('Ventas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SalesChartWidget(),
                const SizedBox(height: 24),

                // widget para los horarios de mayor venta
                PeakHoursWidget(statsController: statsController),
                const SizedBox(height: 24),

                TopItemsListWidget<TopProductStat>(
                  title: 'Productos Más Vendidos',
                  items: statsOverview.topProducts,
                  type: TopListType.products,
                  itemBuilder: (context, product) {
                    return ListTile(
                      leading: product.productImageUrl != null && product.productImageUrl!.isNotEmpty
                          ? SizedBox(width: 40, height: 40, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(product.productImageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported))))
                          : const Icon(Icons.fastfood, size: 30),
                      title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('Vendidos: ${product.quantitySold}'),
                      trailing: Text(
                        NumberFormat.currency(symbol: '\$', decimalDigits: 2, locale: 'es_ES').format(product.totalRevenue),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                TopItemsListWidget<FrequentCustomerStat>(
                  title: 'Clientes Frecuentes',
                  items: statsOverview.frequentCustomers,
                  type: TopListType.customers,
                  itemBuilder: (context, customer) {
                    return ListTile(
                      leading: CircleAvatar(child: Text(customer.customerName.isNotEmpty ? customer.customerName[0].toUpperCase() : 'C')),
                      title: Text(customer.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('Pedidos: ${customer.totalOrders}'),
                      trailing: Text(
                          NumberFormat.currency(symbol: '\$', decimalDigits: 2, locale: 'es_ES').format(customer.totalSpent),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Último cálculo: ${DateFormat('dd MMM yyyy, hh:mm a', 'es_ES').format(statsOverview.lastCalculated.toDate())}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Método para construir el selector de rango de fechas
  Widget _buildDateRangePicker(BuildContext context, StatsController controller) {
    final range = controller.selectedDateRange;
    String rangeText = "Seleccionar Rango de Fechas";
    if (range != null) {
      rangeText = "${DateFormat('dd/MM/yy', 'es_ES').format(range.start)} - ${DateFormat('dd/MM/yy', 'es_ES').format(range.end)}";
    }

    // Muestra el selector de rango de fechas
    return Card(
      child: ListTile(
        leading: const Icon(Icons.date_range, color: Colors.teal),
        title: const Text('Rango de Fechas para Estadísticas', style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(rangeText),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context,
            initialDateRange: controller.selectedDateRange ?? DateTimeRange(
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

  // Método para construir el selector de intervalo de tiempo
  Widget _buildIntervalSelector(BuildContext context, StatsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Intervalo del Gráfico de Ventas:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            SegmentedButton<SalesInterval>(
              segments: const <ButtonSegment<SalesInterval>>[
                ButtonSegment<SalesInterval>(value: SalesInterval.daily, label: Text('Diario'), icon: Icon(Icons.calendar_view_day)),
                ButtonSegment<SalesInterval>(value: SalesInterval.weekly, label: Text('Semanal'), icon: Icon(Icons.calendar_view_week)),
                ButtonSegment<SalesInterval>(value: SalesInterval.monthly, label: Text('Mensual'), icon: Icon(Icons.calendar_month)),
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

// Nueva clase para el widget de recomendaciones
class PeakHoursWidget extends StatelessWidget {
  final StatsController statsController;

  // Constructor
  const PeakHoursWidget({super.key, required this.statsController});

  // Método para construir el widget
  @override
  Widget build(BuildContext context) {
    final peakHours = statsController.peakSalesHours;
    if (peakHours.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ordena las horas por ventas en orden descendente
    final sortedHours = peakHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Toma las 3 horas más vendidas
    final top3Hours = sortedHours.take(3);

    // Muestra las recomendaciones
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
            const Text('Aprovecha para promocionar tus productos o lanzar ofertas en estas horas para maximizar tus ventas.'),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      'Pedidos: $salesCount',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}