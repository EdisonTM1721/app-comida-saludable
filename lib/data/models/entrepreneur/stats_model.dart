import 'package:cloud_firestore/cloud_firestore.dart';

// Clase para representar un modelo de ventas
enum SalesInterval { daily, weekly, monthly }

// Clase para representar un punto de datos de ventas
class SalesDataPoint {
  final DateTime date;
  final double salesAmount;
  final int orderCount;

  // Constructor de la clase
  SalesDataPoint({required this.date, required this.salesAmount, required this.orderCount});
}

// Clase para representar un producto más vendido
class TopProductStat {
  final String productId;
  final String productName;
  final String? productImageUrl;
  final int quantitySold;
  final double totalRevenue;

  // Constructor de la clase
  TopProductStat({
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.quantitySold,
    required this.totalRevenue,
  });
}

// Clase para representar un cliente frecuente
class FrequentCustomerStat {
  final String customerId;
  final String customerName;
  final String? customerEmail;
  final int totalOrders;
  final double totalSpent;

  // Constructor de la clase
  FrequentCustomerStat({
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    required this.totalOrders,
    required this.totalSpent,
  });
}

// Clase para representar un resumen de estadísticas
class StatisticsOverview {
  final List<SalesDataPoint> dailySales;
  final List<SalesDataPoint> weeklySales;
  final List<SalesDataPoint> monthlySales;
  final List<TopProductStat> topProducts;
  final List<FrequentCustomerStat> frequentCustomers;
  final Timestamp lastCalculated;

  // Constructor de la clase
  StatisticsOverview({
    required this.dailySales,
    required this.weeklySales,
    required this.monthlySales,
    required this.topProducts,
    required this.frequentCustomers,
    required this.lastCalculated,
  });

  // Factory constructor para crear una instancia vacía
  factory StatisticsOverview.empty() {
    return StatisticsOverview(
      dailySales: [],
      weeklySales: [],
      monthlySales: [],
      topProducts: [],
      frequentCustomers: [],
      lastCalculated: Timestamp.now(),
    );
  }
}