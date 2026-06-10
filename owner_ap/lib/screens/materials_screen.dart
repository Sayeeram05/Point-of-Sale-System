import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/materials_models.dart';
import '../providers/materials_provider.dart';
import '../theme/waffle_theme.dart';

// ============================================================================
//  MaterialsScreen — top-level entry point
// ============================================================================

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialsProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Date helpers
  // ---------------------------------------------------------------------------

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmtShort(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  String _fmtFull(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  String _fmtApi(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer<MaterialsProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            _buildDateHeader(context, provider),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(WaffleTheme.spacingM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _buildLeftPanel(context, provider)),
                    const SizedBox(width: WaffleTheme.spacingM),
                    Expanded(flex: 4, child: _buildRightPanel(context, provider)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  //  DATE HEADER
  // ============================================================================

  Widget _buildDateHeader(BuildContext context, MaterialsProvider provider) {
    final today = DateTime.now();
    final isToday = _sameDay(provider.selectedDate, today);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        WaffleTheme.spacingL, WaffleTheme.spacingM,
        WaffleTheme.spacingL, WaffleTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: WaffleTheme.cardBackground,
        border: Border(bottom: BorderSide(color: WaffleTheme.border)),
        boxShadow: WaffleTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row + action buttons ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: WaffleTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: WaffleTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Materials Tracking & Procurement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: WaffleTheme.textDark,
                            )),
                    Text('Track daily raw material purchases and costs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: WaffleTheme.textLight,
                            )),
                  ],
                ),
              ),
              _buildActionButtons(context, provider),
            ],
          ),
          const SizedBox(height: WaffleTheme.spacingM),
          // ── Date selector row ──
          Row(
            children: [
              _dateChip(
                label: 'Today',
                isSelected: isToday,
                onTap: () => provider.loadRecordForDate(DateTime.now()),
              ),
              const SizedBox(width: WaffleTheme.spacingS),
              _dateChip(
                label: '📅  Custom',
                isSelected: !isToday,
                onTap: () => _pickDate(context, provider),
              ),
              const SizedBox(width: WaffleTheme.spacingM),
              Container(width: 1, height: 32, color: WaffleTheme.border),
              const SizedBox(width: WaffleTheme.spacingM),
              Expanded(
                child: provider.recentDates.isEmpty
                    ? const Center(
                        child: Text(
                          'No past entries yet.',
                          style: TextStyle(
                              color: WaffleTheme.textMuted, fontSize: 12),
                        ),
                      )
                    : SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.recentDates.length,
                          separatorBuilder: (sc, si) =>
                              const SizedBox(width: 6),
                          itemBuilder: (ctx, i) {
                            final d = DateTime.parse(
                                provider.recentDates[i]);
                            final sel =
                                _sameDay(provider.selectedDate, d);
                            return _dayChip(
                              date: d,
                              isSelected: sel,
                              hasRecord: true,
                              onTap: () =>
                                  provider.loadRecordForDate(d),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: WaffleTheme.fastAnimation,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? WaffleTheme.primaryGradient : null,
          color: isSelected ? null : WaffleTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? WaffleTheme.primary : WaffleTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? WaffleTheme.creamWhite : WaffleTheme.textDark,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _dayChip({
    required DateTime date,
    required bool isSelected,
    required bool hasRecord,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected
        ? WaffleTheme.primary
        : hasRecord
            ? WaffleTheme.success.withValues(alpha: 0.55)
            : WaffleTheme.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: WaffleTheme.fastAnimation,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: isSelected ? WaffleTheme.primaryGradient : null,
          color: isSelected ? null : WaffleTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _fmtShort(date),
              style: TextStyle(
                color:
                    isSelected ? WaffleTheme.creamWhite : WaffleTheme.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasRecord && !isSelected)
              Container(
                width: 4, height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: WaffleTheme.success, shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext ctx, MaterialsProvider provider) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: ColorScheme.light(
            primary: WaffleTheme.primary,
            onPrimary: WaffleTheme.creamWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) provider.loadRecordForDate(picked);
  }

  // ============================================================================
  //  ACTION BUTTONS
  // ============================================================================

  Widget _buildActionButtons(BuildContext ctx, MaterialsProvider provider) {
    if (provider.isSaving) {
      return const SizedBox(
        width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (provider.isLocked) {
      return Row(children: [
        _actionBtn(
          label: 'Edit',
          icon: Icons.edit_rounded,
          color: WaffleTheme.primary,
          onTap: provider.enterEditMode,
        ),
        const SizedBox(width: WaffleTheme.spacingS),
        _actionBtn(
          label: 'Save PDF',
          icon: Icons.picture_as_pdf_rounded,
          color: WaffleTheme.success,
          onTap: () => _generateAndPrint(ctx, provider),
        ),
      ]);
    }
    return Row(children: [
      _actionBtn(
        label: 'Save',
        icon: Icons.save_rounded,
        color: WaffleTheme.success,
        onTap: () => _saveRecord(ctx, provider),
      ),
      const SizedBox(width: WaffleTheme.spacingS),
      _actionBtn(
        label: 'Cancel',
        icon: Icons.cancel_rounded,
        color: WaffleTheme.error,
        onTap: provider.cancelEdits,
      ),
    ]);
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  // ============================================================================
  //  LEFT PANEL — Purchase Grid
  // ============================================================================

  Widget _buildLeftPanel(BuildContext ctx, MaterialsProvider provider) {
    final locked = provider.isLocked;

    return Container(
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFF5F1E8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WaffleTheme.border, width: 1.5),
        boxShadow: WaffleTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header
          _panelHeader(
            icon: locked ? Icons.lock_rounded : Icons.edit_note_rounded,
            iconColor: locked ? WaffleTheme.textLight : WaffleTheme.primary,
            title: locked
                ? 'Purchase Record — View Mode'
                : 'Purchase Record — Edit Mode',
            trailing: Text(
              _fmtFull(provider.selectedDate),
              style: const TextStyle(
                  color: WaffleTheme.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
            gradientColors: [
              WaffleTheme.primary.withValues(alpha: 0.10),
              WaffleTheme.secondary.withValues(alpha: 0.04),
            ],
            isTop: true,
          ),

          // Column headers
          _buildGridHeader(locked),

          // Rows
          Expanded(
            child: provider.purchaseItems.isEmpty
                ? _buildGridEmptyState(locked)
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: provider.purchaseItems.length,
                    separatorBuilder: (sc, si) => Divider(
                      height: 1,
                      color: WaffleTheme.border.withValues(alpha: 0.45),
                    ),
                    itemBuilder: (c, i) => _PurchaseGridRow(
                      index: i,
                      item: provider.purchaseItems[i],
                      quantity: provider.purchaseItems[i].quantity,
                      isLocked: locked,
                      onQtyChanged: provider.updateItemQuantity,
                      onRemove: provider.removeItem,
                    ),
                  ),
          ),

          // Total banner — always visible
          _buildTotalBanner(provider),
        ],
      ),
    );
  }

  Widget _buildGridHeader(bool isLocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: WaffleTheme.textDark.withValues(alpha: 0.05),
        border: Border(
            bottom: BorderSide(
                color: WaffleTheme.border.withValues(alpha: 0.7))),
      ),
      child: Row(children: [
        _hCell('S.No', flex: 1),
        _hCell('Material Name', flex: 4),
        _hCell('Base Price', flex: 2),
        _hCell('Quantity', flex: isLocked ? 2 : 3),
        _hCell('Subtotal', flex: 2),
        if (!isLocked) _hCell('', flex: 1),
      ]),
    );
  }

  Widget _hCell(String label, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WaffleTheme.textDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );

  Widget _buildGridEmptyState(bool locked) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WaffleTheme.spacingXL),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            locked
                ? Icons.lock_outline_rounded
                : Icons.add_shopping_cart_rounded,
            size: 52,
            color: WaffleTheme.border,
          ),
          const SizedBox(height: WaffleTheme.spacingM),
          Text(
            locked
                ? 'No purchase record for this date.'
                : 'Tap a material from the catalog\nto add it to the purchase list.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: WaffleTheme.textMuted, fontSize: 14),
          ),
        ]),
      ),
    );
  }

  Widget _buildTotalBanner(MaterialsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: WaffleTheme.spacingM, vertical: WaffleTheme.spacingS),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          WaffleTheme.success.withValues(alpha: 0.12),
          WaffleTheme.success.withValues(alpha: 0.05),
        ]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(
              color: WaffleTheme.success.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.calculate_rounded,
                color: WaffleTheme.success, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Total Material Cost',
              style: TextStyle(
                  color: WaffleTheme.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ]),
          Text(
            '₹${provider.totalCost.toStringAsFixed(2)}',
            style: const TextStyle(
              color: WaffleTheme.success,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  //  RIGHT PANEL — Material Catalog
  // ============================================================================

  Widget _buildRightPanel(BuildContext ctx, MaterialsProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: WaffleTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WaffleTheme.border, width: 1.5),
        boxShadow: WaffleTheme.cardShadow,
      ),
      child: Column(children: [
        _panelHeader(
          icon: Icons.category_rounded,
          iconColor: WaffleTheme.secondary,
          title: 'Material Catalog',
          trailing: _addNewBtn(ctx, provider),
          gradientColors: [
            WaffleTheme.secondary.withValues(alpha: 0.10),
            WaffleTheme.waffleGold.withValues(alpha: 0.04),
          ],
          isTop: true,
        ),
        Expanded(
          child: provider.catalogLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.catalog.isEmpty
                  ? _buildCatalogEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.catalog.length,
                      separatorBuilder: (sc, si) =>
                          const SizedBox(height: 8),
                      itemBuilder: (c, i) =>
                          _buildCatalogCard(ctx, provider, provider.catalog[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _addNewBtn(BuildContext ctx, MaterialsProvider provider) {
    return GestureDetector(
      onTap: () => _showMaterialDialog(ctx, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: WaffleTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_rounded, color: Colors.white, size: 13),
          SizedBox(width: 4),
          Text('Add New',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _buildCatalogCard(
      BuildContext ctx, MaterialsProvider provider, RawMaterial material) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onCatalogTap(ctx, provider, material),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: WaffleTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WaffleTheme.border),
          ),
          child: Row(children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  WaffleTheme.softOrange,
                  WaffleTheme.secondary.withValues(alpha: 0.28),
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.grain_rounded,
                  color: WaffleTheme.textDark, size: 20),
            ),
            const SizedBox(width: 10),
            // Name + price
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(material.name,
                        style: const TextStyle(
                          color: WaffleTheme.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                    Text(material.formattedPrice,
                        style: const TextStyle(
                            color: WaffleTheme.textLight, fontSize: 11)),
                  ]),
            ),
            // Micro-actions
            Row(mainAxisSize: MainAxisSize.min, children: [
              _microAction(Icons.edit_rounded, WaffleTheme.primary, 'Edit',
                  () => _showMaterialDialog(ctx, provider, existing: material)),
              const SizedBox(width: 4),
              _microAction(Icons.delete_rounded, WaffleTheme.error, 'Delete',
                  () => _confirmDelete(ctx, provider, material)),
              const SizedBox(width: 4),
              _microAction(Icons.add_rounded, WaffleTheme.success, 'Add to list',
                  () => _onCatalogTap(ctx, provider, material)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _onCatalogTap(
      BuildContext ctx, MaterialsProvider provider, RawMaterial material) {
    if (provider.isLocked) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Unlock editing to modify data.'),
          ]),
          backgroundColor: WaffleTheme.textDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    provider.addOrIncrementItem(material);
  }

  Widget _microAction(
      IconData icon, Color color, String tip, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }

  Widget _buildCatalogEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WaffleTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 52, color: WaffleTheme.border),
            const SizedBox(height: WaffleTheme.spacingM),
            const Text(
              'No materials in catalog yet.\nTap "Add New" to create one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WaffleTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  //  SHARED HELPER: panel header
  // ============================================================================

  Widget _panelHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    required List<Color> gradientColors,
    bool isTop = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: WaffleTheme.spacingM, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: isTop
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16))
            : null,
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: WaffleTheme.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        const Spacer(),
        trailing,
      ]),
    );
  }

  // ============================================================================
  //  DIALOGS
  // ============================================================================

  void _showMaterialDialog(BuildContext ctx, MaterialsProvider provider,
      {RawMaterial? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.basePrice.toStringAsFixed(2) ?? '');
    final unitCtrl =
        TextEditingController(text: existing?.unit ?? 'kg');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: WaffleTheme.cardBackground,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: WaffleTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              existing == null ? Icons.add_rounded : Icons.edit_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            existing == null ? 'Add Raw Material' : 'Edit Material',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ]),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 340,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dlgField('Material Name', nameCtrl,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Name is required' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  flex: 3,
                  child: _dlgField(
                    'Base Price (₹)',
                    priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => double.tryParse(v!) == null
                        ? 'Enter a valid number'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _dlgField('Unit (e.g. kg)', unitCtrl,
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Required' : null),
                ),
              ]),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = existing == null
                  ? await provider.createRawMaterial(
                      name: nameCtrl.text.trim(),
                      unit: unitCtrl.text.trim(),
                      basePrice: double.parse(priceCtrl.text),
                    )
                  : await provider.updateRawMaterial(
                      id: existing.id,
                      name: nameCtrl.text.trim(),
                      unit: unitCtrl.text.trim(),
                      basePrice: double.parse(priceCtrl.text),
                    );
              if (dlgCtx.mounted) Navigator.pop(dlgCtx);
              if (!ok && provider.error != null && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(provider.error!),
                  backgroundColor: WaffleTheme.error,
                ));
              }
            },
            child: Text(existing == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Widget _dlgField(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: WaffleTheme.primary, width: 1.5),
        ),
        isDense: true,
      ),
    );
  }

  void _confirmDelete(
      BuildContext ctx, MaterialsProvider provider, RawMaterial material) {
    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: WaffleTheme.cardBackground,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Material?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            Text('Remove "${material.name}" from the catalog?\nThis action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: WaffleTheme.error,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await provider.deleteRawMaterial(material.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  //  SAVE + PDF
  // ============================================================================

  Future<void> _saveRecord(BuildContext ctx, MaterialsProvider provider) async {
    final ok = await provider.saveRecord(_notesCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Purchase record saved successfully!'
          : provider.error ?? 'Save failed.'),
      backgroundColor: ok ? WaffleTheme.success : WaffleTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _generateAndPrint(
      BuildContext ctx, MaterialsProvider provider) async {
    final items = provider.purchaseItems;
    final dateStr = _fmtFull(provider.selectedDate);
    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        // ── Header ──
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('E67E22'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('WAFFLE DAY',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('Materials Purchase Record',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 11)),
                ],
              ),
              pw.Text('Date: $dateStr',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        // ── Table ──
        pw.Table(
          border: pw.TableBorder.all(
              color: PdfColor.fromHex('E8DCC6'), width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(4),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('FDF0E0')),
              children: [
                _pdfHCell('S.No'),
                _pdfHCell('Material Name'),
                _pdfHCell('Base Price'),
                _pdfHCell('Qty'),
                _pdfHCell('Subtotal'),
              ],
            ),
            // Data rows
            ...items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final bg = i.isOdd
                  ? PdfColor.fromHex('FFFAF0')
                  : PdfColors.white;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bg),
                children: [
                  _pdfCell('${i + 1}'),
                  _pdfCell(item.materialName),
                  _pdfCell('Rs. ${item.basePrice.toStringAsFixed(2)}'),
                  _pdfCell(item.displayQty),
                  _pdfCell('Rs. ${item.subtotal.toStringAsFixed(2)}'),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 14),
        // ── Total ──
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('EAF7F0'),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(
                color: PdfColor.fromHex('27AE60'), width: 0.8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Material Cost',
                  style: pw.TextStyle(
                      color: PdfColor.fromHex('27AE60'),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13)),
              pw.Text(
                  'Rs. ${provider.totalCost.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      color: PdfColor.fromHex('27AE60'),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 17)),
            ],
          ),
        ),
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'waffle_materials_${_fmtApi(provider.selectedDate)}.pdf',
    );
  }

  pw.Widget _pdfHCell(String t) => pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Text(t,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)),
      );

  pw.Widget _pdfCell(String t) => pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Text(t,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10)),
      );
}

// ============================================================================
//  _PurchaseGridRow — self-contained row widget with its own qty controller
// ============================================================================

class _PurchaseGridRow extends StatefulWidget {
  final int index;
  final PurchaseLineItem item;
  final double quantity;
  final bool isLocked;
  final void Function(int index, double qty) onQtyChanged;
  final void Function(int index) onRemove;

  const _PurchaseGridRow({
    required this.index,
    required this.item,
    required this.quantity,
    required this.isLocked,
    required this.onQtyChanged,
    required this.onRemove,
  });

  @override
  State<_PurchaseGridRow> createState() => _PurchaseGridRowState();
}

class _PurchaseGridRowState extends State<_PurchaseGridRow> {
  late TextEditingController _ctrl;

  String _fmt(double qty) => qty == qty.truncateToDouble()
      ? qty.toStringAsFixed(0)
      : qty.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.quantity));
  }

  @override
  void didUpdateWidget(_PurchaseGridRow old) {
    super.didUpdateWidget(old);
    // Use widget.quantity (a plain double) so the comparison works even
    // when item is the same mutable object mutated in-place by the provider.
    if (old.quantity != widget.quantity) {
      final newText = _fmt(widget.quantity);
      if (_ctrl.text != newText) {
        _ctrl.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.isLocked;
    final item = widget.item;
    final idx = widget.index;

    return Container(
      color: idx.isOdd
          ? WaffleTheme.background.withValues(alpha: 0.45)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(children: [
        // S.No
        Expanded(
          flex: 1,
          child: Text('${idx + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: WaffleTheme.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        // Name
        Expanded(
          flex: 4,
          child: Text(item.materialName,
              style: const TextStyle(
                  color: WaffleTheme.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        // Base Price
        Expanded(
          flex: 2,
          child: Text(item.formattedBasePrice,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: WaffleTheme.textDark, fontSize: 12)),
        ),
        // Quantity (interactive or read-only)
        Expanded(
          flex: locked ? 2 : 3,
          child: locked
              ? Text(item.displayQty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: WaffleTheme.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600))
              : _buildQtyInput(idx),
        ),
        // Subtotal
        Expanded(
          flex: 2,
          child: Text(item.formattedSubtotal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: WaffleTheme.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
        // Delete (edit mode only)
        if (!locked)
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                onPressed: () => widget.onRemove(idx),
                icon: const Icon(Icons.delete_rounded,
                    color: WaffleTheme.error, size: 18),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove',
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildQtyInput(int idx) {
    final qty = widget.quantity;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _qtyBtn(
        icon: Icons.remove,
        onTap: () {
          final nq = qty - 1;
          if (nq > 0) {
            widget.onQtyChanged(idx, nq);
          } else {
            widget.onRemove(idx);
          }
        },
      ),
      const SizedBox(width: 4),
      SizedBox(
        width: 52,
        child: TextFormField(
          controller: _ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: WaffleTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: WaffleTheme.primary, width: 1.5),
            ),
            isDense: true,
          ),
          onChanged: (val) {
            final q = double.tryParse(val);
            if (q != null && q > 0) widget.onQtyChanged(idx, q);
          },
        ),
      ),
      const SizedBox(width: 4),
      _qtyBtn(
        icon: Icons.add,
        onTap: () => widget.onQtyChanged(idx, qty + 1),
      ),
    ]);
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: WaffleTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: WaffleTheme.primary.withValues(alpha: 0.30)),
        ),
        child: Icon(icon, size: 14, color: WaffleTheme.primary),
      ),
    );
  }
}
