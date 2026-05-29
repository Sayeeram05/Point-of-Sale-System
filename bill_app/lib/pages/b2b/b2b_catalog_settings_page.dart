import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/b2b_product_override.dart';
import '../../models/b2b_settings.dart';
import '../../services/api_service.dart';
import '../../services/b2b_storage_service.dart';
import '../../theme/app_theme.dart';

class B2BCatalogSettingsPage extends StatefulWidget {
  final B2BSettings settings;
  const B2BCatalogSettingsPage({super.key, required this.settings});

  @override
  State<B2BCatalogSettingsPage> createState() => _B2BCatalogSettingsPageState();
}

class _B2BCatalogSettingsPageState extends State<B2BCatalogSettingsPage> {
  List<B2BProductOverride> _catalog = [];
  bool _isLoading = true;
  bool _hasChanges = false;
  String _error = '';
  String _filterQuery = '';
  final _searchCtrl = TextEditingController();

  // inline editing controllers: keyed by productId
  final Map<String, TextEditingController> _rateCtrl = {};
  final Map<String, TextEditingController> _hsnCtrl = {};

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _rateCtrl.values) {
      c.dispose();
    }
    for (final c in _hsnCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final menu = await ApiService.getMenu();

      // Collect all ice-stick products
      final apiProducts = menu.products
          .map((p) => (productId: p.productId, name: p.name, price: p.price))
          .toList();

      // Collect all tub categories (with per-product prices)
      final tubCategories = menu.tubs?.categories ?? [];

      final catalog = await B2BStorageService.mergeWithApiProducts(
        apiProducts,
        tubCategories: tubCategories,
      );

      _buildControllers(catalog);
      setState(() {
        _catalog = catalog;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback: load only from local storage
      try {
        final catalog = await B2BStorageService.loadCatalog();
        _buildControllers(catalog);
        setState(() {
          _catalog = catalog;
          _isLoading = false;
          _error = 'Offline – showing saved data';
        });
      } catch (_) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _buildControllers(List<B2BProductOverride> catalog) {
    for (final p in catalog) {
      _rateCtrl[p.productId] ??= TextEditingController(
        text: p.b2bRateInclTax != null && p.b2bRateInclTax! > 0
            ? p.b2bRateInclTax!.toStringAsFixed(2)
            : '',
      );
      _hsnCtrl[p.productId] ??= TextEditingController(text: p.hsnCode ?? '');
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    // Flush controller values back into catalog
    for (final p in _catalog) {
      p.b2bRateInclTax = double.tryParse(_rateCtrl[p.productId]?.text ?? '');
      final hsn = _hsnCtrl[p.productId]?.text.trim() ?? '';
      p.hsnCode = hsn.isEmpty ? null : hsn;
      p.gstPercent = 0.0;
    }
    await B2BStorageService.saveCatalog(_catalog);
    setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('B2B product catalog saved!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // signal parent to reload
    }
  }

  // ─── Bulk actions ─────────────────────────────────────────────────────────

  void _setFilteredHsn(String hsn, String type) {
    for (final p in _catalog.where((p) => p.productType == type)) {
      _hsnCtrl[p.productId]?.text = hsn;
    }
    setState(() => _hasChanges = true);
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  List<B2BProductOverride> get _filtered {
    final all = _filterQuery.isEmpty
        ? _catalog
        : _catalog
              .where(
                (p) => p.productName.toLowerCase().contains(
                  _filterQuery.toLowerCase(),
                ),
              )
              .toList();
    return all;
  }

  List<B2BProductOverride> get _filteredSticks =>
      _filtered.where((p) => p.isStick).toList();

  List<B2BProductOverride> get _filteredTubs =>
      _filtered.where((p) => p.isTub).toList();

  @override
  Widget build(BuildContext context) {
    final stickCount = _catalog.where((p) => p.isStick).length;
    final tubCount = _catalog.where((p) => p.isTub).length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('B2B Product Catalog'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          actions: [
            if (!_isLoading)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh from server',
                onPressed: _loadCatalog,
              ),
            TextButton.icon(
              onPressed: _hasChanges ? _save : null,
              icon: Icon(
                Icons.save,
                color: _hasChanges ? Colors.white : Colors.white38,
                size: 18,
              ),
              label: Text(
                'Save',
                style: TextStyle(
                  color: _hasChanges ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.icecream_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('Sticks ($stickCount)'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.kitchen_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('Tubs ($tubCount)'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTopBar(),
                  if (_error.isNotEmpty)
                    Container(
                      color: Colors.amber[100],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [_buildSticksList(), _buildTubsList()],
                    ),
                  ),
                  _buildBottomSaveBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFF1565C0),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search product...',
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white54,
                size: AppTheme.isMobileOnly(context) ? 18 : 22,
              ),
              suffixIcon: _filterQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white54,
                        size: AppTheme.isMobileOnly(context) ? 16 : 20,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _filterQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _filterQuery = v),
          ),
          const SizedBox(height: 8),
          // Bulk actions row
          Builder(
            builder: (ctx) {
              final tabIdx = DefaultTabController.of(ctx).index;
              final type = tabIdx == 0 ? 'stick' : 'tub';
              return Row(
                children: [
                  const Text(
                    'Bulk set:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  _bulkButton(
                    'HSN for tab',
                    () => _showBulkDialog(
                      'Set HSN Code for ${type == 'stick' ? 'Sticks' : 'Tubs'}',
                      'HSN Code',
                      TextInputType.number,
                      (v) => _setFilteredHsn(v, type),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bulkButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: AppTheme.isMobileOnly(context) ? 11 : 14,
          ),
        ),
      ),
    );
  }

  void _showBulkDialog(
    String title,
    String fieldLabel,
    TextInputType keyboard,
    void Function(String) onConfirm,
  ) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          autofocus: true,
          decoration: InputDecoration(
            labelText: fieldLabel,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onConfirm(ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildSticksList() {
    final items = _filteredSticks;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No sticks found',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: items.length,
      itemBuilder: (_, i) => _productCard(items[i], i + 1),
    );
  }

  Widget _buildTubsList() {
    final tubItems = _filteredTubs;
    if (tubItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.kitchen_outlined,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 8),
            const Text(
              'No tub products found',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              _catalog.any((p) => p.isTub)
                  ? 'Try clearing the search filter'
                  : 'Tub categories will appear here once the server returns them',
              style: TextStyle(
                fontSize: AppTheme.isMobileOnly(context) ? 12 : 14,
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group by category
    final Map<String, List<B2BProductOverride>> grouped = {};
    for (final p in tubItems) {
      final cat = p.categoryName ?? 'Uncategorised';
      grouped.putIfAbsent(cat, () => []).add(p);
    }

    // Build a flat list: category-header + product cards
    final List<Widget> rows = [];
    int globalIndex = 0;
    for (final entry in grouped.entries) {
      rows.add(_tubCategoryHeader(entry.key, entry.value.length));
      for (final p in entry.value) {
        globalIndex++;
        rows.add(_productCard(p, globalIndex));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      children: rows,
    );
  }

  Widget _tubCategoryHeader(String name, int count) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.kitchen_outlined,
            size: 16,
            color: Color(0xFF1565C0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.isMobileOnly(context) ? 13 : 16,
                color: const Color(0xFF1565C0),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count products',
              style: TextStyle(
                fontSize: AppTheme.isMobileOnly(context) ? 11 : 14,
                color: const Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(B2BProductOverride p, int index) {
    final rateCtrl = _rateCtrl[p.productId]!;
    final hsnCtrl = _hsnCtrl[p.productId]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: p.enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.enabled ? AppTheme.borderLight : AppTheme.borderMedium,
        ),
        boxShadow: p.enabled ? AppTheme.elevationSmall : [],
      ),
      child: Column(
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // index badge
                Container(
                  width: AppTheme.isMobileOnly(context) ? 26 : 32,
                  height: AppTheme.isMobileOnly(context) ? 26 : 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.enabled
                        ? const Color(0xFF1565C0).withValues(alpha: 0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: AppTheme.isMobileOnly(context) ? 11 : 14,
                      fontWeight: FontWeight.bold,
                      color: p.enabled ? const Color(0xFF1565C0) : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppTheme.isMobileOnly(context) ? 13 : 16,
                          color: p.enabled
                              ? AppTheme.textPrimary
                              : AppTheme.textTertiary,
                        ),
                      ),
                      Text(
                        'B2C Rate: ₹${p.b2cPrice}',
                        style: TextStyle(
                          fontSize: AppTheme.isMobileOnly(context) ? 11 : 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Enable toggle
                Switch(
                  value: p.enabled,
                  activeThumbColor: const Color(0xFF1565C0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) {
                    setState(() {
                      p.enabled = v;
                      _hasChanges = true;
                    });
                  },
                ),
              ],
            ),
          ),
          if (p.enabled) ...[
            const Divider(height: 1),
            // ── Field row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  // B2B Rate
                  Expanded(
                    flex: 3,
                    child: _compactField(
                      rateCtrl,
                      'B2B Rate',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefix: '₹',
                      hint: p.b2cPrice,
                      onChanged: (_) => setState(() => _hasChanges = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // HSN Code
                  Expanded(
                    flex: 3,
                    child: _compactField(
                      hsnCtrl,
                      'HSN Code',
                      keyboard: TextInputType.number,
                      hint: 'None',
                      onChanged: (_) => setState(() => _hasChanges = true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactField(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboard = TextInputType.text,
    String? prefix,
    String? suffix,
    String? hint,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.isMobileOnly(context) ? 10 : 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          onChanged: onChanged,
          inputFormatters: [
            if (keyboard == TextInputType.number ||
                keyboard ==
                    const TextInputType.numberWithOptions(decimal: true))
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: TextStyle(fontSize: AppTheme.isMobileOnly(context) ? 13 : 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: AppTheme.isMobileOnly(context) ? 11 : 14,
              color: AppTheme.textTertiary,
            ),
            prefixText: prefix,
            suffixText: suffix,
            isDense: true,
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppTheme.isMobileOnly(context) ? 8 : 12,
              vertical: AppTheme.isMobileOnly(context) ? 7 : 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSaveBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: Row(
          children: [
            Text(
              '${_catalog.where((p) => p.enabled).length} of ${_catalog.length} enabled',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.isMobileOnly(context) ? 13 : 16,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _hasChanges ? _save : null,
              icon: Icon(
                Icons.save,
                size: AppTheme.isMobileOnly(context) ? 18 : 22,
              ),
              label: const Text('Save Catalog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.borderMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
