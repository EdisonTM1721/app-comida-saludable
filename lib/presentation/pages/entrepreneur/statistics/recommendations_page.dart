import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Página de recomendaciones
class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key});


  // Construye el widget
  @override
  Widget build(BuildContext context) {

    final List<BarChartGroupData> barGroups = [

      // Ejemplo de datos: ventas por hora
      BarChartGroupData(x: 10, barRods: [BarChartRodData(toY: 50)]),
      BarChartGroupData(x: 11, barRods: [BarChartRodData(toY: 75)]),
      BarChartGroupData(x: 12, barRods: [BarChartRodData(toY: 90)]),
    ];

    // Puedes personalizar el gráfico según tus necesidades
    return Scaffold(
      appBar: AppBar(
        title: Text('Horarios de Mayor Venta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consulta las mejores horas para aplicar promociones.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}