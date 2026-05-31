import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A dedicated widget for managing bill save location settings.
///
/// This widget provides:
/// - Native directory picker integration using file_picker
/// - Storage permission handling for Android/iOS
/// - Scoped Storage compliance for modern Android versions
/// - Path state management with SharedPreferences persistence
/// - Reset functionality to revert to default app directories
class BillPathSettingsWidget extends StatefulWidget {
  const BillPathSettingsWidget({super.key});

  @override
  State<BillPathSettingsWidget> createState() => _BillPathSettingsWidgetState();
}

class _BillPathSettingsWidgetState extends State<BillPathSettingsWidget> {
  /// The currently selected save path (custom or default)
  String _currentPath = '';
  
  /// Whether a custom path has been set by the user
  bool _hasCustomPath = false;
  
  /// Loading state for async operations
  bool _isLoading = true;
  
  /// Controller for the path text field
  late TextEditingController _pathController;

  /// SharedPreferences key for storing the custom path
  static const String _prefsKey = 'bill_save_path';

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController();
    _initializePath();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  /// Initializes the path by loading from SharedPreferences or computing default
  Future<void> _initializePath() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString(_prefsKey) ?? '';
      
      if (customPath.isNotEmpty) {
        _currentPath = customPath;
        _hasCustomPath = true;
      } else {
        _currentPath = await _getDefaultPath();
        _hasCustomPath = false;
      }
      
      _pathController.text = _currentPath;
    } catch (e) {
      // Fallback to app documents if initialization fails
      _currentPath = await _getAppDocumentsPath();
      _hasCustomPath = false;
      _pathController.text = _currentPath;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Gets the default save path based on platform
  /// 
  /// Returns:
  /// - Android: External Downloads/Bills directory
  /// - iOS: Application Documents/Bills directory
  Future<String> _getDefaultPath() async {
    if (Platform.isAndroid) {
      // For Android, try to get the public Downloads directory
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate to the external storage root, then to Download
          final root = externalDir.parent.parent.parent.parent;
          final downloadPath = '${root.path}/Download/Bills';
          
          // Ensure directory exists
          final dir = Directory(downloadPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return downloadPath;
        }
      } catch (_) {
        // Fall through to app documents if external storage fails
      }
    }
    
    // Default: Use app documents directory
    return await _getAppDocumentsPath();
  }

  /// Gets the app's documents directory with Bills subdirectory
  Future<String> _getAppDocumentsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final b2cPath = '${appDir.path}/Bills';
    
    // Ensure directory exists
    final dir = Directory(b2cPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return b2cPath;
  }

  /// Requests necessary storage permissions based on platform
  /// 
  /// For Android:
  /// - Android 10 (API 29) and below: Requests storage permission
  /// - Android 11+ (API 30+): Uses Scoped Storage, directory picker grants access
  /// 
  /// For iOS: Uses app's sandbox, no special permissions needed for documents
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check Android version
      final androidVersion = int.tryParse(
        Platform.version.split(' ').first.split('.').first,
      ) ?? 0;
      
      if (androidVersion >= 30) {
        // Android 11+ (API 30+): Scoped Storage is enforced
        // Directory picker will handle permissions via SAF (Storage Access Framework)
        // No need for explicit MANAGE_EXTERNAL_STORAGE permission
        return true;
      } else {
        // Android 10 and below: Request traditional storage permission
        final status = await Permission.storage.request();
        return status.isGranted || status.isLimited;
      }
    } else if (Platform.isIOS) {
      // iOS: App has access to its own documents directory by default
      // File picker uses UIDocumentPickerViewController which handles permissions
      return true;
    }
    
    return true;
  }

  /// Opens the native directory picker dialog
  /// 
  /// Uses FilePicker.platform.getDirectoryPath() to open the system folder
  /// selection dialog. The selected path is persisted to SharedPreferences.
  Future<void> _pickDirectory() async {
    // Request permissions before opening picker
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        _showPermissionDeniedDialog();
      }
      return;
    }

    try {
      // Open native directory picker
      final String? selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Choose Bill Save Folder',
      );

      if (selectedPath != null && selectedPath.isNotEmpty) {
        // Validate that the path is writable
        final isWritable = await _validatePathWritable(selectedPath);
        if (!isWritable) {
          if (mounted) {
            _showSnackBar(
              'Selected folder is not writable. Please choose another location.',
              isError: true,
            );
          }
          return;
        }

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, selectedPath);

        // Update state
        setState(() {
          _currentPath = selectedPath;
          _hasCustomPath = true;
          _pathController.text = selectedPath;
        });

        if (mounted) {
          _showSnackBar('Bill save location updated');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to pick directory: $e', isError: true);
      }
    }
  }

  /// Validates that a directory path is writable
  Future<bool> _validatePathWritable(String path) async {
    try {
      final dir = Directory(path);
      
      // Check if directory exists, create if not
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Try to create a test file
      final testFile = File('$path/.test_write');
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resets the save location to the default app directory
  /// 
  /// Clears the custom path from SharedPreferences and reverts to the
  /// standard Downloads/Bills or app documents directory.
  Future<void> _resetToDefault() async {
    setState(() => _isLoading = true);
    
    try {
      // Remove custom path from preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);

      // Get default path
      final defaultPath = await _getDefaultPath();

      // Update state
      setState(() {
        _currentPath = defaultPath;
        _hasCustomPath = false;
        _pathController.text = defaultPath;
      });

      if (mounted) {
        _showSnackBar('Reset to default location', color: Colors.orange);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to reset: $e', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Shows a permission denied dialog with guidance
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'To save bills to a custom location, the app needs storage permission. '
          'Please grant permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Shows a snackbar with the given message
  void _showSnackBar(
    String message, {
    bool isError = false,
    Color? color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? (isError ? Colors.red : Colors.green),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main card with path settings
          _buildPathCard(),
          const SizedBox(height: 16),
          // Info box with instructions
          _buildInfoBox(),
        ],
      ),
    );
  }

  /// Builds the main settings card containing path display and action buttons
  Widget _buildPathCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          _buildHeader(),
          const SizedBox(height: 8),
          // Description text
          _buildDescription(),
          const SizedBox(height: 20),
          // Path text field
          _buildPathTextField(),
          const SizedBox(height: 16),
          // Action buttons row
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Builds the header row with icon and title
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.receipt_long,
            color: Color(0xFFF57F17),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Bill Save Location',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Builds the description text
  Widget _buildDescription() {
    return Text(
      'Choose where bills are saved on this device.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.grey[600],
      ),
    );
  }

  /// Builds the read-only path display text field
  Widget _buildPathTextField() {
    return TextField(
      controller: _pathController,
      readOnly: true,
      enabled: !_isLoading,
      maxLines: 2,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Save Path',
        hintText: _isLoading ? 'Loading...' : 'Default — Downloads/Bills',
        prefixIcon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.folder_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  /// Builds the row containing Browse and Reset buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Browse button - expanded to take available space
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickDirectory,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.folder_open),
            label: Text(_isLoading ? 'Loading...' : 'Browse'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Reset button - disabled when using default path
        OutlinedButton.icon(
          onPressed: (_isLoading || !_hasCustomPath) ? null : _resetToDefault,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the info box with instructions
  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap Browse to choose a custom folder for saving bills.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave as default to save in Downloads/Bills or app documents.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade700.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Service class for managing bill save paths
/// 
/// This class provides static methods for getting and setting the save path,
/// making it accessible from other parts of the application.
class BillPathService {
  static const String _prefsKey = 'bill_save_path';

  /// Gets the current bill save directory path
  /// 
  /// Returns the custom path if set, otherwise returns the default path.
  /// Creates the directory if it doesn't exist.
  static Future<String> getBillSaveDir() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(_prefsKey) ?? '';

    if (customPath.isNotEmpty) {
      // Validate and create custom directory
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return customPath;
    }

    // Return default path
    return _getDefaultPath();
  }

  /// Gets the default save path based on platform
  static Future<String> _getDefaultPath() async {
    if (Platform.isAndroid) {
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final root = externalDir.parent.parent.parent.parent;
          final downloadPath = '${root.path}/Download/Bills';
          
          final dir = Directory(downloadPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return downloadPath;
        }
      } catch (_) {
        // Fall through to app documents
      }
    }

    final appDir = await getApplicationDocumentsDirectory();
    final b2cPath = '${appDir.path}/Bills';
    
    final dir = Directory(b2cPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return b2cPath;
  }

  /// Sets a custom save path
  static Future<void> setCustomPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, path);
  }

  /// Clears the custom path and reverts to default
  static Future<void> clearCustomPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Checks if a custom path is currently set
  static Future<bool> hasCustomPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefsKey) ?? '';
    return path.isNotEmpty;
  }
}
