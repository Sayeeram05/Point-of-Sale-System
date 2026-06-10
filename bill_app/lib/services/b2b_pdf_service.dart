import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/b2b_invoice.dart';
import '../models/b2b_settings.dart';

class B2BPdfService {
  // ─── Number Formatting ────────────────────────────────────────────────────

  static final _fmt = NumberFormat('#,##0.00', 'en_IN');
  static final _qtyFmt = NumberFormat('#,##0.###', 'en_IN');

  static String fmt(double v) => _fmt.format(v);
  static String fmtQty(double v) =>
      v == v.toInt() ? v.toInt().toString() : _qtyFmt.format(v);
  static String _fmtPercent(double v) =>
      v == v.toInt() ? v.toInt().toString() : _qtyFmt.format(v);

  // ─── Indian Number Words ──────────────────────────────────────────────────

  static const List<String> _ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];
  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String _words(int n) {
    if (n == 0) return '';
    if (n < 20) return _ones[n];
    if (n < 100) {
      return '${_tens[n ~/ 10]}${n % 10 != 0 ? ' ${_ones[n % 10]}' : ''}';
    }
    if (n < 1000) {
      return '${_ones[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${_words(n % 100)}' : ''}';
    }
    if (n < 100000) {
      return '${_words(n ~/ 1000)} Thousand${n % 1000 != 0 ? ' ${_words(n % 1000)}' : ''}';
    }
    if (n < 10000000) {
      return '${_words(n ~/ 100000)} Lakh${n % 100000 != 0 ? ' ${_words(n % 100000)}' : ''}';
    }
    return '${_words(n ~/ 10000000)} Crore${n % 10000000 != 0 ? ' ${_words(n % 10000000)}' : ''}';
  }

  static String amountInWords(double amount) {
    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();
    String words = 'Rupees ${_words(rupees)}';
    if (paise > 0) {
      words += ' and ${_words(paise)} Paise';
    }
    return '$words Only';
  }

  // ─── PDF Generation ───────────────────────────────────────────────────────

  static Future<Uint8List> generateInvoicePdf(
    B2BInvoice invoice,
    B2BSettings settings,
  ) async {
    final pdf = pw.Document();

    // Load NotoSans from bundled assets — supports ₹ and Indian scripts (works offline)
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldFontData = await rootBundle.load(
      'assets/fonts/NotoSans-Bold.ttf',
    );
    final font = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final dateStr = DateFormat('dd.MM.yyyy').format(invoice.date);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildHeader(invoice, settings, dateStr, font, boldFont),
            pw.SizedBox(height: 4),
            _buildReceiverSection(invoice, settings, font, boldFont),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (pw.Context context) => [
          _buildItemsTable(invoice, font, boldFont),
          pw.SizedBox(height: 4),
          _buildFooter(invoice, settings, font, boldFont),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    B2BInvoice invoice,
    B2BSettings settings,
    String dateStr,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Column(
        children: [
          // INVOICE title
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                letterSpacing: 1,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Divider(thickness: 0.5, height: 1),
          // Company info row
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // GSTIN on left
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    settings.gstin.isNotEmpty ? settings.gstin : '',
                    style: pw.TextStyle(font: font, fontSize: 7.5),
                  ),
                ),
                // Company name & address centered
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        settings.companyName,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      if (settings.addressLine1.isNotEmpty)
                        pw.Text(
                          settings.addressLine1,
                          style: pw.TextStyle(font: font, fontSize: 7.5),
                          textAlign: pw.TextAlign.center,
                        ),
                      if (settings.addressLine2.isNotEmpty)
                        pw.Text(
                          settings.addressLine2,
                          style: pw.TextStyle(font: font, fontSize: 7.5),
                          textAlign: pw.TextAlign.center,
                        ),
                      pw.Text(
                        'Phone: ${settings.phone1}${settings.phone2.isNotEmpty ? ', ${settings.phone2}' : ''}',
                        style: pw.TextStyle(font: font, fontSize: 7.5),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Invoice No + Date on right
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'Invoice No  :  ',
                            style: pw.TextStyle(font: font, fontSize: 7.5),
                          ),
                          pw.Text(
                            invoice.invoiceNumber,
                            style: pw.TextStyle(font: boldFont, fontSize: 7.5),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Date            :  ',
                            style: pw.TextStyle(font: font, fontSize: 7.5),
                          ),
                          pw.Text(
                            dateStr,
                            style: pw.TextStyle(font: font, fontSize: 7.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Divider(thickness: 0.5, height: 1),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: pw.Text(
              'Place of Supply / State Code: ${settings.state} / ${settings.stateCode}',
              style: pw.TextStyle(font: font, fontSize: 7.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Receiver Section ─────────────────────────────────────────────────────

  static pw.Widget _buildReceiverSection(
    B2BInvoice invoice,
    B2BSettings settings,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Details of Receiver (Billed to)',
            style: pw.TextStyle(font: font, fontSize: 7.5),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            invoice.receiverName,
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
          if (invoice.receiverAddress.isNotEmpty)
            pw.Text(
              invoice.receiverAddress,
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          if (invoice.receiverState.isNotEmpty)
            pw.Text(
              'State: ${invoice.receiverState}',
              style: pw.TextStyle(font: font, fontSize: 7.5),
            ),
        ],
      ),
    );
  }

  // ─── Items Table ──────────────────────────────────────────────────────────

  static pw.Widget _buildItemsTable(
    B2BInvoice invoice,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final headerStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 7,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 7.5);
    final boldCellStyle = pw.TextStyle(font: boldFont, fontSize: 7.5);

    // 10 columns: S.No | Item | HSN | Rate | Stk/Box | Boxes | Gross | Disc % | Disc | Net
    final Map<int, pw.TableColumnWidth> colWidths = {
      0: const pw.FlexColumnWidth(0.8), // S.No
      1: const pw.FlexColumnWidth(3.5), // Item
      2: const pw.FlexColumnWidth(1.5), // HSN Code
      3: const pw.FlexColumnWidth(1.6), // Rate
      4: const pw.FlexColumnWidth(1.0), // Stk/Box
      5: const pw.FlexColumnWidth(1.2), // Boxes
      6: const pw.FlexColumnWidth(1.8), // Gross
      7: const pw.FlexColumnWidth(1.0), // Disc %
      8: const pw.FlexColumnWidth(1.5), // Disc (Rs)
      9: const pw.FlexColumnWidth(1.8), // Net (Rs)
    };

    // ── Header Row (dark blue background) ──
    final pw.TableRow headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1565C0)),
      children: [
        _cell('S.No', headerStyle, center: true),
        _cell('Item', headerStyle),
        _cell('HSN', headerStyle, center: true),
        _cell('Rate (Rs)', headerStyle, right: true),
        _cell('Stk/Box', headerStyle, center: true),
        _cell('Boxes', headerStyle, center: true),
        _cell('Gross (Rs)', headerStyle, right: true),
        _cell('Disc %', headerStyle, center: true),
        _cell('Disc (Rs)', headerStyle, right: true),
        _cell('Net (Rs)', headerStyle, right: true),
      ],
    );

    // ── Data Rows (alternating white / light grey) ──
    final itemRows = invoice.items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final amount = item.rateInclTax * item.quantity;
      final boxQty = item.quantityInBoxes;
      final boxQtyStr = boxQty == boxQty.truncateToDouble()
          ? '${boxQty.toInt()}'
          : boxQty.toStringAsFixed(1);
      return pw.TableRow(
        decoration: pw.BoxDecoration(
          color: i.isEven ? PdfColors.white : PdfColors.grey50,
        ),
        children: [
          _cell('${i + 1}', cellStyle, center: true),
          _cell(item.description, cellStyle),
          _cell(item.hsnCode, cellStyle, center: true),
          _cell(fmt(item.rateInclTax), cellStyle, right: true),
          _cell(item.stkPerBoxLabel, cellStyle, center: true),
          _cell(boxQtyStr, boldCellStyle, center: true),
          _cell(fmt(amount), cellStyle, right: true),
          _cell(
            item.discountPercent > 0
                ? '${item.discountPercent.toStringAsFixed(item.discountPercent == item.discountPercent.truncateToDouble() ? 0 : 2)}%'
                : '-',
            cellStyle,
            center: true,
          ),
          _cell(
            item.discountAmount > 0 ? fmt(item.discountAmount) : '-',
            cellStyle,
            right: true,
          ),
          _cell(fmt(item.netAmount), boldCellStyle, right: true),
        ],
      );
    }).toList();

    // ── Totals Row ──
    final totalAmount = invoice.items.fold(
      0.0,
      (sum, item) => sum + (item.rateInclTax * item.quantity),
    );
    final totalItemDiscount = invoice.items.fold(
      0.0,
      (sum, item) => sum + item.discountAmount,
    );
    final totalBoxes = invoice.items.fold<double>(
      0,
      (s, e) => s + e.quantityInBoxes,
    );
    final totalBoxesStr = totalBoxes == totalBoxes.truncateToDouble()
        ? '${totalBoxes.toInt()}'
        : totalBoxes.toStringAsFixed(1);

    final pw.TableRow totalsRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE3F2FD)),
      children: [
        _cell('', boldCellStyle),
        _cell('TOTAL', pw.TextStyle(font: boldFont, fontSize: 8)),
        _cell('', boldCellStyle),
        _cell('', boldCellStyle),
        _cell('', boldCellStyle), // Stk/Box spacer
        _cell(
          totalBoxesStr,
          pw.TextStyle(font: boldFont, fontSize: 8),
          center: true,
        ),
        _cell(
          fmt(totalAmount),
          pw.TextStyle(font: boldFont, fontSize: 8),
          right: true,
        ),
        _cell('', boldCellStyle), // Disc % spacer
        _cell(
          fmt(totalItemDiscount),
          pw.TextStyle(font: boldFont, fontSize: 8),
          right: true,
        ),
        _cell(
          fmt(invoice.totalNetAmount),
          pw.TextStyle(font: boldFont, fontSize: 8),
          right: true,
        ),
      ],
    );

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: colWidths,
      children: [headerRow, ...itemRows, totalsRow],
    );
  }

  static pw.Widget _cell(
    String text,
    pw.TextStyle style, {
    bool center = false,
    bool right = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      alignment: right
          ? pw.Alignment.centerRight
          : center
          ? pw.Alignment.center
          : pw.Alignment.centerLeft,
      child: pw.Text(text, style: style),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(
    B2BInvoice invoice,
    B2BSettings settings,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Column(
        children: [
          // Discount Amount & Grand Total
          pw.Row(
            children: [
              pw.Expanded(
                flex: 6,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Total in words: ${amountInWords(invoice.grandTotal)}',
                    style: pw.TextStyle(font: font, fontSize: 7.5),
                  ),
                ),
              ),
              pw.Container(width: 0.5, color: PdfColors.black, height: 30),
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (invoice.globalDiscountPercent > 0) ...[
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Overall Disc %',
                              style: pw.TextStyle(font: font, fontSize: 7.5),
                            ),
                            pw.Text(
                              '${_fmtPercent(invoice.globalDiscountPercent)}%',
                              style: pw.TextStyle(font: font, fontSize: 7.5),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                      ],
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Discount Amount',
                            style: pw.TextStyle(font: font, fontSize: 7.5),
                          ),
                          pw.Text(
                            fmt(invoice.totalDiscount),
                            style: pw.TextStyle(font: font, fontSize: 7.5),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Grand Total',
                            style: pw.TextStyle(font: boldFont, fontSize: 8),
                          ),
                          pw.Text(
                            fmt(invoice.grandTotal),
                            style: pw.TextStyle(font: boldFont, fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.Divider(thickness: 0.5, height: 1),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'For ${settings.companyName}',
                      style: pw.TextStyle(font: boldFont, fontSize: 8),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      'Authorised Signatory',
                      style: pw.TextStyle(font: font, fontSize: 7.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Divider(thickness: 0.5, height: 1),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Text(
              'This business is currently operating below the GST registration threshold '
              'as per Section 22 of the CGST Act, 2017. Hence, GST is not applicable on this bill.',
              style: pw.TextStyle(font: font, fontSize: 6.5),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Save & Share ─────────────────────────────────────────────────────────

  /// Saves PDF to device and returns the file path.
  /// Tries Downloads folder on Android, falls back to app documents.
  /// If [dirPath] is supplied it takes priority.
  static Future<String> savePdf(
    Uint8List pdfBytes,
    B2BInvoice invoice,
    B2BSettings settings, {
    String? dirPath,
  }) async {
    String effectiveDirPath = dirPath ?? settings.pdfSavePath;
    if (effectiveDirPath.isEmpty) {
      // On Android try external storage (Downloads-style),
      // fall back to app documents on other platforms.
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            // getExternalStorageDirectory returns something like
            // /storage/emulated/0/Android/data/com.example.bill_app/files
            // We go up 4 levels to reach /storage/emulated/0 then Downloads
            final root = extDir.parent.parent.parent.parent;
            effectiveDirPath = '${root.path}/Download/B2B_Invoices';
          }
        } catch (_) {}
      }
      if (effectiveDirPath.isEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        effectiveDirPath = '${appDir.path}/B2B_Invoices';
      }
    }
    dirPath = effectiveDirPath;

    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final fileName =
        'Invoice_${invoice.invoiceNumber.replaceAll('/', '_')}_${DateFormat('yyyyMMdd').format(invoice.date)}.pdf';
    final file = File('$dirPath/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Opens system print/share dialog (works cross-platform).
  static Future<void> printOrPreview(
    Uint8List pdfBytes,
    String invoiceNumber,
  ) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_$invoiceNumber.pdf',
    );
  }

  /// Opens print preview overlay in Flutter.
  static Future<void> showPreview(
    Uint8List pdfBytes,
    String invoiceNumber,
  ) async {
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }
}
