import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../models/b2b_invoice.dart';
import '../../models/b2b_settings.dart';
import '../../services/b2b_pdf_service.dart';
import '../../theme/app_theme.dart';

class B2BInvoicePreviewPage extends StatefulWidget {
  final B2BInvoice invoice;
  final B2BSettings settings;

  const B2BInvoicePreviewPage({
    super.key,
    required this.invoice,
    required this.settings,
  });

  @override
  State<B2BInvoicePreviewPage> createState() => _B2BInvoicePreviewPageState();
}

class _B2BInvoicePreviewPageState extends State<B2BInvoicePreviewPage> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _savedPath;
  bool _isSaving = false;

  /// Cached directory so we only ask the user once per session.
  static String? _cachedSaveDir;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await B2BPdfService.generateInvoicePdf(
        widget.invoice,
        widget.settings,
      );
      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Resolves the save directory once: settings path > cached path > ask user.
  Future<String?> _resolveSaveDir() async {
    // 1. Use the path from B2B settings if configured
    if (widget.settings.pdfSavePath.isNotEmpty) {
      return widget.settings.pdfSavePath;
    }
    // 2. Reuse the directory picked earlier in this session
    if (_cachedSaveDir != null) return _cachedSaveDir;
    // 3. First time — ask the user to pick a folder
    final pickedDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose folder for B2B invoices (asked once)',
    );
    if (pickedDir != null) _cachedSaveDir = pickedDir;
    return pickedDir;
  }

  Future<void> _savePdf() async {
    if (_pdfBytes == null) return;

    final dir = await _resolveSaveDir();
    if (dir == null) return; // user cancelled

    setState(() => _isSaving = true);
    try {
      final path = await B2BPdfService.savePdf(
        _pdfBytes!,
        widget.invoice,
        widget.settings,
        dirPath: dir,
      );
      setState(() {
        _savedPath = path;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _share() async {
    if (_pdfBytes == null) return;
    await B2BPdfService.printOrPreview(
      _pdfBytes!,
      widget.invoice.invoiceNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Invoice ${widget.invoice.invoiceNumber}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_pdfBytes != null) ...[
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save_alt),
                tooltip: 'Save PDF',
                onPressed: _savePdf,
              ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share / Print',
              onPressed: _share,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Quick summary strip
          _buildSummaryStrip(moneyFmt),
          // PDF Preview
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating PDF...'),
                      ],
                    ),
                  )
                : _pdfBytes == null
                ? const Center(child: Text('Failed to generate PDF'))
                : PdfPreview(
                    build: (_) async => _pdfBytes!,
                    // Disable built-in toolbar — we have our own Save/Print buttons
                    allowPrinting: false,
                    allowSharing: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    pdfFileName: 'Invoice_${widget.invoice.invoiceNumber}.pdf',
                    actions: const [],
                    previewPageMargin: EdgeInsets.all(
                      AppTheme.isMobileOnly(context) ? 8 : 16,
                    ),
                  ),
          ),
          if (_savedPath != null)
            Container(
              color: Colors.green[50],
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saved: $_savedPath',
                      style: TextStyle(
                        fontSize: AppTheme.isMobileOnly(context) ? 11 : 14,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      // Bottom action bar
      bottomNavigationBar: _pdfBytes == null
          ? null
          : SafeArea(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.isMobileOnly(context) ? 16 : 24,
                  vertical: AppTheme.isMobileOnly(context) ? 10 : 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _savePdf,
                        icon: Icon(
                          Icons.save_alt,
                          size: AppTheme.isMobileOnly(context) ? 18 : 22,
                        ),
                        label: const Text('Save PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: AppTheme.isMobileOnly(context) ? 12 : 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _share,
                        icon: Icon(
                          Icons.print_outlined,
                          size: AppTheme.isMobileOnly(context) ? 18 : 22,
                        ),
                        label: const Text('Print / Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: AppTheme.isMobileOnly(context) ? 12 : 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryStrip(NumberFormat moneyFmt) {
    final inv = widget.invoice;
    return Container(
      color: const Color(0xFF1565C0),
      padding: EdgeInsets.fromLTRB(
        AppTheme.isMobileOnly(context) ? 16 : 24,
        8,
        AppTheme.isMobileOnly(context) ? 16 : 24,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.receiverName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.isMobileOnly(context) ? 14 : 17,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(inv.date),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppTheme.isMobileOnly(context) ? 11 : 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${moneyFmt.format(inv.grandTotal)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.isMobileOnly(context) ? 16 : 20,
                ),
              ),
              Text(
                '${inv.items.length} items  •  ${inv.totalQuantity.toInt()} pcs',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: AppTheme.isMobileOnly(context) ? 11 : 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
