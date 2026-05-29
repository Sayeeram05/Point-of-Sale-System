import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/b2b_invoice.dart';
import '../../models/b2b_settings.dart';
import '../../services/b2b_storage_service.dart';
import '../../theme/app_theme.dart';
import 'b2b_invoice_form_page.dart';
import 'b2b_invoice_preview_page.dart';
import 'b2b_settings_page.dart';

class B2BDashboardPage extends StatefulWidget {
  const B2BDashboardPage({super.key});

  @override
  State<B2BDashboardPage> createState() => _B2BDashboardPageState();
}

class _B2BDashboardPageState extends State<B2BDashboardPage> {
  List<B2BInvoice> _invoices = [];
  B2BSettings _settings = B2BSettings();
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final results = await Future.wait([
        B2BStorageService.loadInvoices(),
        B2BStorageService.loadSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        _invoices = results[0] as List<B2BInvoice>;
        _settings = results[1] as B2BSettings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<B2BInvoice> get _filteredInvoices {
    if (_searchQuery.isEmpty) return _invoices;
    final q = _searchQuery.toLowerCase();
    return _invoices.where((inv) {
      return inv.invoiceNumber.toLowerCase().contains(q) ||
          inv.receiverName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _createInvoice() async {
    // Peek the next invoice number without incrementing — counter is only
    // consumed in B2BInvoiceFormPage._save() when the invoice is actually saved.
    final invoiceNo = _settings.nextInvoiceCode;
    final newInvoice = B2BInvoice(
      id: '',
      invoiceNumber: invoiceNo,
      date: DateTime.now(),
      receiverName: '',
      receiverAddress: '',
      items: [],
      createdAt: DateTime.now(),
    );
    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            B2BInvoiceFormPage(invoice: newInvoice, settings: _settings),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _editInvoice(B2BInvoice invoice) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => B2BInvoiceFormPage(
          invoice: invoice,
          settings: _settings,
          isEditing: true,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _openPreview(B2BInvoice invoice) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            B2BInvoicePreviewPage(invoice: invoice, settings: _settings),
      ),
    );
  }

  Future<void> _deleteInvoice(B2BInvoice invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Invoice'),
        content: Text(
          'Delete invoice ${invoice.invoiceNumber} for ${invoice.receiverName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await B2BStorageService.deleteInvoice(invoice.id);
      _load();
    }
  }

  // ─── Status helpers ──────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case B2BInvoice.statusBilled:
        return const Color(0xFF1565C0); // Blue
      case B2BInvoice.statusShipped:
        return const Color(0xFFE65100); // Orange
      case B2BInvoice.statusDelivered:
        return const Color(0xFF2E7D32); // Green
      case B2BInvoice.statusPaid:
        return const Color(0xFF6A1B9A); // Purple
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case B2BInvoice.statusBilled:
        return Icons.receipt_long;
      case B2BInvoice.statusShipped:
        return Icons.local_shipping;
      case B2BInvoice.statusDelivered:
        return Icons.check_circle_outline;
      case B2BInvoice.statusPaid:
        return Icons.payments;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _changeStatus(B2BInvoice invoice) async {
    final newStatus = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: AppTheme.isMobileOnly(context) ? 40 : 50,
                height: AppTheme.isMobileOnly(context) ? 4 : 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Update Status — ${invoice.invoiceNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.isMobileOnly(context) ? 16 : 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...B2BInvoice.allStatuses.map((s) {
                final isCurrent = s == invoice.status;
                final color = _statusColor(s);
                return ListTile(
                  leading: Icon(_statusIcon(s), color: color),
                  title: Text(
                    B2BInvoice.statusLabel(s),
                    style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrent ? color : null,
                    ),
                  ),
                  trailing: isCurrent
                      ? Icon(Icons.check_circle, color: color)
                      : null,
                  onTap: isCurrent ? null : () => Navigator.pop(context, s),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (newStatus != null && newStatus != invoice.status) {
      try {
        await B2BStorageService.updateInvoiceStatus(invoice.id, newStatus);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('B2B Invoices'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'B2B Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => B2BSettingsPage(settings: _settings),
                ),
              );
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? _buildErrorState()
                : _filteredInvoices.isEmpty
                ? _buildEmptyState()
                : _buildInvoiceList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInvoice,
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Invoice',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final totalGrandTotal = _invoices.fold(0.0, (s, inv) => s + inv.grandTotal);
    final fmt = NumberFormat('#,##0.00', 'en_IN');
    return Container(
      color: const Color(0xFF1565C0),
      padding: EdgeInsets.fromLTRB(
        AppTheme.isMobileOnly(context) ? 16 : 24,
        0,
        AppTheme.isMobileOnly(context) ? 16 : 24,
        16,
      ),
      child: Row(
        children: [
          _summaryChip(Icons.receipt_long, '${_invoices.length}', 'Invoices'),
          const SizedBox(width: 16),
          _summaryChip(
            Icons.currency_rupee,
            fmt.format(totalGrandTotal),
            'Total Value',
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.isMobileOnly(context) ? 12 : 16,
          vertical: AppTheme.isMobileOnly(context) ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: AppTheme.isMobileOnly(context) ? 20 : 24,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.isMobileOnly(context) ? 15 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppTheme.isMobileOnly(context) ? 11 : 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        AppTheme.isMobileOnly(context) ? 16 : 24,
        12,
        AppTheme.isMobileOnly(context) ? 16 : 24,
        12,
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by invoice no. or receiver...',
          prefixIcon: Icon(
            Icons.search,
            size: AppTheme.isMobileOnly(context) ? 20 : 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: AppTheme.isMobileOnly(context) ? 18 : 22,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: AppTheme.isMobileOnly(context) ? 72 : 90,
            color: AppTheme.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No B2B invoices yet',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first invoice',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: AppTheme.isMobileOnly(context) ? 64 : 80,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load invoices',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppTheme.isMobileOnly(context) ? 16 : 24,
        12,
        AppTheme.isMobileOnly(context) ? 16 : 24,
        100,
      ),
      itemCount: _filteredInvoices.length,
      itemBuilder: (_, i) => _buildInvoiceCard(_filteredInvoices[i]),
    );
  }

  Widget _buildInvoiceCard(B2BInvoice invoice) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final moneyFmt = NumberFormat('#,##0.00', 'en_IN');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.elevationSmall,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openPreview(invoice),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.isMobileOnly(context) ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invoice.invoiceNumber,
                      style: TextStyle(
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.isMobileOnly(context) ? 13 : 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFmt.format(invoice.date),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _editInvoice(invoice);
                      if (v == 'delete') _deleteInvoice(invoice);
                      if (v == 'preview') _openPreview(invoice);
                      if (v == 'status') _changeStatus(invoice);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Preview / Print'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 18),
                            SizedBox(width: 8),
                            Text('Change Status'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                invoice.receiverName.isNotEmpty
                    ? invoice.receiverName
                    : 'Unnamed Receiver',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppTheme.isMobileOnly(context) ? 15 : 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (invoice.receiverAddress.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  invoice.receiverAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoChip(
                    '${invoice.items.length} items',
                    Icons.inventory_2_outlined,
                  ),
                  const SizedBox(width: 8),
                  _infoChip(
                    '${invoice.totalQuantity.toInt()} Nos',
                    Icons.numbers_outlined,
                  ),
                  const SizedBox(width: 8),
                  // ── Status badge (tappable) ──
                  GestureDetector(
                    onTap: () => _changeStatus(invoice),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          invoice.status,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _statusColor(
                            invoice.status,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcon(invoice.status),
                            size: AppTheme.isMobileOnly(context) ? 13 : 16,
                            color: _statusColor(invoice.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            B2BInvoice.statusLabel(invoice.status),
                            style: TextStyle(
                              color: _statusColor(invoice.status),
                              fontSize: AppTheme.isMobileOnly(context)
                                  ? 11
                                  : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${moneyFmt.format(invoice.grandTotal)}',
                      style: TextStyle(
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.isMobileOnly(context) ? 14 : 17,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppTheme.isMobileOnly(context) ? 13 : 16,
          color: AppTheme.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
