import 'package:flutter_test/flutter_test.dart';

import 'package:emprendedor/data/models/order_model.dart';
import 'package:emprendedor/data/models/stats_model.dart';

void main() {
  group('Order status helpers', () {
    test('stringToOrderStatus handles known and unknown values', () {
      expect(stringToOrderStatus('pending'), OrderStatus.pending);
      expect(stringToOrderStatus('delivered'), OrderStatus.delivered);
      expect(stringToOrderStatus('desconocido'), OrderStatus.pending);
      expect(stringToOrderStatus(null), OrderStatus.pending);
    });

    test('getOrderStatusDisplayString returns readable labels', () {
      expect(
        getOrderStatusDisplayString(OrderStatus.preparing),
        'En Preparación',
      );
      expect(
        getOrderStatusDisplayString(OrderStatus.cancelled),
        'Cancelado',
      );
    });
  });

  test('StatisticsOverview.empty returns empty collections', () {
    final emptyStats = StatisticsOverview.empty();

    expect(emptyStats.dailySales, isEmpty);
    expect(emptyStats.weeklySales, isEmpty);
    expect(emptyStats.monthlySales, isEmpty);
    expect(emptyStats.topProducts, isEmpty);
    expect(emptyStats.frequentCustomers, isEmpty);
  });
}
