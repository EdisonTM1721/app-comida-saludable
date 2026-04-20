import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:emprendedor/core/constants/app_constants.dart';
import 'package:emprendedor/data/models/shared/order_model.dart';
import 'package:emprendedor/data/models/entrepreneur/stats_model.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

// Clase para el repositorio de estadísticas
class StatsRepository {
  final Logger _logger = Logger('StatsRepository');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener pedidos relevantes para estadísticas
  Future<List<OrderModel>> getRelevantOrders({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: orderStatusToString(OrderStatus.delivered));

    // Aplicar filtros si se proporcionan
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      DateTime adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(adjustedEndDate));
    }

    // Obtener los pedidos relevantes
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
  }

  // Calcular estadísticas de ventas
  Future<StatisticsOverview> calculateStatisticsOverview({
    required String userId,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) async {
    final defaultStartDate = filterStartDate ?? DateTime.now().subtract(const Duration(days: 90));
    final defaultEndDate = filterEndDate ?? DateTime.now();

    // Obtener los pedidos relevantes para calcular las estadísticas
    final orders = await getRelevantOrders(userId: userId, startDate: defaultStartDate, endDate: defaultEndDate);

    // Verificar si hay pedidos para calcular las estadísticas
    if (orders.isEmpty) {
      _logger.info("No hay pedidos relevantes para calcular estadísticas en el rango dado.");
      return StatisticsOverview.empty();
    }

    // Calcular las estadísticas
    final dailySales = _calculateDailySales(orders);
    final weeklySales = _calculateWeeklySales(orders, defaultStartDate, defaultEndDate);
    final monthlySales = _calculateMonthlySales(orders, defaultStartDate, defaultEndDate);
    final topProducts = _calculateTopProducts(orders, limit: 5);
    final frequentCustomers = _calculateFrequentCustomers(orders, limit: 5);

    // Actualizar la última fecha de cálculo
    _logger.fine("Estadísticas calculadas exitosamente.");

    // Devolver las estadísticas calculadas
    return StatisticsOverview(
      dailySales: dailySales,
      weeklySales: weeklySales,
      monthlySales: monthlySales,
      topProducts: topProducts,
      frequentCustomers: frequentCustomers,
      lastCalculated: Timestamp.now(),
    );
  }

  // Calcular las estadísticas de ventas diarias
  List<SalesDataPoint> _calculateDailySales(List<OrderModel> orders) {
    if (orders.isEmpty) return [];
    final salesByDay = groupBy<OrderModel, DateTime>(
      orders,
          (order) {
        final date = order.createdAt.toDate();
        return DateTime(date.year, date.month, date.day);
      },
    );
    return salesByDay.entries.map((entry) {
      final date = entry.key;
      final dailyOrders = entry.value;
      final totalAmount = dailyOrders.sumByDouble((order) => order.totalPrice);
      return SalesDataPoint(date: date, salesAmount: totalAmount, orderCount: dailyOrders.length);
    }).sorted((a, b) => a.date.compareTo(b.date));
  }

  // Calcular las estadísticas de ventas semanales y mensuales
  List<SalesDataPoint> _calculateWeeklySales(List<OrderModel> orders, DateTime overallStartDate, DateTime overallEndDate) {
    if (orders.isEmpty) return [];
    final salesByWeekday = groupBy<OrderModel, int>(
      orders,
          (order) => order.createdAt.toDate().weekday,
    );
    final List<SalesDataPoint> result = [];
    final today = DateTime.now();
    for (int i = 1; i <= 7; i++) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: today.weekday - i));
      final weeklyOrders = salesByWeekday[i] ?? [];
      final totalAmount = weeklyOrders.sumByDouble((order) => order.totalPrice);
      result.add(SalesDataPoint(
        date: day,
        salesAmount: totalAmount,
        orderCount: weeklyOrders.length,
      ));
    }
    return result;
  }

  // Calcular las estadísticas de ventas mensuales
  List<SalesDataPoint> _calculateMonthlySales(List<OrderModel> orders, DateTime overallStartDate, DateTime overallEndDate) {
    if (orders.isEmpty) return [];
    final salesByMonth = groupBy<OrderModel, String>(
      orders,
          (order) => DateFormat('yyyy-MM', 'es_ES').format(order.createdAt.toDate()),
    );
    return salesByMonth.entries.map((entry) {
      final monthKey = entry.key;
      final monthlyOrders = entry.value;
      final totalAmount = monthlyOrders.sumByDouble((order) => order.totalPrice);
      final date = DateTime.parse('$monthKey-01');
      return SalesDataPoint(date: date, salesAmount: totalAmount, orderCount: monthlyOrders.length);
    }).sorted((a, b) => a.date.compareTo(b.date));
  }

  // Calcular los productos más vendidos y los clientes frecuentes
  List<TopProductStat> _calculateTopProducts(List<OrderModel> orders, {int limit = 5}) {
    if (orders.isEmpty) return [];
    final Map<String, TopProductStat> productStats = {};
    for (var order in orders) {
      for (var item in order.items) {
        productStats.update(
          item.productId,
              (existing) => TopProductStat(
            productId: existing.productId,
            productName: existing.productName,
            productImageUrl: existing.productImageUrl,
            quantitySold: existing.quantitySold + item.quantity,
            totalRevenue: existing.totalRevenue + (item.quantity * item.priceAtPurchase),
          ),
          ifAbsent: () => TopProductStat(
            productId: item.productId,
            productName: item.productName,
            productImageUrl: item.imageUrl,
            quantitySold: item.quantity,
            totalRevenue: (item.quantity * item.priceAtPurchase),
          ),
        );
      }
    }
    var sortedProducts = productStats.values.toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    return sortedProducts.take(limit).toList();
  }

  // Calcular los clientes frecuentes
  List<FrequentCustomerStat> _calculateFrequentCustomers(List<OrderModel> orders, {int limit = 5}) {
    if (orders.isEmpty) return [];
    final Map<String, FrequentCustomerStat> customerStats = {};
    for (var order in orders) {
      customerStats.update(
        order.userId,
            (existing) => FrequentCustomerStat(
          customerId: existing.customerId,
          customerName: existing.customerName,
          customerEmail: existing.customerEmail,
          totalOrders: existing.totalOrders + 1,
          totalSpent: existing.totalSpent + order.totalPrice,
        ),
        ifAbsent: () => FrequentCustomerStat(
          customerId: order.userId,
          customerName: order.customerInfo.name,
          customerEmail: order.customerInfo.email,
          totalOrders: 1,
          totalSpent: order.totalPrice,
        ),
      );
    }
    var sortedCustomers = customerStats.values.toList()
      ..sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
    return sortedCustomers.take(limit).toList();
  }
}

// Extensión para sumar valores de un iterable
extension SumByDouble<T> on Iterable<T> {
  double sumByDouble(double Function(T element) selector) {
    return fold(0.0, (previousValue, element) => previousValue + selector(element));
  }
}
