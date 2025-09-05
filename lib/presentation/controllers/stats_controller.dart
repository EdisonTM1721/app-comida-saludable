import 'package:flutter/material.dart';
import 'package:emprendedor/data/models/stats_model.dart';
import 'package:emprendedor/data/repositories/stats_repository.dart';
import 'package:emprendedor/services/report_exporter_service.dart';
import 'package:logging/logging.dart';

// Clase para el controlador de estadísticas
class StatsController extends ChangeNotifier {
  final Logger _logger = Logger('StatsController');

  // Repositorios y servicios
  final StatsRepository _statsRepository = StatsRepository();
  final ReportExporterService _reportExporterService = ReportExporterService();

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

  // Constructor
  StatsController() {
    final today = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: today.subtract(const Duration(days: 30)),
      end: today,
    );
    fetchStatistics();
  }

  // Métodos para interactuar con la base de datos
  Future<void> fetchStatistics() async {
    _setLoading(true);
    _clearError();
    notifyListeners();
    try {
      _statisticsOverview = await _statsRepository.calculateStatisticsOverview(
        filterStartDate: _selectedDateRange?.start,
        filterEndDate: _selectedDateRange?.end,
      );
      await _calculatePeakSalesHours();
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
    try {
      final allOrders = await _statsRepository.getRelevantOrders(
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

    // Verificar que el formato de exportación sea válido
    _setLoading(true);
    _clearError();
    notifyListeners();

    // Formatear el nombre del archivo según el formato de exportación
    String fileTypeDescription = format.toLowerCase() == 'excel' ? "Excel" : "PDF";

    // Exportar el reporte
    try {
      if (format.toLowerCase() == 'excel') {
        await _reportExporterService.exportToExcel(
            _statisticsOverview!, "reporte_estadisticas_tienda");
      } else if (format.toLowerCase() == 'pdf') {
        await _reportExporterService.exportToPdf(
            _statisticsOverview!, "reporte_estadisticas_tienda");
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