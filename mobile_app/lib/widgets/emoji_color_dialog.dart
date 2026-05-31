import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_preferences.dart';
import '../models/order.dart';
import '../services/app_colors.dart';
import 'color_picker_dialog.dart';

class EmojiColorDialog extends StatefulWidget {
  final Order order;
  final VoidCallback onChanged;

  const EmojiColorDialog({
    super.key,
    required this.order,
    required this.onChanged,
  });

  @override
  State<EmojiColorDialog> createState() => _EmojiColorDialogState();
}

class _EmojiColorDialogState extends State<EmojiColorDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<UserEmoji> _emojis = [];
  List<UserColor> _colors = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedEmoji = '';
  String _selectedColor = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedEmoji = widget.order.emoji;
    _selectedColor = widget.order.color;
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

      setState(() {
        _emojis = results[0] as List<UserEmoji>;
        _colors = results[1] as List<UserColor>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addEmoji() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Emoji'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Emoji',
            hintText: 'Enter an emoji (e.g., 🍦)',
            border: OutlineInputBorder(),
          ),
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
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

        // Emoji added notification removed per user request
      } catch (e) {
        // Error notification removed per user request
      }
    }
  }

  Future<void> _addColor() async {
    // Use color picker dialog for RGB color selection
    final result = await showColorPickerDialog(context);

    if (result != null) {
      try {
        final colorHex = AppColors.toHex(result);
        final newColor = await ApiService.addColor(colorHex);
        setState(() {
          _colors.add(newColor);
        });

        // Color added notification removed per user request
      } catch (e) {
        // Error notification removed per user request
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      child: Container(
        width: isTablet ? 750 : double.infinity,
        height: isTablet ? 750 : 580, // Increased height significantly
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          children: [
            // Modern Header with preview
            Container(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 20,
                isTablet ? 24 : 20,
                isTablet ? 24 : 20,
                isTablet ? 16 : 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[600]!, Colors.blue[700]!],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue[600]!.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Live Preview Circle
                      Container(
                        width: isTablet ? 90 : 70, // Increased size
                        height: isTablet ? 90 : 70, // Increased size
                        decoration: BoxDecoration(
                          color: _selectedColor.isNotEmpty
                              ? AppColors.fromHex(_selectedColor)
                              : AppColors.fromHex(widget.order.color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _selectedEmoji.isNotEmpty
                                ? _selectedEmoji
                                : widget.order.emoji,
                            style: TextStyle(
                              fontSize: isTablet
                                  ? 38
                                  : 28, // Increased emoji size significantly
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customize Order',
                              style: TextStyle(
                                fontSize: isTablet ? 24 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: isTablet ? 6 : 4),
                            Text(
                              'Choose your style',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced Modern Tab Bar
            Container(
              margin: EdgeInsets.fromLTRB(
                isTablet ? 32 : 24,
                isTablet ? 24 : 20,
                isTablet ? 32 : 24,
                isTablet ? 20 : 16,
              ),
              height: isTablet
                  ? 66
                  : 52, // Increased height for better prominence
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20), // More rounded
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[500]!,
                      Colors.blue[600]!,
                      Colors.blue[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[600]!.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(6),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700, // Bolder text
                  fontSize: isTablet ? 18 : 14, // Larger font
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 18 : 14,
                ),
                tabs: [
                  Tab(
                    height: isTablet ? 54 : 40, // Increased tab height
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_emotions_rounded,
                          size: isTablet ? 28 : 20, // Larger icons
                        ),
                        SizedBox(width: isTablet ? 10 : 6),
                        const Text('Emojis'),
                      ],
                    ),
                  ),
                  Tab(
                    height: isTablet ? 54 : 40, // Increased tab height
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.palette_rounded,
                          size: isTablet ? 28 : 20, // Larger icons
                        ),
                        SizedBox(width: isTablet ? 8 : 6),
                        const Text('Colors'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: isTablet ? 70 : 50,
                            height: isTablet ? 70 : 50,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              color: Colors.blue[600],
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'Loading your preferences...',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error.isNotEmpty
                  ? Center(
                      child: Container(
                        margin: EdgeInsets.all(isTablet ? 32 : 24),
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[200]!, width: 1),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isTablet ? 70 : 50,
                              height: isTablet ? 70 : 50,
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: isTablet ? 38 : 28,
                                color: Colors.red[600],
                              ),
                            ),
                            SizedBox(height: isTablet ? 16 : 12),
                            Text(
                              'Failed to load preferences',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.red[800],
                              ),
                            ),
                            SizedBox(height: isTablet ? 8 : 6),
                            Text(
                              'Please check your connection and try again',
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 10,
                                color: Colors.red[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red[500]!, Colors.red[600]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _loadUserPreferences,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 20 : 16,
                                      vertical: isTablet ? 12 : 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.white,
                                          size: isTablet ? 22 : 16,
                                        ),
                                        SizedBox(width: isTablet ? 8 : 6),
                                        Text(
                                          'Try Again',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: isTablet ? 16 : 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEmojiTab(isTablet),
                        _buildColorTab(isTablet),
                      ],
                    ),
            ),

            // Modern Action buttons
            Container(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 20,
                isTablet ? 20 : 16,
                isTablet ? 24 : 20,
                isTablet ? 24 : 20,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: isTablet ? 54 : 44,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).pop(),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Container(
                      height: isTablet ? 54 : 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[500]!, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue[600]!.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            // Apply changes to the order
                            widget.order.emoji = _selectedEmoji;
                            widget.order.color = _selectedColor;
                            Navigator.of(context).pop();
                            widget.onChanged();
                          },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: isTablet ? 24 : 18,
                                ),
                                SizedBox(width: isTablet ? 10 : 6),
                                Text(
                                  'Apply Changes',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiTab(bool isTablet) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 16 : 12,
        isTablet ? 24 : 20,
        isTablet ? 16 : 12,
      ),
      child: Column(
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose your emoji',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[500]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[600]!.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _addEmoji,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 10 : 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: isTablet ? 22 : 16,
                          ),
                          SizedBox(width: isTablet ? 8 : 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 16 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),

          // Enhanced emojis grid
          Expanded(
            child: _emojis.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: isTablet ? 90 : 64,
                          height: isTablet ? 90 : 64,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.emoji_emotions_outlined,
                            size: isTablet ? 48 : 32,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        Text(
                          'No emojis available',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: isTablet ? 8 : 6),
                        Text(
                          'Add your first emoji to get started',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet
                          ? 6
                          : 4, // Increased count for smaller emojis
                      crossAxisSpacing: isTablet ? 14 : 8, // Reduced spacing
                      mainAxisSpacing: isTablet ? 14 : 8, // Reduced spacing
                      childAspectRatio: 1,
                    ),
                    itemCount: _emojis.length,
                    itemBuilder: (context, index) {
                      final emoji = _emojis[index];
                      final isSelected = _selectedEmoji == emoji.emojiText;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                _selectedEmoji = emoji.emojiText;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue[50]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue[500]!
                                      : Colors.grey[200]!,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.blue[500]!.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.grey.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: Text(
                                  emoji.emojiText,
                                  style: TextStyle(
                                    fontSize: isTablet
                                        ? 36
                                        : 28, // Increased emoji size in grid
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorTab(bool isTablet) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 16 : 12,
        isTablet ? 24 : 20,
        isTablet ? 16 : 12,
      ),
      child: Column(
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose your color',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[500]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[600]!.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _addColor,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 12,
                        vertical: isTablet ? 12 : 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: isTablet ? 22 : 16,
                          ),
                          SizedBox(width: isTablet ? 8 : 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 16 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),

          // Enhanced colors grid
          Expanded(
            child: _colors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: isTablet ? 90 : 64,
                          height: isTablet ? 90 : 64,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.palette_outlined,
                            size: isTablet ? 48 : 32,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        Text(
                          'No colors available',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: isTablet ? 8 : 6),
                        Text(
                          'Add your first color to get started',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet
                          ? 6
                          : 4, // Increased count for smaller cards
                      crossAxisSpacing: isTablet ? 14 : 8, // Reduced spacing
                      mainAxisSpacing: isTablet ? 14 : 8, // Reduced spacing
                      childAspectRatio: 1,
                    ),
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      final color = _colors[index];
                      final isSelected = _selectedColor == color.color;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                _selectedColor = color.color;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.fromHex(color.color),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[300]!,
                                  width: isSelected ? 4 : 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.fromHex(
                                            color.color,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                        const BoxShadow(
                                          color: Colors.white,
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.grey.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: isTablet ? 24 : 16,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
