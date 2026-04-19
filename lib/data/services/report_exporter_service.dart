import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:emprendedor/data/models/stats_model.dart';

// Nueva clase para el servicio de exportación de Excel
class ReportExporterService {
  final String _locale = 'es_ES';

  // Método para exportar a Excel
  Future<String?> exportToExcel(StatisticsOverview statsOverview, String fileNamePrefix) async {
    if (statsOverview.dailySales.isEmpty &&
        statsOverview.topProducts.isEmpty &&
        statsOverview.frequentCustomers.isEmpty) {
      throw Exception("No hay datos para exportar a Excel.");
    }

    // Crear un archivo Excel
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Estadisticas_Tienda'];

    // Estilo para las celdas
    CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('FFEEEEEE'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Variables para controlar la posición de las celdas|
    int currentRow = 0;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
        TextCellValue("Reporte de Estadísticas");
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
    currentRow++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
        TextCellValue("Generado: ${DateFormat('dd MMM yyyy, hh:mm a', _locale).format(DateTime.now())}");
    currentRow += 2;

    if (statsOverview.dailySales.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue("Ventas Diarias");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = headerStyle;
      currentRow++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue("Fecha");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
          TextCellValue("Monto Ventas");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value =
          TextCellValue("Núm. Pedidos");
      for (int i = 0; i < 3; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).cellStyle = headerStyle;
      }
      currentRow++;

      // Agregar las ventas diarias
      for (final sale in statsOverview.dailySales) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
            TextCellValue(DateFormat('dd/MM/yyyy', _locale).format(sale.date));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
            DoubleCellValue(sale.salesAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value =
            IntCellValue(sale.orderCount);
        currentRow++;
      }
      currentRow += 2;
    }

    if (statsOverview.topProducts.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue("Productos Más Vendidos");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = headerStyle;
      currentRow++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue("Producto");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
          TextCellValue("Cantidad Vendida");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value =
          TextCellValue("Ingresos Generados");
      for (int i = 0; i < 3; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).cellStyle = headerStyle;
      }
      currentRow++;

      // Agregar los productos más vendidos
      for (final product in statsOverview.topProducts) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
            TextCellValue(product.productName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
            IntCellValue(product.quantitySold);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value =
            DoubleCellValue(product.totalRevenue);
        currentRow++;
      }
      currentRow += 2;
    }

    if (statsOverview.frequentCustomers.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue("Clientes Frecuentes");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = headerStyle;
      currentRow++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue("Cliente");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
          TextCellValue("Total Pedidos");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value =
          TextCellValue("Total Gastado");
      for (int i = 0; i < 3; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).cellStyle = headerStyle;
      }
      currentRow++;

      // Agregar los clientes frecuentes
      for (final customer in statsOverview.frequentCustomers) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
            TextCellValue(customer.customerName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
            IntCellValue(customer.totalOrders);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value =
            DoubleCellValue(customer.totalSpent);
        currentRow++;
      }
    }

    // Obtener la ruta del directorio de documentos
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

    // Guardar el archivo Excel
    excel.setDefaultSheet(sheet.sheetName);
    final fileBytes = excel.save();

    // Si el archivo se guardó correctamente, abrirlo
    if (fileBytes != null) {
      final file = File(path);
      await file.writeAsBytes(fileBytes, flush: true);
      await OpenFilex.open(path);
      return path;
    } else {
      throw Exception("No se pudo generar el archivo Excel (bytes nulos).");
    }
  }

  // Método para exportar a PDF
  Future<String?> exportToPdf(StatisticsOverview statsOverview, String fileNamePrefix) async {
    if (statsOverview.dailySales.isEmpty &&
        statsOverview.topProducts.isEmpty &&
        statsOverview.frequentCustomers.isEmpty) {
      throw Exception("No hay datos para exportar a PDF.");
    }

    // Crear un documento PDF
    final pdf = pw.Document();
    final defaultTextStyle = pw.TextStyle(fontSize: 10, color: PdfColors.black);
    final headerTextStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700);
    final tableHeaderStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white);

    // Estilo para las celdas
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
            padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey)),
            ),
            child: pw.Text(
              'Reporte de Estadísticas - Tienda Emprendedor',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          );
        },
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];

          // --- Encabezado ---
          widgets.add(
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: <pw.Widget>[
                    pw.Text('Reporte General de Estadísticas', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                    pw.PdfLogo(),
                  ],
                ),
              )
          );

          widgets.add(pw.Paragraph(text: 'Generado el: ${DateFormat('dd MMMM yyyy, hh:mm a', _locale).format(DateTime.now())}', style: defaultTextStyle));
          widgets.add(pw.SizedBox(height: 20));

          if (statsOverview.dailySales.isNotEmpty) {
            widgets.add(pw.Header(level: 1, child: pw.Text('Resumen de Ventas Diarias', style: headerTextStyle)));
            widgets.add(_buildSalesTablePdf(statsOverview.dailySales, "Fecha", defaultTextStyle, tableHeaderStyle));
            widgets.add(pw.SizedBox(height: 15));
          }

          if (statsOverview.topProducts.isNotEmpty) {
            widgets.add(pw.Header(level: 1, child: pw.Text('Productos Más Vendidos', style: headerTextStyle)));
            widgets.add(_buildTopProductsTablePdf(statsOverview.topProducts, defaultTextStyle, tableHeaderStyle));
            widgets.add(pw.SizedBox(height: 15));
          }

          if (statsOverview.frequentCustomers.isNotEmpty) {
            widgets.add(pw.Header(level: 1, child: pw.Text('Clientes Frecuentes', style: headerTextStyle)));
            widgets.add(_buildFrequentCustomersTablePdf(statsOverview.frequentCustomers, defaultTextStyle, tableHeaderStyle));
          }

          // --- Pie de Página ---
          return widgets;
        },
      ),
    );

    // Obtener la ruta del directorio de documentos
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File(path);
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);

    // Usar printing para compartir/guardar/imprimir
    await Printing.sharePdf(bytes: pdfBytes, filename: file.path.split('/').last);

    return path;
  }

  pw.Widget _buildSalesTablePdf(List<SalesDataPoint> sales, String dateHeader, pw.TextStyle style, pw.TextStyle headerStyle) {
    if (sales.isEmpty) return pw.Paragraph(text: 'No hay datos de ventas disponibles.', style: style);
    return pw.TableHelper.fromTextArray(
        cellPadding: const pw.EdgeInsets.all(5),
        headerStyle: headerStyle,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.teal400),
        cellStyle: style,
        cellAlignment: pw.Alignment.centerLeft,
        data: <List<String>>[
          <String>[dateHeader, 'Monto Ventas', 'Núm. Pedidos'],
          ...sales.map((s) => [
            DateFormat('dd/MM/yy', _locale).format(s.date),
            NumberFormat.currency(locale: _locale, symbol: '\$', decimalDigits: 2).format(s.salesAmount),
            s.orderCount.toString(),
          ]),
        ],
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2),
        }
    );
  }

  pw.Widget _buildTopProductsTablePdf(List<TopProductStat> products, pw.TextStyle style, pw.TextStyle headerStyle) {
    if (products.isEmpty) return pw.Paragraph(text: 'No hay datos de productos más vendidos.', style: style);
    return pw.TableHelper.fromTextArray(
        cellPadding: const pw.EdgeInsets.all(5),
        headerStyle: headerStyle,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.teal400),
        cellStyle: style,
        cellAlignment: pw.Alignment.centerLeft,
        data: <List<String>>[
          <String>['Producto', 'Cant. Vendida', 'Ingresos'],
          ...products.map((p) => [
            p.productName,
            p.quantitySold.toString(),
            NumberFormat.currency(locale: _locale, symbol: '\$', decimalDigits: 2).format(p.totalRevenue),
          ]),
        ],
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(4),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(3),
        }
    );
  }

  pw.Widget _buildFrequentCustomersTablePdf(List<FrequentCustomerStat> customers, pw.TextStyle style, pw.TextStyle headerStyle) {
    if (customers.isEmpty) return pw.Paragraph(text: 'No hay datos de clientes frecuentes.', style: style);
    return pw.TableHelper.fromTextArray(
        cellPadding: const pw.EdgeInsets.all(5),
        headerStyle: headerStyle,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.teal400),
        cellStyle: style,
        cellAlignment: pw.Alignment.centerLeft,
        data: <List<String>>[
          <String>['Cliente', 'Total Pedidos', 'Total Gastado'],
          ...customers.map((c) => [
            c.customerName,
            c.totalOrders.toString(),
            NumberFormat.currency(locale: _locale, symbol: '\$', decimalDigits: 2).format(c.totalSpent),
          ]),
        ],
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(4),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(3),
        }
    );
  }
}
