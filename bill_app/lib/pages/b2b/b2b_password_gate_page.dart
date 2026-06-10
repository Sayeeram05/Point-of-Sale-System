import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'b2b_dashboard_page.dart';

/// Guards entry to the B2B section with an alphanumeric password.
///
/// Flow:
///   - If no password has been set  -> show "Create Password" form (forced setup)
///   - If a password is set         -> show a password entry field
///
/// Locked-out after 5 consecutive wrong attempts for 30 seconds.
class B2BPasswordGatePage extends StatefulWidget {
  const B2BPasswordGatePage({super.key});

  @override
  State<B2BPasswordGatePage> createState() => _B2BPasswordGatePageState();
}

class _B2BPasswordGatePageState extends State<B2BPasswordGatePage>
    with SingleTickerProviderStateMixin {
  // App theme accent — matches the B2B blue used across the section
  static const Color _accent = Color(0xFF1565C0);

  // ── State ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _passwordSet = false;

  // Entry mode
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _errorText;
  bool _checking = false;

  // Failed attempts / lockout
  int _failedAttempts = 0;
  static const int _maxAttempts = 5;
  static const int _lockoutSeconds = 30;
  int _lockoutRemaining = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Setup mode (no password set)
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _setupError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 24,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _checkPasswordStatus();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _passwordCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> _checkPasswordStatus() async {
    try {
      final data = await ApiService.getB2BSettings();
      final passwordSet = data['password_set'] as bool? ?? false;
      setState(() {
        _passwordSet = passwordSet;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── Lockout timer ──────────────────────────────────────────────────────────

  void _startLockout() {
    setState(() => _lockoutRemaining = _lockoutSeconds);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _lockoutRemaining--);
      return _lockoutRemaining > 0;
    }).then((_) {
      if (mounted) setState(() => _failedAttempts = 0);
    });
  }

  bool get _isLockedOut => _lockoutRemaining > 0;

  // ── Password verify ────────────────────────────────────────────────────────

  Future<void> _verify() async {
    if (_isLockedOut || _checking) return;
    final entered = _passwordCtrl.text.trim();
    if (entered.isEmpty) {
      setState(() => _errorText = 'Please enter your password');
      return;
    }

    setState(() {
      _checking = true;
      _errorText = null;
    });

    try {
      final result = await ApiService.verifyB2BPassword(entered);
      if (!mounted) return;
      final valid = result['valid'] as bool? ?? false;

      if (valid) {
        _navigateToDashboard();
      } else {
        _failedAttempts++;
        _shakeController.forward(from: 0);
        if (_failedAttempts >= _maxAttempts) {
          setState(() {
            _errorText = null;
            _passwordCtrl.clear();
            _checking = false;
          });
          _startLockout();
        } else {
          setState(() {
            _errorText =
                'Incorrect password. ${_maxAttempts - _failedAttempts} attempts remaining.';
            _checking = false;
            _passwordCtrl.clear();
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Connection error. Please try again.';
        _checking = false;
      });
    }
  }

  // ── Password setup ─────────────────────────────────────────────────────────

  Future<void> _setupPassword() async {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmCtrl.text;

    if (newPass.isEmpty) {
      setState(() => _setupError = 'Password cannot be empty');
      return;
    }
    if (newPass.length < 4) {
      setState(() => _setupError = 'Password must be at least 4 characters');
      return;
    }
    if (newPass != confirm) {
      setState(() => _setupError = 'Passwords do not match');
      return;
    }

    setState(() {
      _saving = true;
      _setupError = null;
    });

    try {
      await ApiService.setB2BPassword(newPassword: newPass);
      if (!mounted) return;
      _navigateToDashboard();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _setupError = 'Failed to set password. Please try again.';
        _saving = false;
      });
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const B2BDashboardPage()),
    );
  }

  // ── Themed input decoration ────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String hint,
    required bool obscure,
    required VoidCallback toggleObscure,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textTertiary),
      filled: true,
      fillColor: AppTheme.surfaceColor,
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
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.error, width: 2),
      ),
      errorText: errorText,
      errorStyle: const TextStyle(color: AppTheme.error),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: AppTheme.textTertiary,
        ),
        onPressed: toggleObscure,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: _accent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('B2B Access'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.isMobileOnly(context) ? 28 : 60,
                    vertical: AppTheme.isMobileOnly(context) ? 24 : 32,
                  ),
                  child: _passwordSet ? _buildVerifyForm() : _buildSetupForm(),
                ),
              ),
            ),
    );
  }

  // ── Verify form ────────────────────────────────────────────────────────────

  Widget _buildVerifyForm() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          _shakeController.isAnimating
              ? (_shakeAnimation.value *
                    ((_shakeController.value * 10).floor().isEven ? 1 : -1))
              : 0,
          0,
        ),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: AppTheme.isMobileOnly(context) ? 80 : 100,
            height: AppTheme.isMobileOnly(context) ? 80 : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.business_center_outlined,
              color: _accent,
              size: AppTheme.isMobileOnly(context) ? 40 : 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'B2B Access',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.isMobileOnly(context) ? 26 : 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your password to continue',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.isMobileOnly(context) ? 14 : 17,
            ),
          ),
          const SizedBox(height: 36),

          // Lockout banner
          if (_isLockedOut) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: AppTheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Too many attempts. Try again in $_lockoutRemaining seconds.',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontSize: AppTheme.isMobileOnly(context) ? 13 : 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Password field
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            enabled: !_isLockedOut && !_checking,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: _inputDecoration(
              hint: 'Password',
              obscure: _obscure,
              toggleObscure: () => setState(() => _obscure = !_obscure),
              errorText: _errorText,
            ),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: AppTheme.isMobileOnly(context) ? 50 : 56,
            child: ElevatedButton(
              onPressed: _isLockedOut || _checking ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                disabledBackgroundColor: AppTheme.borderLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: _checking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: AppTheme.isMobileOnly(context) ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Setup form ─────────────────────────────────────────────────────────────

  Widget _buildSetupForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppTheme.isMobileOnly(context) ? 80 : 100,
          height: AppTheme.isMobileOnly(context) ? 80 : 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.lock_outline,
            color: _accent,
            size: AppTheme.isMobileOnly(context) ? 40 : 50,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Set B2B Password',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.isMobileOnly(context) ? 26 : 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a password to protect the B2B section\nfrom staff access.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: AppTheme.isMobileOnly(context) ? 14 : 17,
          ),
        ),
        const SizedBox(height: 36),

        // New password field
        TextField(
          controller: _newPassCtrl,
          obscureText: _obscureNew,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'New Password',
            obscure: _obscureNew,
            toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 14),

        // Confirm password field
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Confirm Password',
            obscure: _obscureConfirm,
            toggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            errorText: _setupError,
          ),
          onSubmitted: (_) => _setupPassword(),
        ),
        const SizedBox(height: 20),

        // Save button
        SizedBox(
          width: double.infinity,
          height: AppTheme.isMobileOnly(context) ? 50 : 56,
          child: ElevatedButton(
            onPressed: _saving ? null : _setupPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              disabledBackgroundColor: AppTheme.borderLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Set Password & Continue',
                    style: TextStyle(
                      fontSize: AppTheme.isMobileOnly(context) ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
