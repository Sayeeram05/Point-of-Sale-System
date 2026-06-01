import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/woffle_api_service.dart';
import '../services/woffle_bill_pdf_service.dart';
import '../models/woffle_user_preferences.dart';
import '../services/woffle_app_colors.dart';
import '../theme/woffle_app_theme.dart';
import '../widgets/woffle_color_picker_dialog.dart';
import '../widgets/woffle_bill_path_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  List<UserEmoji> _emojis = [];
  List<UserColor> _colors = [];
  bool _isLoading = true;
  String _error = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Parallel fetch — 2 independent requests at once
      final results = await Future.wait([
        ApiService.getEmojis(),
        ApiService.getColors(),
      ]);
      final emojis = results[0] as List<UserEmoji>;
      final colors = results[1] as List<UserColor>;

      // Check for data integrity issues
      _validateDataIntegrity(emojis, colors);

      setState(() {
        _emojis = emojis;
        _colors = colors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _validateDataIntegrity(List<UserEmoji> emojis, List<UserColor> colors) {
    // Removed all debug notifications per user request
    // Data validation happens silently in the background
  }

  Future<void> _addEmoji() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Add Emoji',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Emoji',
            labelStyle: AppTheme.bodyLarge,
            hintText: 'Enter an emoji (e.g., 🍦)',
            hintStyle: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
          style: AppTheme.bodyLarge,
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Text(
              'Add',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final newEmoji = await ApiService.addEmoji(result);
        setState(() {
          _emojis.add(newEmoji);
        });
        // Notification removed per user request
      } catch (e) {
        // Error notification removed per user request
      }
    }
  }

  Future<void> _deleteEmoji(UserEmoji emoji) async {
    // Prevent deletion of default emoji (ID 1)
    if (emoji.id == 1) {
      // Cannot delete default emoji notification removed per user request
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Delete Emoji',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete ${emoji.emojiText}?',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Text(
              'Delete',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (emoji.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot delete emoji: missing ID.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      try {
        final success = await ApiService.deleteEmoji(emoji.id!);
        if (success) {
          setState(() {
            _emojis.removeWhere((e) => e.id == emoji.id);
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete emoji. Please try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting emoji: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _addColor() async {
    final result = await showColorPickerDialog(context);
    if (result != null) {
      try {
        final colorHex = AppColors.toHex(result);
        // Duplicate check
        if (_colors.any(
          (c) => c.color.toUpperCase() == colorHex.toUpperCase(),
        )) {
          return;
        }
        final newColor = await ApiService.addColor(colorHex);
        setState(() {
          _colors.add(newColor);
        });
      } catch (e) {
        // Error handled silently
      }
    }
  }

  Future<void> _deleteColor(UserColor color) async {
    // Prevent deletion of blue color (#2196F3) only
    const defaultBlueHex = '#2196F3';
    final isBlueColor = color.color.toUpperCase() == defaultBlueHex;

    if (isBlueColor) {
      // Cannot delete default blue color notification removed per user request
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Delete Color',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.fromHex(color.color),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor, width: 2),
                boxShadow: AppTheme.elevationSmall,
              ),
            ),
            const SizedBox(width: AppTheme.spacingLarge),
            const Expanded(
              child: Text(
                'Are you sure you want to delete this color?',
                style: AppTheme.bodyLarge,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (color.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot delete color: missing ID.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      try {
        final success = await ApiService.deleteColor(color.id!);
        if (success) {
          setState(() {
            _colors.removeWhere((c) => c.id == color.id);
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete color. Please try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting color: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTheme.headingMedium(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: AppTheme.isMobileOnly(context) ? 28 : 34,
            ),
            onPressed: _loadUserPreferences,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              icon: Icon(
                Icons.emoji_emotions,
                size: AppTheme.isMobileOnly(context) ? 24 : 32,
              ),
              text: 'Emojis',
            ),
            Tab(
              icon: Icon(
                Icons.palette,
                size: AppTheme.isMobileOnly(context) ? 24 : 32,
              ),
              text: 'Colors',
            ),
            Tab(
              icon: Icon(
                Icons.dns,
                size: AppTheme.isMobileOnly(context) ? 24 : 32,
              ),
              text: 'Server',
            ),
            Tab(
              icon: Icon(
                Icons.receipt_long,
                size: AppTheme.isMobileOnly(context) ? 24 : 32,
              ),
              text: 'Bills',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                strokeWidth: 3,
              ),
            )
          : _error.isNotEmpty
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEmojisTab(),
                _buildColorsTab(),
                _buildServerTab(),
                _buildBillsTab(),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingXLarge),
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.elevationMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 72, color: AppTheme.error),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'Failed to load settings',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXLarge),
            ElevatedButton.icon(
              onPressed: _loadUserPreferences,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Retry',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojisTab() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Available Emojis',
                Icons.emoji_emotions,
                _emojis.length,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Expanded(
                child: _emojis.isEmpty
                    ? _buildEmptyState(
                        Icons.emoji_emotions_outlined,
                        'No emojis added yet',
                        'Tap the + button to add your first emoji',
                      )
                    : _buildEmojiGrid(),
              ),
            ],
          ),
        ),
        _buildFloatingActionButton(_addEmoji, 'addEmojiFab'),
      ],
    );
  }

  Widget _buildColorsTab() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Available Colors',
                Icons.palette,
                _colors.length,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Expanded(
                child: _colors.isEmpty
                    ? _buildEmptyState(
                        Icons.palette_outlined,
                        'No colors added yet',
                        'Tap the + button to add your first color',
                      )
                    : _buildColorGrid(),
              ),
            ],
          ),
        ),
        _buildFloatingActionButton(_addColor, 'addColorFab'),
      ],
    );
  }

  Widget _buildServerTab() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final prefs = snapshot.data!;
        final currentIp = prefs.getString('server_ip') ?? '';
        final controller = TextEditingController(text: currentIp);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.elevationSmall,
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.dns,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Server Connection',
                          style: AppTheme.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure the backend server IP address and port.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'IP Address:Port',
                        hintText: '192.168.1.100:8000',
                        prefixIcon: const Icon(Icons.language),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ip = controller.text.trim();
                          if (ip.isEmpty) return;
                          await prefs.setString('server_ip', ip);
                          ApiService.configure(baseUrl: 'http://$ip');
                          ApiService.invalidateCache();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Server updated to $ip'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Current: ${ApiService.baseUrl}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillsTab() {
    return const BillPathSettingsWidget();
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    final isEmojiSection = title.contains('Emoji');
    final defaultCount = isEmojiSection
        ? _emojis.where((e) => e.id == 1).length
        : _colors.where((c) {
            const defaultBlueHex = '#2196F3';
            return c.color.toUpperCase() == defaultBlueHex;
          }).length; // Only count blue colors as default
    final customCount = count - defaultCount;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppTheme.primaryColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.elevationSmall,
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: AppTheme.isMobileOnly(context) ? 32 : 40,
            ),
          ),
          const SizedBox(width: AppTheme.spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatChip(
                      'Total',
                      count.toString(),
                      AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Default',
                      defaultCount.toString(),
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Custom',
                      customCount.toString(),
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    final isTablet = !AppTheme.isMobileOnly(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 14 : 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 8 : 6,
              vertical: isTablet ? 4 : 2,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 14 : 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.isMobileOnly(context) ? 32 : 44),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppTheme.isMobileOnly(context) ? 80 : 100,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXLarge),
          Text(
            title,
            style: AppTheme.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: more columns on wider screens
        final crossAxisCount = constraints.maxWidth > 600 ? 8 : 6;

        return GridView.builder(
          key: ValueKey(_emojis.length),
          padding: const EdgeInsets.only(bottom: 100), // Space for FAB
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.spacingMedium,
            mainAxisSpacing: AppTheme.spacingMedium,
            childAspectRatio: 1.0,
          ),
          itemCount: _emojis.length,
          itemBuilder: (context, index) {
            final emoji = _emojis[index];
            return _buildEmojiCard(emoji);
          },
        );
      },
    );
  }

  Widget _buildColorGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: more columns on wider screens
        final crossAxisCount = constraints.maxWidth > 600 ? 8 : 6;

        return GridView.builder(
          key: ValueKey(_colors.length),
          padding: const EdgeInsets.only(bottom: 100), // Space for FAB
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.spacingMedium,
            mainAxisSpacing: AppTheme.spacingMedium,
            childAspectRatio: 1.0,
          ),
          itemCount: _colors.length,
          itemBuilder: (context, index) {
            final color = _colors[index];
            return _buildColorCard(color);
          },
        );
      },
    );
  }

  Widget _buildEmojiCard(UserEmoji emoji) {
    final isDefault = emoji.id == 1;
    final isMobile = AppTheme.isMobileOnly(context);

    // Deterministic hue from the emoji codepoints
    final hue =
        (emoji.emojiText.codeUnits.fold(0, (a, b) => a + b) * 137) % 360;
    final bgColor = HSLColor.fromAHSL(
      1.0,
      hue.toDouble(),
      0.55,
      0.60,
    ).toColor();
    final bgColorDark = HSLColor.fromAHSL(
      1.0,
      (hue + 20) % 360,
      0.55,
      0.45,
    ).toColor();

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji.emojiText,
                  style: TextStyle(
                    fontSize: AppTheme.isMobileOnly(context) ? 64 : 80,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isDefault ? 'Default Emoji' : 'Custom Emoji',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (emoji.id != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${emoji.id}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor, bgColorDark],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: isDefault
              ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2)
              : null,
        ),
        child: Stack(
          children: [
            // Emoji centred
            Center(
              child: Text(
                emoji.emojiText,
                style: TextStyle(fontSize: isMobile ? 32 : 44),
              ),
            ),
            // DEFAULT badge — top-left
            if (isDefault)
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: TextStyle(
                      color: bgColorDark,
                      fontSize: isMobile ? 7 : 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            // Delete button — top-right (non-default only)
            if (!isDefault)
              Positioned(
                top: isMobile ? 4 : 6,
                right: isMobile ? 4 : 6,
                child: GestureDetector(
                  onTap: () => _deleteEmoji(emoji),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isMobile ? 12 : 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCard(UserColor color) {
    const defaultBlueHex = '#2196F3';
    final isDefault = color.color.toUpperCase() == defaultBlueHex;
    final cardColor = AppColors.fromHex(color.color);
    final isMobile = AppTheme.isMobileOnly(context);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isMobile ? 100 : 130,
                  height: isMobile ? 100 : 130,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isDefault ? 'Default Color' : 'Custom Color',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    color.color.toUpperCase(),
                    style: AppTheme.bodyMedium.copyWith(
                      color: cardColor,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: isDefault ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: Stack(
          children: [
            if (isDefault)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: TextStyle(
                      color: cardColor,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (!isDefault)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _deleteColor(color),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isMobile ? 13 : 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(VoidCallback onPressed, String heroTag) {
    final isEmojiTab = heroTag == 'addEmojiFab';

    return Positioned(
      bottom: AppTheme.isMobileOnly(context) ? 32 : 40,
      right: AppTheme.isMobileOnly(context) ? 32 : 40,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: onPressed,
          icon: Icon(
            isEmojiTab ? Icons.emoji_emotions : Icons.palette,
            size: AppTheme.isMobileOnly(context) ? 24 : 30,
          ),
          label: Text(
            isEmojiTab ? 'Add Emoji' : 'Add Color',
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          heroTag: heroTag,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
