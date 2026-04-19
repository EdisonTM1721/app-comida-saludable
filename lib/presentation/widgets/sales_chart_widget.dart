import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/data/models/stats_model.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/stats_controller.dart';

// Nueva clase para el widget de gráfico de ventas
class SalesChartWidget extends StatelessWidget {
  const SalesChartWidget({super.key});

  // Metodo para construir el widget de gráfico de ventas
  @override
  Widget build(BuildContext context) {
    final statsController = Provider.of<StatsController>(context);
    final salesData = statsController.currentSalesData;
    final interval = statsController.selectedSalesInterval;

    // Si no hay datos de ventas, mostrar un mensaje
    if (salesData.isEmpty) {
      return const Center(child: Text("No hay datos de ventas para mostrar en el gráfico."));
    }

    // Encontrar el valor máximo de ventas para el eje Y
    double maxY = salesData.map((d) => d.salesAmount).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 100;

    // Ajustar el ancho del gráfico según el intervalo de ventas
    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (BarChartGroupData group) {
                  // Usar withAlpha para colores sRGB
                  return Colors.blueGrey.withAlpha((255 * 0.9).round());
                },
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                tooltipBorder: const BorderSide(color: Colors.white, width: 1),
                // Formato personalizado del tooltip
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final dataPoint = salesData[groupIndex];
                  String title;
                  if (interval == SalesInterval.daily) {
                    title = DateFormat('d MMM', 'es_ES').format(dataPoint.date);
                  } else if (interval == SalesInterval.weekly) {
                    title = DateFormat('d MMM yy', 'es_ES').format(dataPoint.date);
                  } else { // monthly
                    title = DateFormat('MMM yyyy', 'es_ES').format(dataPoint.date);
                  }
                  return BarTooltipItem(
                    '$title\n',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    children: <TextSpan>[
                      TextSpan(
                        text: NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 2).format(dataPoint.salesAmount),
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= salesData.length) {
                      return const SizedBox.shrink();
                    }
                    final dataPoint = salesData[index];
                    String text;
                    if (interval == SalesInterval.daily) {
                      text = DateFormat('d', 'es_ES').format(dataPoint.date);
                    } else if (interval == SalesInterval.weekly) {
                      text = "S${DateFormat('w', 'es_ES').format(dataPoint.date)}";
                    } else { // monthly
                      text = DateFormat('MMM', 'es_ES').format(dataPoint.date).substring(0,3);
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 10)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) {
                    final numTicks = maxY < 500 ? 3 : 5;
                    if (value == 0 || value == maxY || (value % (maxY / numTicks).ceilToDouble()) == 0 ) {
                      if (value == 0 && maxY < 100) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          NumberFormat.compactCurrency(locale: 'es_ES', symbol: '\$', decimalDigits: 0).format(value),
                          style: const TextStyle(color: Colors.black54, fontSize: 10),
                          textAlign: TextAlign.left,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: salesData.asMap().entries.map((entry) {
              final index = entry.key;
              final dataPoint = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: dataPoint.salesAmount,
                    // Usar withAlpha para colores sRGB
                    color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.8).round()),
                    width: interval == SalesInterval.daily ? 16 : (interval == SalesInterval.weekly ? 20 : 24),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 5,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Colors.black12,
                  strokeWidth: 0.8,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
