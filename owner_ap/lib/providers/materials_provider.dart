import 'package:flutter/foundation.dart';
import '../models/materials_models.dart';
import '../services/materials_service.dart';

/// Provider managing all state for the Materials Tracking & Procurement screen.
/// Drives both the purchase grid (left panel) and the material catalog (right panel).
class MaterialsProvider extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Catalog state
  // ---------------------------------------------------------------------------
  List<RawMaterial> _catalog = [];
  bool _catalogLoading = false;

  // ---------------------------------------------------------------------------
  // Active purchase grid state
  // ---------------------------------------------------------------------------
  List<PurchaseLineItem> _purchaseItems = [];
  bool _isLocked = false;
  DateTime _selectedDate = DateTime.now();
  int? _savedRecordId;
  double _totalCost = 0.0;

  // ---------------------------------------------------------------------------
  // Last 7 days presence tracking
  // ---------------------------------------------------------------------------
  List<String> _recentDates = [];

  // ---------------------------------------------------------------------------
  // Operation state
  // ---------------------------------------------------------------------------
  bool _isSaving = false;
  String? _error;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------
  List<RawMaterial> get catalog => List.unmodifiable(_catalog);
  List<PurchaseLineItem> get purchaseItems => List.unmodifiable(_purchaseItems);
  bool get isLocked => _isLocked;
  DateTime get selectedDate => _selectedDate;
  bool get catalogLoading => _catalogLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  double get totalCost => _totalCost;
  List<String> get recentDates => List.unmodifiable(_recentDates);
  bool get hasSavedRecord => _savedRecordId != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Called once when the screen mounts. Loads catalog + recent dates + today's record.
  Future<void> initialize() async {
    await Future.wait([loadCatalog(), loadRecentDates()]);
    await loadRecordForDate(_selectedDate);
  }

  Future<void> loadCatalog() async {
    _catalogLoading = true;
    notifyListeners();
    try {
      _catalog = await MaterialsService.getRawMaterials();
    } catch (e) {
      _error = e.toString();
    } finally {
      _catalogLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentDates() async {
    try {
      _recentDates = await MaterialsService.getLast7DaysDates();
      notifyListeners();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Date selection
  // ---------------------------------------------------------------------------

  /// Switches the active date and loads (or resets) the corresponding record.
  Future<void> loadRecordForDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();

    try {
      final record = await MaterialsService.getPurchaseRecord(_fmtDate(date));
      if (record != null) {
        _savedRecordId = record.id;
        _isLocked = record.isLocked;
        _purchaseItems = record.items
            .map((item) => PurchaseLineItem(
                  rawMaterialId: item.rawMaterialId,
                  materialName: item.materialName,
                  basePrice: item.basePriceSnapshot,
                  quantity: item.quantity,
                  isLumpSum: item.rawMaterialId == null,
                ))
            .toList();
        _totalCost = record.totalCost;
      } else {
        // No record yet for this date — start in edit mode with empty grid
        _savedRecordId = null;
        _isLocked = false;
        _purchaseItems = [];
        _totalCost = 0.0;
      }
    } catch (_) {
      _savedRecordId = null;
      _isLocked = false;
      _purchaseItems = [];
      _totalCost = 0.0;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Edit-mode controls
  // ---------------------------------------------------------------------------

  void enterEditMode() {
    _isLocked = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Grid mutation helpers
  // ---------------------------------------------------------------------------

  /// Adds a material to the grid, or increments its quantity if already present.
  void addOrIncrementItem(RawMaterial material) {
    if (_isLocked) return;

    final idx = _purchaseItems.indexWhere((i) => i.rawMaterialId == material.id);
    if (idx != -1) {
      _purchaseItems[idx].quantity += 1;
    } else {
      _purchaseItems.add(PurchaseLineItem(
        rawMaterialId: material.id,
        materialName: material.name,
        basePrice: material.basePrice,
      ));
    }
    _recalcTotal();
    notifyListeners();
  }

  void updateItemQuantity(int index, double quantity) {
    if (index < 0 || index >= _purchaseItems.length) return;
    if (quantity <= 0) {
      _purchaseItems.removeAt(index);
    } else {
      _purchaseItems[index].quantity = quantity;
    }
    _recalcTotal();
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _purchaseItems.length) {
      _purchaseItems.removeAt(index);
      _recalcTotal();
      notifyListeners();
    }
  }

  void addLumpSumItem() {
    if (_isLocked) return;
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    _purchaseItems.add(PurchaseLineItem(
      rawMaterialId: null,
      materialName: 'Vendor Bill — $h12:$m $period',
      basePrice: 0.0,
      quantity: 1.0,
      isLumpSum: true,
    ));
    _recalcTotal();
    notifyListeners();
  }

  void updateLumpSumPrice(int index, double price) {
    if (index < 0 || index >= _purchaseItems.length) return;
    final old = _purchaseItems[index];
    if (!old.isLumpSum) return;
    _purchaseItems[index] = PurchaseLineItem(
      rawMaterialId: null,
      materialName: old.materialName,
      basePrice: price,
      quantity: 1.0,
      isLumpSum: true,
    );
    _recalcTotal();
    notifyListeners();
  }

  void updateLumpSumName(int index, String name) {
    if (index < 0 || index >= _purchaseItems.length) return;
    final old = _purchaseItems[index];
    if (!old.isLumpSum) return;
    _purchaseItems[index] = PurchaseLineItem(
      rawMaterialId: null,
      materialName: name,
      basePrice: old.basePrice,
      quantity: 1.0,
      isLumpSum: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Saves (or replaces) the purchase record via the API.
  /// On success locks the record and returns true.
  Future<bool> saveRecord(String notes) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    // Pre-flight sanitization for lump-sum items
    int billCount = 0;
    for (int i = 0; i < _purchaseItems.length; i++) {
      final item = _purchaseItems[i];
      if (!item.isLumpSum) continue;
      billCount++;
      if (item.basePrice <= 0) {
        final label =
            item.materialName.trim().isEmpty ? 'Bill #$billCount' : item.materialName;
        _error = 'Bill amount for "$label" must be greater than ₹0.';
        _isSaving = false;
        notifyListeners();
        return false;
      }
      if (item.materialName.trim().isEmpty) {
        _purchaseItems[i] = PurchaseLineItem(
          rawMaterialId: null,
          materialName: 'Bill #$billCount',
          basePrice: item.basePrice,
          quantity: 1.0,
          isLumpSum: true,
        );
      }
    }

    try {
      final record = await MaterialsService.savePurchaseRecord(
        targetDate: _fmtDate(_selectedDate),
        notes: notes,
        items: _purchaseItems,
      );
      _savedRecordId = record.id;
      _isLocked = record.isLocked;
      _totalCost = record.totalCost;
      await loadRecentDates();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Discards unsaved changes and reverts to the last saved snapshot.
  void cancelEdits() {
    if (_savedRecordId != null) {
      loadRecordForDate(_selectedDate);
    } else {
      _purchaseItems = [];
      _totalCost = 0.0;
      _isLocked = true;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Catalog CRUD
  // ---------------------------------------------------------------------------

  Future<bool> createRawMaterial({
    required String name,
    required String unit,
    required double basePrice,
  }) async {
    try {
      final m = await MaterialsService.createRawMaterial(
          name: name, unit: unit, basePrice: basePrice);
      _catalog.add(m);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRawMaterial({
    required int id,
    required String name,
    required String unit,
    required double basePrice,
  }) async {
    try {
      final updated = await MaterialsService.updateRawMaterial(
          id: id, name: name, unit: unit, basePrice: basePrice);
      final idx = _catalog.indexWhere((m) => m.id == id);
      if (idx != -1) _catalog[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRawMaterial(int id) async {
    try {
      await MaterialsService.deleteRawMaterial(id);
      _catalog.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _recalcTotal() {
    _totalCost = _purchaseItems.fold(0.0, (sum, i) => sum + i.subtotal);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
