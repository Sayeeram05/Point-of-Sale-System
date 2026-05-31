import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class BillPdfService {
  // ─── Brand Colors ─────────────────────────────────────────────────────────
  static const _navy = PdfColor.fromInt(0xFF1A2B4A);
  static const _blue = PdfColor.fromInt(0xFF2C5F8A);
  static const _lightBg = PdfColor.fromInt(0xFFF8FAFC);
  static const _border = PdfColor.fromInt(0xFFDDE3EA);
  static const _dark = PdfColor.fromInt(0xFF1E293B);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _accent = PdfColor.fromInt(0xFF0EA5E9);

  // ─── Number Formatting ────────────────────────────────────────────────────
  static final _fmt = NumberFormat('#,##0.00', 'en_IN');
  static String fmt(double v) => _fmt.format(v);

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
    if (paise > 0) words += ' and ${_words(paise)} Paise';
    return '$words Only';
  }

  // ─── PDF Generation ───────────────────────────────────────────────────────
  static Future<Uint8List> generateBillPdf(Order order) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldFontData = await rootBundle.load(
      'assets/fonts/NotoSans-Bold.ttf',
    );
    final font = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldFontData);

    // Load the banner logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/icon/BillLogo.jpeg');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    final orderDate = order.parsedOrderDate ?? DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(orderDate);
    final timeStr = DateFormat('hh:mm a').format(orderDate);
    final grandTotal = order.totalPrice;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: _border, width: 0.8),
                  left: pw.BorderSide(color: _border, width: 0.8),
                  right: pw.BorderSide(color: _border, width: 0.8),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildLogoBanner(logoImage),
                  _buildBusinessInfo(font, boldFont),
                  pw.Container(height: 2.5, color: _accent),
                  _buildBillInfo(order, dateStr, timeStr, font, boldFont),
                ],
              ),
            );
          }
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _border, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Bill No: #${order.orderId} (continued)',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 9,
                    color: _dark,
                  ),
                ),
                pw.Text(
                  '$dateStr  $timeStr',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 9,
                    color: _dark,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            _buildItemsTable(order, font, boldFont),
            _buildSummarySection(order, grandTotal, font, boldFont),
            _buildAmountInWords(grandTotal, font, boldFont),
            _buildFooter(font, boldFont),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ─── Logo Banner (full width) ─────────────────────────────────────────────
  static pw.Widget _buildLogoBanner(pw.MemoryImage? logoImage) {
    if (logoImage == null) return pw.SizedBox(height: 0);
    const logoBlue = PdfColor.fromInt(0xFF89D4F5); // logo's left colour
    const logoYellow = PdfColor.fromInt(0xFFFFE040); // logo's right colour
    return pw.CustomPaint(
      // PDF canvas: origin bottom-left, y increases upward
      // h = visual top, 0 = visual bottom
      painter: (canvas, size) {
        final w = size.x;
        final h = size.y;
        // Logo diagonal is "\" direction (top-left → bottom-right visually).
        // PDF y: 0 = visual bottom, h = visual top.
        // So "\" means: at top (h) cut is LEFT of center, at bottom (0) cut is RIGHT.
        // LEFT side → yellow (inverted from logo)
        canvas
          ..setFillColor(logoYellow)
          ..moveTo(0, h)
          ..lineTo(w * 0.48, h) // top cut at 49%
          ..lineTo(w * 0.525, 0) // bottom cut at 55%
          ..lineTo(0, 0)
          ..fillPath();
        // RIGHT side → blue (inverted from logo)
        canvas
          ..setFillColor(logoBlue)
          ..moveTo(w * 0.48, h)
          ..lineTo(w, h)
          ..lineTo(w, 0)
          ..lineTo(w * 0.525, 0)
          ..fillPath();
      },
      child: pw.SizedBox(
        width: double.infinity,
        height: 80,
        child: pw.Center(
          child: pw.Image(logoImage, fit: pw.BoxFit.contain, height: 64),
        ),
      ),
    );
  }

  // ─── Business Info (below logo) ───────────────────────────────────────────
  static pw.Widget _buildBusinessInfo(
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Fruitice Billing',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '123 Main Street, Chennai',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 7.5,
                    color: const PdfColor.fromInt(0xFFCBD5E1),
                  ),
                ),
                pw.Text(
                  'Tamil Nadu, India',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 7.5,
                    color: const PdfColor.fromInt(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Ph: +91 98765 43210',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 7.5,
                  color: const PdfColor.fromInt(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Bill Info Row ────────────────────────────────────────────────────────
  static pw.Widget _buildBillInfo(
    Order order,
    String dateStr,
    String timeStr,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const pw.BoxDecoration(
        color: _lightBg,
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Text(
                  'Bill No: ',
                  style: pw.TextStyle(font: font, fontSize: 9, color: _muted),
                ),
                pw.Text(
                  '#${order.orderId}',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: _dark,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            '$dateStr  $timeStr',
            style: pw.TextStyle(font: boldFont, fontSize: 9, color: _dark),
          ),
        ],
      ),
    );
  }

  // ─── Items Table ──────────────────────────────────────────────────────────
  static pw.Widget _buildItemsTable(
    Order order,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final hStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 8,
      color: PdfColors.white,
    );
    final cStyle = pw.TextStyle(font: font, fontSize: 8.5, color: _dark);
    final cBold = pw.TextStyle(font: boldFont, fontSize: 8.5, color: _dark);

    final cols = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(0.6),
      1: const pw.FlexColumnWidth(4.5),
      2: const pw.FlexColumnWidth(1.2),
      3: const pw.FlexColumnWidth(1.8),
      4: const pw.FlexColumnWidth(2.0),
    };

    final rows = <pw.TableRow>[
      // Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _blue),
        children: [
          _tc('No.', hStyle, center: true),
          _tc('Description', hStyle),
          _tc('Qty', hStyle, center: true),
          _tc('Rate', hStyle, right: true),
          _tc('Amount', hStyle, right: true),
        ],
      ),
      // Items
      ...order.items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        final bg = i.isOdd ? _lightBg : PdfColors.white;
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: bg),
          children: [
            _tc('${i + 1}', cStyle, center: true),
            _tc(item.product.toUpperCase(), cBold),
            _tc('${item.pieces}', cStyle, center: true),
            _tc(fmt(item.priceDouble), cStyle, right: true),
            _tc(fmt(item.totalPrice), cBold, right: true),
          ],
        );
      }),
      // Total row
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: _lightBg,
          border: pw.Border(top: pw.BorderSide(color: _border, width: 1)),
        ),
        children: [
          _tc('', cBold),
          _tc('', cBold),
          _tc(
            '${order.totalItems}',
            pw.TextStyle(font: boldFont, fontSize: 9, color: _blue),
            center: true,
          ),
          _tc(
            'Total',
            pw.TextStyle(font: boldFont, fontSize: 9, color: _blue),
            right: true,
          ),
          _tc(
            fmt(order.totalPrice),
            pw.TextStyle(font: boldFont, fontSize: 10, color: _navy),
            right: true,
          ),
        ],
      ),
    ];

    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(
          width: 0.3,
          color: PdfColor.fromInt(0xFFE2E8F0),
        ),
      ),
      columnWidths: cols,
      children: rows,
    );
  }

  static pw.Widget _tc(
    String text,
    pw.TextStyle style, {
    bool center = false,
    bool right = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      alignment: right
          ? pw.Alignment.centerRight
          : center
          ? pw.Alignment.center
          : pw.Alignment.centerLeft,
      child: pw.Text(text, style: style),
    );
  }

  // ─── Summary Section ──────────────────────────────────────────────────────
  static pw.Widget _buildSummarySection(
    Order order,
    double grandTotal,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _border, width: 0.5),
          bottom: pw.BorderSide(color: _border, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Left: Payment
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Payment',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: _muted,
                  ),
                ),
                pw.SizedBox(height: 6),
                if (order.cashAmountDouble > 0)
                  pw.Text(
                    'Cash:  \u20B9${fmt(order.cashAmountDouble)}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8.5,
                      color: _dark,
                    ),
                  ),
                if (order.upiAmountDouble > 0)
                  pw.Text(
                    'UPI:  \u20B9${fmt(order.upiAmountDouble)}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8.5,
                      color: _dark,
                    ),
                  ),
                if (order.cashAmountDouble <= 0 && order.upiAmountDouble <= 0)
                  pw.Text(
                    '--',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8.5,
                      color: _muted,
                    ),
                  ),
              ],
            ),
          ),
          // Right: Grand Total
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: _muted,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '\u20B9${fmt(grandTotal)}',
                style: pw.TextStyle(font: boldFont, fontSize: 24, color: _navy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Amount In Words ──────────────────────────────────────────────────────
  static pw.Widget _buildAmountInWords(
    double total,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const PdfColor.fromInt(0xFFFEFCE8),
      child: pw.Text(
        amountInWords(total),
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 8,
          color: const PdfColor.fromInt(0xFF92400E),
        ),
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your purchase!',
            style: pw.TextStyle(font: boldFont, fontSize: 10, color: _navy),
          ),
        ],
      ),
    );
  }

  // ─── Get bill save directory (user-configurable via SharedPreferences) ────
  /// Gets the current bill save directory path.
  ///
  /// Priority:
  /// 1. User-selected custom path from SharedPreferences
  /// 2. Platform-specific default path:
  ///    - Android: /storage/emulated/0/Download/Bills
  ///    - iOS: App Documents/Bills
  ///
  /// The directory is automatically created if it doesn't exist.
  static Future<String> getBillSaveDir() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('bill_save_path') ?? '';

    // Use custom path if set
    if (customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        try {
          await dir.create(recursive: true);
        } catch (_) {
          // Fall back to default if custom path fails
        }
      }
      if (await dir.exists()) {
        return customPath;
      }
    }

    // Web platform - use share instead of file system
    if (kIsWeb) {
      return '';
    }

    // Get platform-specific default path
    String defaultPath;
    if (Platform.isAndroid) {
      defaultPath = await _getAndroidDefaultPath();
    } else {
      defaultPath = await _getIOSDefaultPath();
    }

    // Ensure directory exists
    final dir = Directory(defaultPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return defaultPath;
  }

  /// Gets the default save path for Android
  /// Tries external Downloads directory first, falls back to app documents
  static Future<String> _getAndroidDefaultPath() async {
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        // Navigate to external storage root (/storage/emulated/0)
        final root = extDir.parent.parent.parent.parent;
        return '${root.path}/Download/Bills';
      }
    } catch (_) {
      // Fall through to app documents
    }

    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/Bills';
  }

  /// Gets the default save path for iOS
  /// Uses app documents directory (sandboxed)
  static Future<String> _getIOSDefaultPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/Bills';
  }

  // ─── Save PDF ─────────────────────────────────────────────────────────────
  static Future<String> savePdf(Uint8List pdfBytes, Order order) async {
    if (kIsWeb) {
      final fileName = _buildFileName(order);
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      return 'Shared via browser';
    }

    final dirPath = await getBillSaveDir();

    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final fileName = _buildFileName(order);
    final file = File('$dirPath/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Opens system share dialog with consistent filename.
  static Future<void> shareOrPrint(Uint8List pdfBytes, Order order) async {
    final fileName = _buildFileName(order);
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  /// Consistent filename: Bill_orderId_YYYYMMDD.pdf
  static String _buildFileName(Order order) {
    final orderDate = order.parsedOrderDate ?? DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(orderDate);
    return 'Bill_${order.orderId}_$dateStr.pdf';
  }
}
