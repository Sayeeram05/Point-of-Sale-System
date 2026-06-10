import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/waffle_theme.dart';
import '../widgets/waffle_card.dart';
import '../widgets/waffle_button.dart';

/// Materials screen for managing raw material versions with 2-card layout
class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<MaterialVersionsProvider>();
    await Future.wait([
      provider.loadVersionForDate(provider.selectedDate),
      provider.loadAvailableMaterials(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(WaffleTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date picker and action buttons
            _buildHeader(),
            const SizedBox(height: WaffleTheme.spacingL),
            
            // Main content with 2-card layout
            Expanded(
              child: _buildTwoCardLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<MaterialVersionsProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Materials Management',
                    style: WaffleTheme.theme.textTheme.headlineMedium?.copyWith(
                      color: WaffleTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version-based material configuration',
                    style: WaffleTheme.theme.textTheme.bodyMedium?.copyWith(
                      color: WaffleTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            
            // Date selector
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDateButton(
                  label: 'Today',
                  isSelected: _isToday(provider.selectedDate),
                  onTap: () => provider.setSelectedDate(DateTime.now()),
                ),
                const SizedBox(width: WaffleTheme.spacingS),
                _buildDatePickerButton(provider),
              ],
            ),
            
            const SizedBox(width: WaffleTheme.spacingL),
            
            // Action buttons
            _buildActionButtons(provider),
          ],
        );
      },
    );
  }

  Widget _buildDateButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WaffleTheme.spacingM,
            vertical: WaffleTheme.spacingS,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? WaffleTheme.primaryGradient : null,
            color: isSelected ? null : WaffleTheme.background,
            borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
            border: Border.all(
              color: isSelected ? WaffleTheme.primary : WaffleTheme.border,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? WaffleTheme.creamWhite : WaffleTheme.textDark,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(MaterialVersionsProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add Material button
        WaffleButton(
          text: 'Add Material',
          icon: Icons.add,
          onPressed: () => _showAddMaterialDialog(provider),
          type: WaffleButtonType.primary,
        ),
        
        const SizedBox(width: WaffleTheme.spacingS),
        
        // Save button
        WaffleButton(
          text: 'Save',
          icon: Icons.save,
          onPressed: provider.canSave ? () => _handleSave(provider) : null,
          type: WaffleButtonType.primary,
        ),
        
        if (!provider.isEditing && provider.currentVersion != null) ...[
          const SizedBox(width: WaffleTheme.spacingS),
          // Edit button
          WaffleButton(
            text: 'Edit',
            icon: Icons.edit,
            onPressed: () => provider.startEditing(),
            type: WaffleButtonType.secondary,
          ),
          
          const SizedBox(width: WaffleTheme.spacingS),
          // Delete button
          WaffleButton(
            text: 'Delete',
            icon: Icons.delete,
            onPressed: () => _showDeleteConfirmation(provider),
            type: WaffleButtonType.outline,
          ),
        ],
      ],
    );
  }

  Widget _buildTwoCardLayout() {
    return Consumer<MaterialVersionsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.selectedMaterials.isEmpty && provider.availableMaterials.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Card - Selected Raw Materials
              Expanded(
                flex: 3,
                child: _buildSelectedMaterialsCard(provider),
              ),
              
              const SizedBox(width: 20),
              
              // Right Card - Available Products
              Expanded(
                flex: 2,
                child: _buildAvailableProductsCard(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatePickerButton(MaterialVersionsProvider provider) {
    final isCustom = !_isToday(provider.selectedDate);
    final dateStr = DateFormat('MMM dd, yyyy').format(provider.selectedDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDatePicker(provider),
        borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WaffleTheme.spacingM,
            vertical: WaffleTheme.spacingS,
          ),
          decoration: BoxDecoration(
            gradient: isCustom ? WaffleTheme.primaryGradient : null,
            color: isCustom ? null : WaffleTheme.background,
            borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
            border: Border.all(
              color: isCustom ? WaffleTheme.primary : WaffleTheme.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: isCustom ? WaffleTheme.creamWhite : WaffleTheme.textDark,
              ),
              const SizedBox(width: 8),
              Text(
                isCustom ? dateStr : 'Custom',
                style: TextStyle(
                  color: isCustom ? WaffleTheme.creamWhite : WaffleTheme.textDark,
                  fontWeight: isCustom ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMaterialsCard(MaterialVersionsProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selected Materials',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (provider.isEditing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Editing',
                          style: TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: Color(0xFFF3F4F6),
          ),
          
          // Materials table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildSelectedMaterialsTable(provider),
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: Color(0xFFF3F4F6),
          ),
          
          // Total row
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildTotalRow(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMaterialsTable(MaterialVersionsProvider provider) {
    if (provider.selectedMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: WaffleTheme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No materials selected yet',
              style: TextStyle(
                color: WaffleTheme.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click product buttons in the right card to add materials',
              style: TextStyle(
                color: WaffleTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: WaffleTheme.border),
        borderRadius: BorderRadius.circular(WaffleTheme.cardRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WaffleTheme.cardRadius),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 0,
            headingRowColor: WidgetStateProperty.all(Color(0xFFF9FAFB)),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 48,
            border: TableBorder.symmetric(
              inside: BorderSide(color: Color(0xFFF3F4F6), width: 1),
              outside: BorderSide.none,
            ),
            columns: const [
              DataColumn(
                label: Text('S.No', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151))),
                numeric: true,
              ),
              DataColumn(
                label: Text('Material Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151))),
              ),
              DataColumn(
                label: Text('Qty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151))),
                numeric: true,
              ),
              DataColumn(
                label: Text('Price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151))),
                numeric: true,
              ),
              DataColumn(
                label: Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151))),
                numeric: true,
              ),
              DataColumn(
                label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151))),
                numeric: true,
              ),
            ],
            rows: provider.selectedMaterials.asMap().entries.map((entry) {
              final index = entry.key;
              final material = entry.value;
              
              return DataRow(
                color: WidgetStateProperty.all(
                  index % 2 == 0 ? Colors.white : Color(0xFFF9FAFB),
                ),
                cells: [
                  DataCell(
                    Text(
                      '${index + 1}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ),
                  DataCell(
                    Text(
                      material.materialName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                    ),
                  ),
                  DataCell(
                    _buildCompactQuantityCell(material, provider),
                  ),
                  DataCell(
                    Text(
                      material.formattedPrice,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                    ),
                  ),
                  DataCell(
                    Text(
                      '₹${material.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                    ),
                  ),
                  DataCell(
                    _buildCompactActionsCell(material, provider),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableProductsCard(MaterialVersionsProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Available Products',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (provider.isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Click on products to add them to materials',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: Color(0xFFF3F4F6),
          ),
          
          // Available materials buttons
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildAvailableMaterialsButtons(provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableMaterialsButtons(MaterialVersionsProvider provider) {
    if (provider.availableMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: WaffleTheme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No available products',
              style: TextStyle(
                color: WaffleTheme.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Available products will appear here',
              style: TextStyle(
                color: WaffleTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: WaffleTheme.spacingS,
        mainAxisSpacing: WaffleTheme.spacingS,
      ),
      itemCount: provider.availableMaterials.length,
      itemBuilder: (context, index) {
        final material = provider.availableMaterials[index];
        final isSelected = provider.selectedMaterials
            .any((item) => item.materialName == material.name);
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: !isSelected 
              ? () => provider.addMaterial(material) 
              : null,
            borderRadius: BorderRadius.circular(WaffleTheme.cardRadius),
            child: Container(
              padding: const EdgeInsets.all(WaffleTheme.spacingS),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                    ? WaffleTheme.success 
                    : WaffleTheme.primary,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(WaffleTheme.cardRadius),
                color: isSelected 
                  ? WaffleTheme.success.withValues(alpha: 0.1)
                  : WaffleTheme.primary.withValues(alpha: 0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    material.name,
                    style: TextStyle(
                      color: isSelected 
                        ? WaffleTheme.success 
                        : WaffleTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    material.formattedPrice,
                    style: TextStyle(
                      color: isSelected 
                        ? WaffleTheme.success 
                        : WaffleTheme.textLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: WaffleTheme.success,
                      size: 5,
                    )
                  else
                    Icon(
                      Icons.add_circle_outline,
                      color: WaffleTheme.primary,
                      size: 5,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton(AvailableMaterial material, MaterialVersionsProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: provider.isEditing ? () => provider.addMaterial(material) : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: provider.isEditing 
              ? WaffleTheme.primary.withValues(alpha: 0.1)
              : WaffleTheme.textMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.add,
            size: 16,
            color: provider.isEditing ? WaffleTheme.primary : WaffleTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WaffleTheme.spacingM,
        vertical: WaffleTheme.spacingS,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: WaffleTheme.textDark,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isCenter = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WaffleTheme.spacingM,
        vertical: WaffleTheme.spacingS,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: WaffleTheme.textDark,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        textAlign: isCenter ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildQuantityCell(MaterialVersionItem material, MaterialVersionsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          GestureDetector(
            onTap: () {
              provider.decrementMaterialQuantity(material.materialName);
            },
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: WaffleTheme.border),
                borderRadius: BorderRadius.circular(3),
                color: WaffleTheme.background,
              ),
              child: Icon(
                Icons.remove,
                size: 12,
                color: WaffleTheme.primary,
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Quantity display
          Container(
            width: 24,
            height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: WaffleTheme.border),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Text(
                '${material.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Increment button
          GestureDetector(
            onTap: () {
              provider.incrementMaterialQuantity(material.materialName);
            },
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: WaffleTheme.border),
                borderRadius: BorderRadius.circular(3),
                color: WaffleTheme.background,
              ),
              child: Icon(
                Icons.add,
                size: 12,
                color: WaffleTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactQuantityCell(MaterialVersionItem material, MaterialVersionsProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrement button
        GestureDetector(
          onTap: () => provider.decrementMaterialQuantity(material.materialName),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFD1D5DB), width: 1),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Icon(
              Icons.remove,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Quantity display
        Container(
          width: 32,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFD1D5DB), width: 1),
            borderRadius: BorderRadius.circular(4),
            color: Color(0xFFF9FAFB),
          ),
          child: Center(
            child: Text(
              '${material.quantity}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Increment button
        GestureDetector(
          onTap: () => provider.incrementMaterialQuantity(material.materialName),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFD1D5DB), width: 1),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Icon(
              Icons.add,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionsCell(MaterialVersionItem material, MaterialVersionsProvider provider) {
    return GestureDetector(
      onTap: () => provider.removeMaterial(material.materialName),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFD1D5DB), width: 1),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Icon(
          Icons.delete_outline,
          size: 16,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }

  Widget _buildActionsCell(MaterialVersionItem material, MaterialVersionsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WaffleTheme.spacingS,
        vertical: 4,
      ),
      child: _buildActionButton(
        icon: Icons.delete_outline,
        color: WaffleTheme.error,
        onTap: () => provider.removeMaterial(material.materialName),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(MaterialVersionsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(WaffleTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WaffleTheme.success.withValues(alpha: 0.15),
            WaffleTheme.success.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(WaffleTheme.cardRadius),
        border: Border.all(
          color: WaffleTheme.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: WaffleTheme.success,
                size: 24,
              ),
              const SizedBox(width: WaffleTheme.spacingS),
              Text(
                'Total Material Cost',
                style: TextStyle(
                  color: WaffleTheme.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${provider.selectedMaterials.length} items)',
                style: TextStyle(
                  color: WaffleTheme.textLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WaffleTheme.spacingM,
              vertical: WaffleTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: WaffleTheme.creamWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: WaffleTheme.success.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              provider.formattedSelectedTotal,
              style: TextStyle(
                color: WaffleTheme.success,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  Future<void> _showDatePicker(MaterialVersionsProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: WaffleTheme.primary,
              onPrimary: WaffleTheme.creamWhite,
              surface: WaffleTheme.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      provider.setSelectedDate(picked);
    }
  }

  Future<void> _handleSave(MaterialVersionsProvider provider) async {
    final success = provider.isEditing 
      ? await provider.updateConfiguration()
      : await provider.saveConfiguration();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.isEditing ? 'Configuration updated successfully!' : 'Configuration saved successfully!'
          ),
          backgroundColor: WaffleTheme.success,
        ),
      );
    } else if (provider.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'An error occurred'),
          backgroundColor: WaffleTheme.error,
        ),
      );
    }
  }

  void _showAddMaterialDialog(MaterialVersionsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _AddMaterialDialog(
        onAdd: (name, price) => provider.addCustomMaterial(name, price),
      ),
    );
  }

  void _showDeleteConfirmation(MaterialVersionsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaffleTheme.cardRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: WaffleTheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Delete Configuration'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${provider.currentVersion?.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WaffleTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await provider.deleteConfiguration();
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Configuration deleted successfully'),
                    backgroundColor: WaffleTheme.success,
                  ),
                );
              } else if (provider.hasError && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'An error occurred'),
                    backgroundColor: WaffleTheme.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding new materials with custom name and price
class _AddMaterialDialog extends StatefulWidget {
  final Function(String name, double price) onAdd;

  const _AddMaterialDialog({required this.onAdd});

  @override
  State<_AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<_AddMaterialDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();

    // Validation
    if (name.isEmpty) {
      setState(() => _error = 'Material name is required');
      return;
    }

    if (priceText.isEmpty) {
      setState(() => _error = 'Price is required');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      setState(() => _error = 'Please enter a valid price');
      return;
    }

    if (price < 0) {
      setState(() => _error = 'Price cannot be negative');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Call the onAdd callback
    widget.onAdd(name, price);
    
    // Close dialog
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WaffleTheme.cardRadius),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(WaffleTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WaffleTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add,
                    color: WaffleTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: WaffleTheme.spacingM),
                Text(
                  'Add New Material',
                  style: WaffleTheme.theme.textTheme.titleLarge?.copyWith(
                    color: WaffleTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WaffleTheme.spacingL),
            
            // Material name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Material Name',
                hintText: 'e.g., Flour (Wheat), Butter, Eggs',
                labelStyle: TextStyle(
                  color: WaffleTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
                hintStyle: TextStyle(
                  color: WaffleTheme.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.inventory_2_outlined,
                  color: WaffleTheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                  borderSide: BorderSide(color: WaffleTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                  borderSide: BorderSide(color: WaffleTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                  borderSide: BorderSide(color: WaffleTheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: WaffleTheme.spacingM),
            
            // Price field
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (₹)',
                hintText: 'Enter price in rupees',
                labelStyle: TextStyle(
                  color: WaffleTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
                hintStyle: TextStyle(
                  color: WaffleTheme.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee,
                  color: WaffleTheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                  borderSide: BorderSide(color: WaffleTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                  borderSide: BorderSide(color: WaffleTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                  borderSide: BorderSide(color: WaffleTheme.primary, width: 2),
                ),
              ),
            ),
            
            // Error message
            if (_error != null) ...[
              const SizedBox(height: WaffleTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(WaffleTheme.spacingS),
                decoration: BoxDecoration(
                  color: WaffleTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: WaffleTheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: WaffleTheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: WaffleTheme.spacingL),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: WaffleTheme.spacingS),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WaffleTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: WaffleTheme.spacingL,
                      vertical: WaffleTheme.spacingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleAdd,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add Material'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
