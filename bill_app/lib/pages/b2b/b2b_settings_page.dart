import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/b2b_settings.dart';
import '../../services/b2b_storage_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'b2b_catalog_settings_page.dart';

class B2BSettingsPage extends StatefulWidget {
  final B2BSettings settings;

  const B2BSettingsPage({super.key, required this.settings});

  @override
  State<B2BSettingsPage> createState() => _B2BSettingsPageState();
}

class _B2BSettingsPageState extends State<B2BSettingsPage> {
  late B2BSettings _settings;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Controllers
  late TextEditingController _gstinCtrl;
  late TextEditingController _companyNameCtrl;
  late TextEditingController _companyTypeCtrl;
  late TextEditingController _addr1Ctrl;
  late TextEditingController _addr2Ctrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _stateCodeCtrl;
  late TextEditingController _phone1Ctrl;
  late TextEditingController _phone2Ctrl;
  late TextEditingController _hsnCtrl;
  late TextEditingController _invPrefixCtrl;
  late TextEditingController _invNextCtrl;
  late TextEditingController _pdfPathCtrl;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _initControllers();
  }

  void _initControllers() {
    _gstinCtrl = TextEditingController(text: _settings.gstin);
    _companyNameCtrl = TextEditingController(text: _settings.companyName);
    _companyTypeCtrl = TextEditingController(text: _settings.companyType);
    _addr1Ctrl = TextEditingController(text: _settings.addressLine1);
    _addr2Ctrl = TextEditingController(text: _settings.addressLine2);
    _cityCtrl = TextEditingController(text: _settings.city);
    _stateCtrl = TextEditingController(text: _settings.state);
    _stateCodeCtrl = TextEditingController(
      text: _settings.stateCode.toString(),
    );
    _phone1Ctrl = TextEditingController(text: _settings.phone1);
    _phone2Ctrl = TextEditingController(text: _settings.phone2);
    _hsnCtrl = TextEditingController(text: _settings.defaultHsnCode);
    _invPrefixCtrl = TextEditingController(text: _settings.invoicePrefix);
    _invNextCtrl = TextEditingController(
      text: _settings.nextInvoiceNumber.toString(),
    );
    _pdfPathCtrl = TextEditingController(text: _settings.pdfSavePath);

    for (final c in _allControllers) {
      c.addListener(() => setState(() => _hasChanges = true));
    }
  }

  List<TextEditingController> get _allControllers => [
    _gstinCtrl,
    _companyNameCtrl,
    _companyTypeCtrl,
    _addr1Ctrl,
    _addr2Ctrl,
    _cityCtrl,
    _stateCtrl,
    _stateCodeCtrl,
    _phone1Ctrl,
    _phone2Ctrl,
    _hsnCtrl,
    _invPrefixCtrl,
    _invNextCtrl,
    _pdfPathCtrl,
  ];

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickSaveFolder() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose PDF save folder',
    );
    if (dir != null) {
      setState(() {
        _pdfPathCtrl.text = dir;
        _hasChanges = true;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    _settings.gstin = _gstinCtrl.text.trim();
    _settings.companyName = _companyNameCtrl.text.trim();
    _settings.companyType = _companyTypeCtrl.text.trim();
    _settings.addressLine1 = _addr1Ctrl.text.trim();
    _settings.addressLine2 = _addr2Ctrl.text.trim();
    _settings.city = _cityCtrl.text.trim();
    _settings.state = _stateCtrl.text.trim();
    _settings.stateCode =
        int.tryParse(_stateCodeCtrl.text) ?? _settings.stateCode;
    _settings.phone1 = _phone1Ctrl.text.trim();
    _settings.phone2 = _phone2Ctrl.text.trim();
    _settings.defaultHsnCode = _hsnCtrl.text.trim();
    _settings.defaultGstPercent = 0.0;
    _settings.invoicePrefix = _invPrefixCtrl.text.trim();
    _settings.nextInvoiceNumber =
        int.tryParse(_invNextCtrl.text) ?? _settings.nextInvoiceNumber;
    _settings.pdfSavePath = _pdfPathCtrl.text.trim();

    await B2BStorageService.saveSettings(_settings);
    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('B2B Settings saved!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('B2B Settings'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _hasChanges ? _save : null,
              icon: Icon(
                Icons.save,
                color: _hasChanges ? Colors.white : Colors.white38,
                size: 18,
              ),
              label: Text(
                'Save',
                style: TextStyle(
                  color: _hasChanges ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppTheme.isMobileOnly(context) ? 16 : 24),
        children: [
          // ── Supplier Info ──────────────────────────────────────────────
          _section(
            title: 'Supplier / Company Info',
            icon: Icons.business_outlined,
            children: [
              _field(
                _gstinCtrl,
                'GSTIN',
                hint: '32ACIFA8866E1ZB',
                caps: TextCapitalization.characters,
              ),
              _field(
                _companyNameCtrl,
                'Company Name *',
                caps: TextCapitalization.characters,
              ),
              _field(
                _companyTypeCtrl,
                'Company Type',
                hint: 'LLP / Pvt Ltd',
                caps: TextCapitalization.words,
              ),
              _field(
                _addr1Ctrl,
                'Address Line 1',
                caps: TextCapitalization.sentences,
              ),
              _field(
                _addr2Ctrl,
                'Address Line 2',
                caps: TextCapitalization.sentences,
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _cityCtrl,
                      'City',
                      caps: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      _stateCtrl,
                      'State',
                      caps: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 70,
                    child: _field(
                      _stateCodeCtrl,
                      'Code',
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _phone1Ctrl,
                      'Phone 1',
                      keyboard: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      _phone2Ctrl,
                      'Phone 2',
                      keyboard: TextInputType.phone,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Invoice Defaults ───────────────────────────────────────────
          _section(
            title: 'Invoice Defaults',
            icon: Icons.receipt_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _hsnCtrl,
                      'Default HSN Code',
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: _field(
                      _invPrefixCtrl,
                      'Inv. Prefix',
                      hint: 'C',
                      caps: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      _invNextCtrl,
                      'Next Invoice Number',
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              // Preview
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next invoice: ${_invPrefixCtrl.text}${(int.tryParse(_invNextCtrl.text) ?? 1).toString().padLeft(3, '0')}',
                      style: TextStyle(
                        fontSize: AppTheme.isMobileOnly(context) ? 13 : 16,
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── PDF Save Path ─────────────────────────────────────────────────────
          _section(
            title: 'PDF Save Location',
            icon: Icons.folder_outlined,
            children: [
              // Read-only path display + Browse button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        _pdfPathCtrl.text.isEmpty
                            ? 'Default — Downloads/B2B_Invoices'
                            : _pdfPathCtrl.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: _pdfPathCtrl.text.isEmpty
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickSaveFolder,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('Browse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (_pdfPathCtrl.text.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _pdfPathCtrl.text = '';
                      _hasChanges = true;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Reset to default'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              const Text(
                'Tap Browse to choose where invoices are saved.\nLeave default to save in Downloads/B2B_Invoices.',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Product Catalog ────────────────────────────────────────────
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => B2BCatalogSettingsPage(settings: _settings),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.elevationSmall,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.price_change_outlined,
                      color: Color(0xFF1565C0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'B2B Product Catalog',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppTheme.isMobileOnly(context) ? 14 : 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Set B2B prices and HSN codes per product',
                          style: TextStyle(
                            fontSize: AppTheme.isMobileOnly(context) ? 12 : 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Access Password ────────────────────────────────────────────
          InkWell(
            onTap: _showPasswordDialog,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.elevationSmall,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF1565C0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'B2B Access Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppTheme.isMobileOnly(context) ? 14 : 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _settings.passwordSet
                              ? 'Change or remove the access password'
                              : 'Set a password to restrict staff access',
                          style: TextStyle(
                            fontSize: AppTheme.isMobileOnly(context) ? 12 : 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _settings.passwordSet ? Icons.lock : Icons.lock_open,
                    color: _settings.passwordSet
                        ? const Color(0xFF1565C0)
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          ElevatedButton.icon(
            onPressed: _hasChanges ? _save : null,
            icon: const Icon(Icons.save),
            label: Text(
              'Save Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.isMobileOnly(context) ? 15 : 18,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.borderMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Password management ─────────────────────────────────────────────────

  void _showPasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PasswordSheet(
        passwordSet: _settings.passwordSet,
        onChanged: () {
          // Reload settings so the tile label updates
          B2BStorageService.loadSettings().then((s) {
            if (mounted) setState(() => _settings = s);
          });
        },
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.elevationSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppTheme.isMobileOnly(context) ? 18 : 22,
                  color: const Color(0xFF1565C0),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.isMobileOnly(context) ? 14 : 17,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

// ─── Password Sheet ────────────────────────────────────────────────────────────

class _PasswordSheet extends StatefulWidget {
  final bool passwordSet;
  final VoidCallback onChanged;

  const _PasswordSheet({required this.passwordSet, required this.onChanged});

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _currentCtrl.text;
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    // Validate
    if (widget.passwordSet && current.isEmpty) {
      setState(() => _error = 'Enter your current password');
      return;
    }
    if (newPass.isNotEmpty && newPass.length < 4) {
      setState(() => _error = 'New password must be at least 4 characters');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'New passwords do not match');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.setB2BPassword(
        oldPassword: widget.passwordSet ? current : null,
        newPassword: newPass,
      );
      if (!mounted) return;
      widget.onChanged();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newPass.isEmpty ? 'Password removed' : 'Password updated',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: Color(0xFF1565C0)),
              const SizedBox(width: 10),
              Text(
                widget.passwordSet ? 'Change Password' : 'Set Password',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current password (only when already set)
          if (widget.passwordSet) ...[
            _passField(
              _currentCtrl,
              'Current Password',
              _obscureCurrent,
              () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 12),
          ],

          _passField(
            _newCtrl,
            widget.passwordSet
                ? 'New Password (leave empty to remove)'
                : 'New Password',
            _obscureNew,
            () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),

          _passField(
            _confirmCtrl,
            'Confirm New Password',
            _obscureConfirm,
            () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.borderLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.passwordSet ? 'Update Password' : 'Set Password',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passField(
    TextEditingController ctrl,
    String label,
    bool obscure,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        isDense: true,
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textTertiary,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }
}
