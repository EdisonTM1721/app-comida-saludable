import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/data/models/entrepreneur/stats_model.dart';
import 'package:emprendedor/data/models/entrepreneur/product_model.dart';
import 'package:emprendedor/data/models/entrepreneur/promotion_model.dart';
import 'package:emprendedor/data/repositories/entrepreneur/stats_repository.dart';
import 'package:emprendedor/data/repositories/entrepreneur/product_repository.dart';
import 'package:emprendedor/data/repositories/entrepreneur/promotion_repository.dart';
import 'package:emprendedor/data/services/report_exporter_service.dart';

// Definición de la clase StatsController
class StatsController extends ChangeNotifier {
  final Logger _logger = Logger('StatsController');

  // Repositorios y servicios
  final StatsRepository _statsRepository = StatsRepository();
  final ProductRepository _productRepository = ProductRepository();
  final PromotionRepository _promotionRepository = PromotionRepository();
  final ReportExporterService _reportExporterService = ReportExporterService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Datos de estadísticas
  StatisticsOverview? _statisticsOverview;
  StatisticsOverview? get statisticsOverview => _statisticsOverview;

  // Estado de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Mensaje de error
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filtros de fecha y intervalo de ventas
  DateTimeRange? _selectedDateRange;
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  // Intervalo de ventas
  SalesInterval _selectedSalesInterval = SalesInterval.daily;
  SalesInterval get selectedSalesInterval => _selectedSalesInterval;

  // Horarios de mayor venta
  Map<int, int> _peakSalesHours = {};
  Map<int, int> get peakSalesHours => _peakSalesHours;

  // Productos más vendidos
  List<ProductModel> _topProducts = [];
  List<ProductModel> get topProducts => _topProducts;

  // Promociones
  List<PromotionModel> _promotions = [];
  List<PromotionModel> get promotions => _promotions;

  StreamSubscription? _promotionsSubscription;

  String? _userId;

  // Constructor ligero
  StatsController();

  // Método para inicializar el controlador
  Future<void> setUserId(String? userId) async {
    if (userId == null || userId == _userId) {
      return;
    }
    _userId = userId;
    final today = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: today.subtract(const Duration(days: 30)),
      end: today,
    );
    await fetchStatistics();
    _fetchPromotions();
  }

  // Lógica para manejar el deslogueo
  void disposeController() {
    _userId = null;
    _statisticsOverview = StatisticsOverview.empty();
    _peakSalesHours = {};
    _topProducts = [];
    _promotions = [];
    _promotionsSubscription?.cancel();
    notifyListeners();
  }

  // Getter para los datos de ventas actuales
  List<SalesDataPoint> get currentSalesData {
    if (_statisticsOverview == null) {
      return [];
    }
    switch (_selectedSalesInterval) {
      case SalesInterval.daily:
        return _statisticsOverview!.dailySales;
      case SalesInterval.weekly:
        return _statisticsOverview!.weeklySales;
      case SalesInterval.monthly:
        return _statisticsOverview!.monthlySales;
    }
  }

  // Métodos para interactuar con la base de datos
  Future<void> fetchStatistics() async {
    if (_userId == null) {
      _setError("El ID de usuario no está disponible.");
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _statisticsOverview = await _statsRepository.calculateStatisticsOverview(
        userId: _userId!,
        filterStartDate: _selectedDateRange?.start,
        filterEndDate: _selectedDateRange?.end,
      );
      await _calculatePeakSalesHours();
      await _fetchTopProducts();
    } catch (e, stackTrace) {
      _logger.severe('Error al cargar estadísticas', e, stackTrace);
      _setError("Error al calcular estadísticas: ${e.toString()}");
      _statisticsOverview = StatisticsOverview.empty();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Métodos para interactuar con la base de datos
  Future<void> _calculatePeakSalesHours() async {
    if (_userId == null) return;

    try {
      final allOrders = await _statsRepository.getRelevantOrders(
        userId: _userId!,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );
      final Map<int, int> salesByHour = {};
      for (var order in allOrders) {
        final hour = order.createdAt.toDate().hour;
        salesByHour[hour] = (salesByHour[hour] ?? 0) + 1;
      }
      _peakSalesHours = salesByHour;
    } catch (e, stackTrace) {
      _logger.severe("Error al calcular horarios de mayor venta", e, stackTrace);
      _peakSalesHours = {};
    }
  }

  // Métodos para interactuar con la base de datos
  Future<void> _fetchTopProducts() async {
    if (_statisticsOverview == null || _statisticsOverview!.topProducts.isEmpty) {
      _topProducts = [];
      return;
    }

    final topProductIds = _statisticsOverview!.topProducts.map((p) => p.productId).toList();
    _topProducts = await _productRepository.getProductsByIds(topProductIds, _userId!);
  }

  // Métodos para interactuar con la base de datos
  void _fetchPromotions() {
    if (_userId == null) return;
    _promotionsSubscription?.cancel();
    _promotionsSubscription = _promotionRepository.getPromotions(_userId!).listen((promotions) {
      _promotions = promotions;
      notifyListeners();
    }, onError: (e, stackTrace) {
      _logger.severe("Error al cargar promociones", e, stackTrace);
    });
  }

  // Métodos para interactuar con la interfaz de usuario
  void setSelectedDateRange(DateTimeRange? range) {
    if (range != null && range != _selectedDateRange) {
      _selectedDateRange = range;
      notifyListeners();
      fetchStatistics();
    }
  }

  // Métodos para interactuar con la interfaz de usuario
  void setSelectedSalesInterval(SalesInterval interval) {
    if (interval != _selectedSalesInterval) {
      _selectedSalesInterval = interval;
      notifyListeners();
    }
  }

  // Métodos para interactuar con la interfaz de usuario
  Future<void> exportReport(String format) async {
    if (_statisticsOverview == null ||
        (_statisticsOverview!.dailySales.isEmpty &&
            _statisticsOverview!.topProducts.isEmpty &&
            _statisticsOverview!.frequentCustomers.isEmpty)) {
      _setError("No hay datos disponibles para exportar.");
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    String fileTypeDescription = format.toLowerCase() == 'excel' ? "Excel" : "PDF";

    try {
      if (format.toLowerCase() == 'excel') {
        await _reportExporterService.exportToExcel(_statisticsOverview!, "reporte_estadisticas_tienda");
      } else if (format.toLowerCase() == 'pdf') {
        await _reportExporterService.exportToPdf(_statisticsOverview!, "reporte_estadisticas_tienda");
      } else {
        throw Exception("Formato de exportación no soportado: $format");
      }
      _logger.info("Reporte $fileTypeDescription solicitado. El servicio de exportación gestionará la apertura/compartición.");
    } catch (e, stackTrace) {
      _logger.severe('Error durante la exportación del reporte $fileTypeDescription', e, stackTrace);
      _setError("Error al exportar reporte $fileTypeDescription: ${e.toString()}");
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Métodos para interactuar con la interfaz de usuario
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
  }

  // Métodos para interactuar con la interfaz de usuario
  void _setError(String? message) {
    _errorMessage = message;
  }

  // Métodos para interactuar con la interfaz de usuario
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }
}