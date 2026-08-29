import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wave/core/utils/money.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

/// Generates the digital receipt (§5.2).
///
/// Built on the device rather than server-side, for two reasons: it works
/// offline, and a receipt is not sensitive data that needs a trusted generator —
/// every figure on it is already in the order document the buyer can read.
///
/// The layout is deliberately plain. A receipt is a document someone may need
/// to show a courier, a bank, or a tax office; it needs to be legible when
/// printed in black and white on bad paper, not to look like the app.
///
/// Strings arrive as [ReceiptStrings] rather than being looked up here. A
/// service has no BuildContext, and a receipt generated in the wrong language
/// is a document someone hands to a courier who cannot read it.
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

  /// The app name. Identical in all three languages, and sourced from the ARB
  /// anyway so there is one place it is written rather than two that can drift.
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

  /// The order date, already formatted for the reader's locale.
  ///
  /// Formatted before it gets here rather than inside the PDF builder, for the
  /// same reason every other string on this receipt is: the builder has no
  /// BuildContext, so a date formatted there is `dd/MM/yyyy` with Western
  /// digits in every language.
  final String orderedOnDate;

  /// Keyed by [CustomerOrderStage], so the receipt shows the same three words
  /// the tracker does.
  final Map<CustomerOrderStage, String> statusLabels;
}

class ReceiptService {
  const ReceiptService();

  /// The Unicode font, loaded once and reused across every receipt.
  ///
  /// pdf's built-in `pw.Font` faces (Helvetica and friends) are the 14
  /// standard PDF core fonts, which cover Latin text and nothing else. Every
  /// receipt for an Arabic or Kurdish name, seller, or delivery address —
  /// which per `WaveLocalizations`, two of this app's three launch locales —
  /// rendered as blank boxes, silently, with only a console warning
  /// ("Helvetica has no Unicode support") that nobody sees on a customer's
  /// device. The existing test suite could not have caught it: it only
  /// asserts the PDF bytes are non-empty, never that the glyphs in it are the
  /// ones that were asked for.
  ///
  /// Uses IBMPlexSansArabic — already declared in pubspec.yaml for the
  /// in-app UI, so this needs no new asset and no pubspec change. It covers
  /// the Arabic script block, which both Arabic and Sorani Kurdish (written
  /// in Arabic script, not Latin) are built from, and its Latin glyphs cover
  /// English too, so one face serves all three launch locales on one
  /// document — useful here specifically, since a single receipt routinely
  /// mixes scripts: an Arabic seller name beside a Latin order id, an English
  /// UI string beside a Kurdish delivery note.
  ///
  /// Only two weights are declared for this family — 400 and 600 — so 600
  /// (SemiBold) stands in for every place this file asks for `bold`. That is
  /// a font family a UI designer chose for on-screen legibility, not a print
  /// designer choosing print weights; if the semibold-as-bold substitution
  /// reads as too heavy or too light on actual printed paper, that is a
  /// design call worth revisiting deliberately, not a byproduct of this fix.
  ///
  /// Loaded lazily and cached in a static so a seller generating several
  /// receipts in a session pays the asset-read cost once, not per document.
  static Future<pw.ThemeData>? _themeFuture;

  static Future<pw.ThemeData> _theme() {
    return _themeFuture ??= _loadTheme();
  }

  static Future<pw.ThemeData> _loadTheme() async {
    final regularBytes = await rootBundle.load(
      'assets/fonts/IBMPlexSansArabic-Regular.ttf',
    );
    final semiBoldBytes = await rootBundle.load(
      'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
    );

    final regular = pw.Font.ttf(regularBytes);
    final semiBold = pw.Font.ttf(semiBoldBytes);

    return pw.ThemeData.withFont(
      base: regular,
      bold: semiBold,
      // Applied to italic/boldItalic too, since this family has no separate
      // italic weight and pdf falls back to Helvetica for any style left
      // unset — which reintroduces the exact bug this exists to fix, just on
      // whichever style nobody thought to set explicitly.
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
          margin: const pw.EdgeInsets.all(40),
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
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        strings.receipt,
                        style: const pw.TextStyle(fontSize: 12),
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
                      pw.SizedBox(height: 2),
                      // The reference someone actually quotes on the phone.
                      //
                      // _shortId was written for this and never called, so every
                      // receipt named an order without saying WHICH order — the
                      // one field a courier or a bank asks for. Latin digits and
                      // letters deliberately, in all three locales: this is a
                      // lookup key, not prose, and it has to survive being read
                      // aloud and typed back in.
                      pw.Text(
                        _shortId(order.id),
                        style: const pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        strings.orderedOnDate,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 16),

              _labelled(strings.soldBy, sellerName),
              if (buyerName != null) _labelled(strings.buyer, buyerName),
              if (deliveryAddress != null)
                _labelled(strings.deliveredTo, deliveryAddress),
              _labelled(
                strings.status,
                strings.statusLabels[order.stage] ?? order.stage.name,
              ),

              pw.SizedBox(height: 24),

              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside:
                      const pw.BorderSide(width: 0.5, color: PdfColors.grey400),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
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

              pw.SizedBox(height: 16),
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
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                // Says plainly what this document is and is not. A receipt that
                // implies it is a tax invoice when it is not causes real problems
                // for whoever tries to use it as one.
                strings.disclaimer,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      );

    return doc.save();
  }

  static pw.Widget _labelled(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 100,
              child: pw.Text(
                label,
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
            pw.Expanded(
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
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
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  /// First six characters of the order id, uppercased.
  ///
  /// Short enough to read down a phone line, long enough to be unambiguous
  /// against one seller's order list. The length guard is not theoretical: a
  /// seeded or migrated order can carry a shorter id than a Firestore
  /// auto-id, and substring would throw rather than degrade.
  static String _shortId(String id) =>
      '#${id.substring(0, id.length < 6 ? id.length : 6).toUpperCase()}';
}
