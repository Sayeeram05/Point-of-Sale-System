import 'package:flutter/material.dart';
import '../theme/waffle_theme.dart';
import '../widgets/widgets.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final List<SelectedMaterial> _selectedMaterials = [
    SelectedMaterial(name: 'Flour', quantity: 10, price: 20.00),
    SelectedMaterial(name: 'Sugar', quantity: 5, price: 30.00),
    SelectedMaterial(name: 'Milk', quantity: 2, price: 25.00),
  ];

  final List<AvailableMaterial> _availableMaterials = [
    AvailableMaterial(name: 'Rice', price: 40.00, icon: '🌾', color: const Color(0xFFFEF3C7)),
    AvailableMaterial(name: 'Wheat', price: 28.00, icon: '🌾', color: const Color(0xFFDCFCE7)),
    AvailableMaterial(name: 'Dal', price: 60.00, icon: '🫘', color: const Color(0xFFE0E7FF)),
    AvailableMaterial(name: 'Oil', price: 120.00, icon: '🫒', color: const Color(0xFFFEE2E2)),
    AvailableMaterial(name: 'Salt', price: 10.00, icon: '🧂', color: const Color(0xFFF3E8FF)),
    AvailableMaterial(name: 'Yeast', price: 15.00, icon: '🍞', color: const Color(0xFFECFDF5)),
    AvailableMaterial(name: 'Butter', price: 50.00, icon: '🧈', color: const Color(0xFFFEF3C7)),
    AvailableMaterial(name: 'Cocoa Powder', price: 80.00, icon: '🍫', color: const Color(0xFFE0F2FE)),
  ];

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQuantity = _selectedMaterials[index].quantity + delta;
      if (newQuantity > 0) {
        _selectedMaterials[index] = _selectedMaterials[index].copyWith(quantity: newQuantity);
      }
    });
  }

  void _removeMaterial(int index) {
    setState(() {
      _selectedMaterials.removeAt(index);
    });
  }

  void _addMaterial(AvailableMaterial material) {
    setState(() {
      final existingIndex = _selectedMaterials.indexWhere((m) => m.name == material.name);
      if (existingIndex >= 0) {
        _selectedMaterials[existingIndex] = _selectedMaterials[existingIndex].copyWith(
          quantity: _selectedMaterials[existingIndex].quantity + 1,
        );
      } else {
        _selectedMaterials.add(SelectedMaterial(
          name: material.name,
          quantity: 1,
          price: material.price,
        ));
      }
    });
  }

  double get _totalCost {
    return _selectedMaterials.fold(0.0, (sum, material) => sum + (material.quantity * material.price));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Section - Selected Materials
            Expanded(
              flex: 1,
              child: _buildSelectedMaterials(),
            ),
            const SizedBox(width: 24),
            // Right Section - Available Materials
            Expanded(
              flex: 1,
              child: _buildAvailableMaterials(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSelectedMaterials() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Raw Materials',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Materials added to your configuration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedMaterials.length} Items',
                    style: const TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 40, child: Text('S.No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                Expanded(child: Text('Material Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                SizedBox(width: 80, child: Text('Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                SizedBox(width: 80, child: Text('Price (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                SizedBox(width: 80, child: Text('Total (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              ],
            ),
          ),

          // Material Rows
          ..._selectedMaterials.asMap().entries.map((entry) => _buildSelectedMaterialRow(entry.key + 1, entry.value, entry.key)),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.calculate, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Material Cost',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                    Text(
                      '(${_selectedMaterials.length} items)',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF10B981).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '₹${_totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSelectedMaterialRow(int sNo, SelectedMaterial material, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$sNo',
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            child: Text(
              material.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _updateQuantity(index, -1),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.remove, size: 16, color: Color(0xFF6B7280)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${material.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _updateQuantity(index, 1),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '₹${material.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '₹${(material.quantity * material.price).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
              onPressed: () => _removeMaterial(index),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAvailableMaterials() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Raw Materials',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Click "Add" to include materials',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, color: Color(0xFF6B7280), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Search materials...',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('Material Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                SizedBox(width: 120, child: Text('Price (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                SizedBox(width: 80, child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              ],
            ),
          ),

          // Material Rows
          ..._availableMaterials.map((material) => _buildAvailableMaterialRow(material)),

          // Pagination Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Showing 1 to 8 of ${_availableMaterials.length} items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _paginationButton('<', false),
                    const SizedBox(width: 4),
                    _paginationButton('1', true),
                    const SizedBox(width: 4),
                    _paginationButton('2', false),
                    const SizedBox(width: 4),
                    _paginationButton('3', false),
                    const SizedBox(width: 4),
                    _paginationButton('>', false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAvailableMaterialRow(AvailableMaterial material) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: material.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                material.icon,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              material.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              '₹${material.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextButton.icon(
              onPressed: () => _addMaterial(material),
              icon: const Icon(Icons.add, color: Color(0xFF10B981), size: 16),
              label: const Text(
                'Add',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paginationButton(String text, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF10B981) : Colors.white,
        border: Border.all(
          color: active ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
// Data Models
class SelectedMaterial {
  final String name;
  final int quantity;
  final double price;

  SelectedMaterial({
    required this.name,
    required this.quantity,
    required this.price,
  });

  SelectedMaterial copyWith({
    String? name,
    int? quantity,
    double? price,
  }) {
    return SelectedMaterial(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}

class AvailableMaterial {
  final String name;
  final double price;
  final String icon;
  final Color color;

  AvailableMaterial({
    required this.name,
    required this.price,
    required this.icon,
    required this.color,
  });
}