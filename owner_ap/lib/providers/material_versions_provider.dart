import 'package:flutter/foundation.dart';
import '../models/material_version.dart';
import '../services/services.dart';

/// Provider for managing material versions state and operations
class MaterialVersionsProvider extends ChangeNotifier {
  final MaterialVersionsService _materialVersionsService;

  List<MaterialVersion> _versions = [];
  MaterialVersion? _currentVersion;
  List<AvailableMaterial> _availableMaterials = [];
  List<MaterialVersionItem> _selectedMaterials = [];
  bool _isLoading = false;
  bool _isEditing = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  MaterialVersionsProvider({MaterialVersionsService? materialVersionsService})
      : _materialVersionsService = materialVersionsService ?? ServiceFactory.createMaterialVersionsService();

  // Getters
  List<MaterialVersion> get versions => List.unmodifiable(_versions);
  MaterialVersion? get currentVersion => _currentVersion;
  List<AvailableMaterial> get availableMaterials => List.unmodifiable(_availableMaterials);
  List<MaterialVersionItem> get selectedMaterials => List.unmodifiable(_selectedMaterials);
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get error => _error;
  bool get hasError => _error != null;
  DateTime get selectedDate => _selectedDate;
  
  // Computed properties
  double get selectedTotalCost {
    return _selectedMaterials.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  String get formattedSelectedTotal => '₹${selectedTotalCost.toStringAsFixed(0)}';
  
  bool get hasSelectedMaterials => _selectedMaterials.isNotEmpty;
  
  bool get canSave => _selectedMaterials.isNotEmpty && !_isLoading;

  /// Load all material versions
  Future<void> loadVersions() async {
    _setLoading(true);
    _clearError();

    try {
      _versions = await _materialVersionsService.getVersions();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Load version for the selected date
  Future<void> loadVersionForDate(DateTime date) async {
    _setLoading(true);
    _clearError();

    try {
      _currentVersion = await _materialVersionsService.getVersionForDate(date);
      
      if (_currentVersion != null && _currentVersion!.materialItems.isNotEmpty) {
        // Found saved materials for this date
        _selectedMaterials = List.from(_currentVersion!.materialItems);
      } else {
        // No materials for this date, load the most recent saved materials
        await _loadMostRecentMaterials();
      }
      
      _isEditing = false;
      _clearError();
      notifyListeners();
    } catch (e) {
      _currentVersion = null;
      // On error, try to load most recent materials
      await _loadMostRecentMaterials();
      _isEditing = false;
      _clearError();
    } finally {
      _setLoading(false);
    }
  }

  /// Load the most recently saved materials as default
  Future<void> _loadMostRecentMaterials() async {
    try {
      final versions = await _materialVersionsService.getVersions();
      if (versions.isNotEmpty) {
        // Sort by effective date descending to get the most recent
        versions.sort((a, b) => b.effectiveFromDate.compareTo(a.effectiveFromDate));
        final mostRecent = versions.first;
        _selectedMaterials = List.from(mostRecent.materialItems);
      } else {
        _selectedMaterials = [];
      }
    } catch (e) {
      _selectedMaterials = [];
    }
  }

  /// Load available materials
  Future<void> loadAvailableMaterials() async {
    _setLoading(true);
    _clearError();

    try {
      _availableMaterials = await _materialVersionsService.getAvailableMaterials();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Set selected date and reload version
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();
    await loadVersionForDate(date);
  }

  /// Start new material configuration
  void startNewConfiguration() {
    _selectedMaterials = [];
    _isEditing = true;
    _clearError();
    notifyListeners();
  }

  /// Start editing current version
  void startEditing() {
    if (_currentVersion != null) {
      _selectedMaterials = List.from(_currentVersion!.materialItems);
      _isEditing = true;
      _clearError();
      notifyListeners();
    }
  }

  /// Add material to selected list
  void addMaterial(AvailableMaterial material) {
    // Check if material already exists
    final existingIndex = _selectedMaterials.indexWhere((item) => item.materialName == material.name);
    
    if (existingIndex != -1) {
      // Material exists, increment quantity
      final existingItem = _selectedMaterials[existingIndex];
      _selectedMaterials[existingIndex] = existingItem.incrementQuantity();
      _clearError();
      notifyListeners();
      return;
    }

    final newItem = MaterialVersionItem(
      id: '', // Will be set by backend
      materialName: material.name,
      price: material.price,
      quantity: 1, // Default quantity
    );

    _selectedMaterials.add(newItem);
    _selectedMaterials.sort((a, b) => a.materialName.compareTo(b.materialName));
    _clearError();
    notifyListeners();
  }

  /// Add custom material with name and price
  void addCustomMaterial(String name, double price) {
    // Check if material already exists in available materials
    final exists = _availableMaterials.any((item) => item.name == name);
    if (exists) {
      _setError('Material "$name" already exists');
      return;
    }

    // Create new available material
    final newAvailableMaterial = AvailableMaterial(
      name: name,
      price: price,
      versionName: 'Custom',
      effectiveFrom: DateTime.now(),
    );

    _availableMaterials.add(newAvailableMaterial);
    _availableMaterials.sort((a, b) => a.name.compareTo(b.name));
    _clearError();
    notifyListeners();
  }

  /// Remove material from selected list
  void removeMaterial(String materialName) {
    _selectedMaterials.removeWhere((item) => item.materialName == materialName);
    _clearError();
    notifyListeners();
  }

  /// Update material price
  void updateMaterialPrice(String materialName, double newPrice) {
    final index = _selectedMaterials.indexWhere((item) => item.materialName == materialName);
    if (index != -1) {
      _selectedMaterials[index] = _selectedMaterials[index].copyWith(price: newPrice);
      notifyListeners();
    }
  }

  /// Increment material quantity
  void incrementMaterialQuantity(String materialName) {
    final index = _selectedMaterials.indexWhere((item) => item.materialName == materialName);
    if (index != -1) {
      _selectedMaterials[index] = _selectedMaterials[index].incrementQuantity();
      _clearError();
      notifyListeners();
    }
  }

  /// Decrement material quantity
  void decrementMaterialQuantity(String materialName) {
    final index = _selectedMaterials.indexWhere((item) => item.materialName == materialName);
    if (index != -1) {
      _selectedMaterials[index] = _selectedMaterials[index].decrementQuantity();
      _clearError();
      notifyListeners();
    }
  }

  /// Save current material configuration
  Future<bool> saveConfiguration() async {
    if (!_canSaveConfiguration()) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final request = MaterialVersionRequest(
        name: _generateVersionName(),
        effectiveFromDate: _selectedDate,
        materialItems: _selectedMaterials.map((item) => MaterialVersionItemRequest(
          materialName: item.materialName,
          price: item.price,
        )).toList(),
      );

      final version = await _materialVersionsService.createVersion(request);
      
      // Update state
      _versions.insert(0, version);
      _currentVersion = version;
      _selectedMaterials = List.from(version.materialItems);
      _isEditing = false;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update current version
  Future<bool> updateConfiguration() async {
    if (!_canSaveConfiguration() || _currentVersion == null) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final request = MaterialVersionRequest(
        name: _currentVersion!.name,
        effectiveFromDate: _currentVersion!.effectiveFromDate,
        materialItems: _selectedMaterials.map((item) => MaterialVersionItemRequest(
          materialName: item.materialName,
          price: item.price,
        )).toList(),
      );

      final version = await _materialVersionsService.updateVersion(_currentVersion!.id, request);
      
      // Update state
      final index = _versions.indexWhere((v) => v.id == version.id);
      if (index != -1) {
        _versions[index] = version;
      }
      _currentVersion = version;
      _selectedMaterials = List.from(version.materialItems);
      _isEditing = false;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete current version
  Future<bool> deleteConfiguration() async {
    if (_currentVersion == null) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _materialVersionsService.deleteVersion(_currentVersion!.id);
      
      // Update state
      _versions.removeWhere((v) => v.id == _currentVersion!.id);
      _currentVersion = null;
      _selectedMaterials = [];
      _isEditing = false;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel editing
  void cancelEditing() {
    if (_currentVersion != null) {
      _selectedMaterials = List.from(_currentVersion!.materialItems);
    } else {
      _selectedMaterials = [];
    }
    _isEditing = false;
    _clearError();
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadVersions(),
      loadVersionForDate(_selectedDate),
      loadAvailableMaterials(),
    ]);
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

  bool _canSaveConfiguration() {
    if (_selectedMaterials.isEmpty) {
      _setError('At least one material must be selected');
      return false;
    }

    // Check for duplicate material names
    final materialNames = _selectedMaterials.map((item) => item.materialName).toSet();
    if (materialNames.length != _selectedMaterials.length) {
      _setError('Duplicate material names found');
      return false;
    }

    // Check for negative prices
    final hasNegativePrice = _selectedMaterials.any((item) => item.price < 0);
    if (hasNegativePrice) {
      _setError('Material prices cannot be negative');
      return false;
    }

    return true;
  }

  String _generateVersionName() {
    if (_isEditing && _currentVersion != null) {
      return _currentVersion!.name;
    }
    
    final versionNumber = _versions.length + 1;
    return 'Version $versionNumber.0';
  }
}
