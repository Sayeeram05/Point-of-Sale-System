import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider for managing materials state and operations
class MaterialsProvider extends ChangeNotifier {
  final MaterialsService _materialsService;

  List<MaterialEntry> _entries = [];
  double _total = 0.0;
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  MaterialsProvider({MaterialsService? materialsService})
      : _materialsService = materialsService ?? ServiceFactory.createMaterialsService();

  // Getters
  List<MaterialEntry> get entries => List.unmodifiable(_entries);
  double get total => _total;
  String get formattedTotal => '₹${_total.toStringAsFixed(0)}';
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _entries.isEmpty && !_isLoading;
  DateTime get selectedDate => _selectedDate;

  /// Load materials for the selected date
  Future<void> loadMaterials() async {
    _setLoading(true);
    _clearError();

    try {
      final dateStr = _formatDate(_selectedDate);
      final entries = await _materialsService.getMaterials(date: dateStr);
      final total = await _materialsService.getTotal(date: dateStr);
      
      _entries = entries;
      _total = total;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Set selected date and reload materials
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();
    await loadMaterials();
  }

  /// Create a new material entry
  Future<bool> createMaterial(MaterialEntryRequest request) async {
    _clearError();

    try {
      final entry = await _materialsService.createMaterial(request);
      _entries.add(entry);
      _recalculateTotal();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Update an existing material entry
  Future<bool> updateMaterial(String id, MaterialEntryRequest request) async {
    _clearError();

    try {
      final updatedEntry = await _materialsService.updateMaterial(id, request);
      final index = _entries.indexWhere((e) => e.id == id);
      if (index != -1) {
        _entries[index] = updatedEntry;
        _recalculateTotal();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Delete a material entry
  Future<bool> deleteMaterial(String id) async {
    _clearError();

    try {
      await _materialsService.deleteMaterial(id);
      _entries.removeWhere((e) => e.id == id);
      _recalculateTotal();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Refresh materials (reload from service)
  Future<void> refresh() async {
    await loadMaterials();
  }

  /// Clear any existing error
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _recalculateTotal() {
    _total = _entries.fold<double>(0.0, (sum, e) => sum + e.price);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
