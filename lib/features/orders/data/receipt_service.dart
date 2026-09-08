import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wave/core/utils/money.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

class ReceiptStrings {
  const ReceiptStrings({
    required this.brand,
    required this.documentTitle,
    required this.receipt,
    required this.orderLabel,
    required this.soldBy,
    required this.buyer,
    required this.deliveredTo,
    required this.status,
    required this.item,
    required this.qty,
    required this.unit,
    required this.total,
    required this.disclaimer,
    required this.orderedOnDate,
    required this.statusLabels,
  });

  final String brand;
  final String documentTitle;
  final String receipt;
  final String orderLabel;
  final String soldBy;
  final String buyer;
  final String deliveredTo;
  final String status;
  final String item;
  final String qty;
  final String unit;
  final String total;
  final String disclaimer;
  final String orderedOnDate;
  final Map<CustomerOrderStage, String> statusLabels;
}

class ReceiptService {
  const ReceiptService();

  static Future<pw.ThemeData>? _themeFuture;

  static Future<pw.ThemeData> _theme() {
    return _themeFuture ??= _loadTheme();
  }

  static Future<pw.ThemeData> _loadTheme() async {
    final regularBytes = await rootBundle.load(
      'assets/fonts/NotoSansArabic-Regular.ttf',
    );
    final semiBoldBytes = await rootBundle.load(
      'assets/fonts/NotoSansArabic-SemiBold.ttf',
    );

    final regular = pw.Font.ttf(regularBytes);
    final semiBold = pw.Font.ttf(semiBoldBytes);

    return pw.ThemeData.withFont(
      base: regular,
      bold: semiBold,
      italic: regular,
      boldItalic: semiBold,
    );
  }

  Future<Uint8List> generate({
    required Order order,
    required String sellerName,
    required ReceiptStrings strings,
    String? buyerName,
    String? deliveryAddress,
  }) async {
    final doc = pw.Document(
      title: strings.documentTitle,
      theme: await _theme(),
    )..addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40), // FIXED
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        strings.brand,
                        style: const pw.TextStyle(
                          fontSize: 24, // FIXED
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4), // FIXED
                      pw.Text(
                        strings.receipt,
                        style: const pw.TextStyle(fontSize: 12), // FIXED
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        strings.orderLabel,
                        style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2), // FIXED
                      pw.Text(
                        _shortId(order.id),
                        style: const pw.TextStyle(
                          fontSize: 12, // FIXED
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4), // FIXED
                      pw.Text(
                        strings.orderedOnDate,
                        style: const pw.TextStyle(fontSize: 10), // FIXED
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24), // FIXED
              pw.Divider(),
              pw.SizedBox(height: 16), // FIXED

              _labelled(strings.soldBy, sellerName),
              if (buyerName != null) _labelled(strings.buyer, buyerName),
              if (deliveryAddress != null)
                _labelled(strings.deliveredTo, deliveryAddress),
              _labelled(
                strings.status,
                strings.statusLabels[order.stage] ?? order.stage.name,
              ),

              pw.SizedBox(height: 24), // FIXED

              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside:
                      const pw.BorderSide(width: 0.5, color: PdfColors.grey400),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4), // FIXED
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FlexColumnWidth(2), // FIXED
                  3: const pw.FlexColumnWidth(2), // FIXED
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell(strings.item, bold: true),
                      _cell(strings.qty, bold: true, align: pw.TextAlign.center),
                      _cell(strings.unit, bold: true, align: pw.TextAlign.right),
                      _cell(strings.total, bold: true, align: pw.TextAlign.right),
                    ],
                  ),
                  for (final item in order.items)
                    pw.TableRow(
                      children: [
                        _cell(item.title),
                        _cell('${item.quantity}', align: pw.TextAlign.center),
                        _cell(
                          Money.format(item.unitPriceMinor, order.currency),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          Money.format(item.lineTotalMinor, order.currency),
                          align: pw.TextAlign.right,
                        ),
                      ],
                    ),
                ],
              ),

              pw.SizedBox(height: 16), // FIXED
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      '${strings.total}  ',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      Money.format(order.totalMinor, order.currency),
                      style: const pw.TextStyle(
                        fontSize: 16, // FIXED
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 8), // FIXED
              pw.Text(
                strings.disclaimer,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700), // FIXED
              ),
            ],
          ),
        ),
      );

    return doc.save();
  }

  static pw.Widget _labelled(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6), // FIXED
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 100, // FIXED
              child: pw.Text(
                label,
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700), // FIXED
              ),
            ),
            pw.Expanded(
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)), // FIXED
            ),
          ],
        ),
      );

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), // FIXED
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 10, // FIXED
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  static String _shortId(String id) =>
      '#${id.substring(0, id.length < 6 ? id.length : 6).toUpperCase()}';
}
