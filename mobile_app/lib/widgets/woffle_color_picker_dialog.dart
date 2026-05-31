import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<Color?> showColorPickerDialog(BuildContext context) async {
  return showDialog<Color>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _RgbColorPickerDialog(),
  );
}

class _RgbColorPickerDialog extends StatefulWidget {
  const _RgbColorPickerDialog();

  @override
  State<_RgbColorPickerDialog> createState() => _RgbColorPickerDialogState();
}

class _RgbColorPickerDialogState extends State<_RgbColorPickerDialog> {
  int _r = 33, _g = 150, _b = 243; // Default: #2196F3
  bool _updatingFromHex = false;

  final _rCtrl = TextEditingController(text: '33');
  final _gCtrl = TextEditingController(text: '150');
  final _bCtrl = TextEditingController(text: '243');
  final _hexCtrl = TextEditingController(text: '2196F3');

  static const List<Color> _presets = [
    Color(0xFF2196F3),
    Color(0xFFF44336),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFFFFEB3B),
    Color(0xFFFF9800),
    Color(0xFFFF5722),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];

  @override
  void dispose() {
    _rCtrl.dispose();
    _gCtrl.dispose();
    _bCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  Color get _color => Color.fromRGBO(_r, _g, _b, 1.0);

  String _toHexStr() =>
      '${_r.toRadixString(16).padLeft(2, '0')}'
              '${_g.toRadixString(16).padLeft(2, '0')}'
              '${_b.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  void _updateHex() {
    if (!_updatingFromHex) _hexCtrl.text = _toHexStr();
  }

  void _setR(int v) => setState(() {
    _r = v.clamp(0, 255);
    _rCtrl.text = '$_r';
    _updateHex();
  });
  void _setG(int v) => setState(() {
    _g = v.clamp(0, 255);
    _gCtrl.text = '$_g';
    _updateHex();
  });
  void _setB(int v) => setState(() {
    _b = v.clamp(0, 255);
    _bCtrl.text = '$_b';
    _updateHex();
  });

  void _fromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      try {
        final r = int.parse(hex.substring(0, 2), radix: 16);
        final g = int.parse(hex.substring(2, 4), radix: 16);
        final b = int.parse(hex.substring(4, 6), radix: 16);
        _updatingFromHex = true;
        setState(() {
          _r = r;
          _g = g;
          _b = b;
          _rCtrl.text = '$r';
          _gCtrl.text = '$g';
          _bCtrl.text = '$b';
        });
        _updatingFromHex = false;
      } catch (_) {}
    }
  }

  void _pickPreset(Color c) => setState(() {
    _r = (c.r * 255.0).round().clamp(0, 255);
    _g = (c.g * 255.0).round().clamp(0, 255);
    _b = (c.b * 255.0).round().clamp(0, 255);
    _rCtrl.text = '$_r';
    _gCtrl.text = '$_g';
    _bCtrl.text = '$_b';
    _hexCtrl.text = _toHexStr();
  });

  Widget _rgbSlider(
    String label,
    int val,
    Color activeColor,
    ValueChanged<int> onChanged,
    TextEditingController ctrl,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 5,
                activeTrackColor: activeColor,
                inactiveTrackColor: activeColor.withValues(alpha: 0.15),
                thumbColor: activeColor,
                overlayColor: activeColor.withValues(alpha: 0.15),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              ),
              child: Slider(
                value: val.toDouble(),
                min: 0,
                max: 255,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 54,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: activeColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onChanged: (s) {
                final n = int.tryParse(s);
                if (n != null && n >= 0 && n <= 255) onChanged(n);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: isTablet ? 440 : 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Colour header (background = current colour) ───────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              color: _color,
              child: Row(
                children: [
                  Container(
                    width: isTablet ? 90 : 72,
                    height: isTablet ? 90 : 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: isTablet ? 65 : 52,
                        height: isTablet ? 65 : 52,
                        decoration: BoxDecoration(
                          color: _color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pick a Color',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 22 : 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R: $_r   G: $_g   B: $_b',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: isTablet ? 13 : 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Hex input inside header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tag,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              IntrinsicWidth(
                                child: TextField(
                                  controller: _hexCtrl,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9a-fA-F]'),
                                    ),
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTablet ? 16 : 14,
                                    letterSpacing: 2,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: _fromHex,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── RGB sliders + quick presets ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RGB VALUES',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _rgbSlider('R', _r, Colors.red[600]!, _setR, _rCtrl),
                  _rgbSlider('G', _g, Colors.green[600]!, _setG, _gCtrl),
                  _rgbSlider('B', _b, Colors.blue[600]!, _setB, _bCtrl),
                  const SizedBox(height: 16),
                  Text(
                    'QUICK PRESETS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets.map((c) {
                      final isSel =
                          _r == (c.r * 255.0).round().clamp(0, 255) &&
                          _g == (c.g * 255.0).round().clamp(0, 255) &&
                          _b == (c.b * 255.0).round().clamp(0, 255);
                      return GestureDetector(
                        onTap: () => _pickPreset(c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: isTablet ? 38 : 32,
                          height: isTablet ? 38 : 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: c.withValues(alpha: isSel ? 0.6 : 0.35),
                                blurRadius: isSel ? 10 : 4,
                              ),
                            ],
                          ),
                          child: isSel
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Action buttons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_color),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                        shadowColor: _color.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Add Color',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isTablet ? 16 : 14,
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
}
