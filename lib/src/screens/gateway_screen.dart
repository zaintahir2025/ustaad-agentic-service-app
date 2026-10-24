import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../ustaad_state.dart';
import '../data/models/user_role.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common_widgets.dart';

class GatewayScreen extends StatefulWidget {
  const GatewayScreen({super.key});

  @override
  State<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends State<GatewayScreen> {
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _joinName = TextEditingController();
  final _joinEmail = TextEditingController();
  final _joinPhone = TextEditingController();
  final _joinPassword = TextEditingController();
  final _recoveryPassword = TextEditingController();
  final _recoveryConfirmPassword = TextEditingController();
  final _phoneInput = TextEditingController(text: '+92 300 1234567');
  final _otpInput = TextEditingController();

  bool _creatingAccount = false;
  bool _usePhoneAuth = false;
  bool _otpSent = false;
  bool _remember = false;
  bool _obscure = true;
  int _failedLoginAttempts = 0;
  DateTime? _loginLockedUntil;
  Timer? _lockoutTimer;
  Timer? _otpTimer;
  int _otpCountdown = 60;
  String? _emailError;
  String? _phoneError;
  String? _otpError;
  UserRole _selectedRole = UserRole.customer;

  @override
  void initState() {
    super.initState();
    final savedEmail = context.read<UstaadState>().savedEmail;
    _loginEmail.text = savedEmail;
    _remember = savedEmail.isNotEmpty;
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _otpTimer?.cancel();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _joinName.dispose();
    _joinEmail.dispose();
    _joinPhone.dispose();
    _joinPassword.dispose();
    _recoveryPassword.dispose();
    _recoveryConfirmPassword.dispose();
    _phoneInput.dispose();
    _otpInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
    final recoveryActive = context
        .select<UstaadState, bool>((state) => state.passwordRecoveryActive);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth < 420 ? 18.0 : 28.0;
            final vertical = constraints.maxHeight < 720 ? 18.0 : 28.0;
            final contentWidth = (constraints.maxWidth - (horizontal * 2))
                .clamp(0.0, 420.0)
                .toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: vertical,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (vertical * 2),
                ),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            LanguageButton(),
                            SizedBox(width: 4),
                            AuthThemeButton(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.center,
                          child: AuthBrandHeader(),
                        ),
                        const SizedBox(height: 20),
                        AuthPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!recoveryActive && !_usePhoneAuth) ...[
                                AuthTabs(
                                  creatingAccount: _creatingAccount,
                                  onLogin: () => setState(
                                    () => _creatingAccount = false,
                                  ),
                                  onJoin: () => setState(
                                    () => _creatingAccount = true,
                                  ),
                                ),
                                const SizedBox(height: 22),
                              ],
                              AnimatedSize(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: recoveryActive
                                      ? _passwordRecoveryForm()
                                      : _usePhoneAuth
                                          ? (_otpSent
                                              ? _otpVerificationForm()
                                              : _phoneLoginForm())
                                          : _creatingAccount
                                              ? _joinForm()
                                              : _loginForm(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _loginForm() {
    final l10n = AppLocalizations.of(context);
    final busy = context.watch<UstaadState>().authBusy;
    final pendingEmail = context.watch<UstaadState>().pendingConfirmationEmail;
    final coolingDown = context.watch<UstaadState>().authEmailCoolingDown;
    final cooldownSeconds =
        context.watch<UstaadState>().authEmailCooldownSeconds;
    final colors = AuthPalette.of(context);
    final loginLocked = _loginLocked;
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingEmail != null && pendingEmail.isNotEmpty) ...[
          EmailConfirmationNotice(
            email: pendingEmail,
            cooldownSeconds: coolingDown ? cooldownSeconds : 0,
            onResend: busy || coolingDown
                ? null
                : () => _resendConfirmation(pendingEmail),
          ),
          const SizedBox(height: 18),
        ],
        AuthTextField(
          controller: _loginEmail,
          label: l10n?.email ?? 'Enter Email Address',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 26),
        AuthPasswordField(
          controller: _loginPassword,
          label: l10n?.password ?? 'Enter Password',
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: busy ? null : _showResetDialog,
            style: TextButton.styleFrom(
              foregroundColor: colors.accent,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
            child: Text(l10n?.forgotPassword ?? 'Forgot Password?'),
          ),
        ),
        const SizedBox(height: 18),
        AuthButton(
          onPressed: busy || loginLocked ? null : _submitLogin,
          child: busy
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.fieldFill,
                  ),
                )
              : Text(loginLocked
                  ? _loginCooldownLabel
                  : (l10n?.signIn ?? 'Sign in')),
        ),
        if (loginLocked) ...[
          const SizedBox(height: 10),
          const SecurityInlineMessage(
            icon: Icons.lock_clock,
            text: 'Too many failed attempts. Sign in unlocks shortly.',
          ),
        ],
        const SizedBox(height: 14),
        AuthRememberRow(
          value: _remember,
          onChanged: (value) => setState(() => _remember = value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Divider(color: colors.border.withValues(alpha: 0.7))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.muted,
                ),
              ),
            ),
            Expanded(child: Divider(color: colors.border.withValues(alpha: 0.7))),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy || loginLocked
              ? null
              : () => setState(() {
                    _usePhoneAuth = true;
                    _otpSent = false;
                  }),
          icon: const Icon(Icons.phone_android_rounded, size: 18),
          label: const Text('Sign in with Phone (OTP)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: BorderSide(color: colors.accent.withValues(alpha: 0.6)),
            foregroundColor: colors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GuestAccessButton(onPressed: busy ? null : _continueAsGuest),
      ],
    );
  }

  Widget _phoneLoginForm() {
    final colors = AuthPalette.of(context);
    final busy = context.watch<UstaadState>().authBusy;

    return Column(
      key: const ValueKey('phone_login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.phone_iphone_rounded, color: colors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone Number Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    'ہم آپ کے نمبر پر 6 ہندسوں کا کوڈ بھیجیں گے',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AuthTextField(
          controller: _phoneInput,
          label: 'Enter Mobile Number (+923XXXXXXXXX)',
          keyboardType: TextInputType.phone,
          errorText: _phoneError,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        const SizedBox(height: 18),
        AuthButton(
          onPressed: busy ? null : _submitPhoneSend,
          child: busy
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.fieldFill,
                  ),
                )
              : const Text('Send Verification Code (OTP)'),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() {
              _usePhoneAuth = false;
              _otpSent = false;
              _phoneError = null;
            }),
            icon: const Icon(Icons.mail_outline_rounded, size: 16),
            label: const Text('Use Email / Password Instead'),
            style: TextButton.styleFrom(
              foregroundColor: colors.muted,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _otpVerificationForm() {
    final colors = AuthPalette.of(context);
    final busy = context.watch<UstaadState>().authBusy;

    return Column(
      key: const ValueKey('otp_verification'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.mark_email_read_rounded, color: colors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify Phone Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    'کوڈ درج کر کے تصدیق مکمل کریں',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.sms_outlined, size: 16, color: colors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sent to ${_phoneInput.text.trim()}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.text),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _otpSent = false),
                child: Text(
                  'Edit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AuthTextField(
          controller: _otpInput,
          label: '6-Digit Verification Code',
          keyboardType: TextInputType.number,
          errorText: _otpError,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _otpCountdown > 0
                  ? 'Resend code in ${_otpCountdown}s'
                  : 'Didn\'t get code?',
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
            TextButton(
              onPressed: _otpCountdown == 0 ? _submitPhoneSend : null,
              style: TextButton.styleFrom(
                foregroundColor: colors.accent,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Resend Code',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AuthButton(
          onPressed: busy ? null : _submitOtpVerify,
          child: busy
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.fieldFill,
                  ),
                )
              : const Text('Verify & Sign In (تصدیق کریں)'),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() {
              _usePhoneAuth = false;
              _otpSent = false;
              _otpError = null;
            }),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back to Email Login'),
            style: TextButton.styleFrom(
              foregroundColor: colors.muted,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _joinForm() {
    final l10n = AppLocalizations.of(context);
    final busy = context.watch<UstaadState>().authBusy;
    final coolingDown = context.watch<UstaadState>().authEmailCoolingDown;
    final colors = AuthPalette.of(context);
    final strength = calculatePasswordStrength(_joinPassword.text);
    return Column(
      key: const ValueKey('join'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.fieldFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRole = UserRole.customer),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedRole.isCustomer ? colors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '👤 Customer (گاہک)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedRole.isCustomer ? Colors.white : colors.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRole = UserRole.provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedRole.isProvider ? colors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '🛠️ Provider (استاد)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedRole.isProvider ? Colors.white : colors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AuthTextField(
          controller: _joinName,
          label: l10n?.fullName ?? 'Enter Full Name',
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: 22),
        AuthTextField(
          controller: _joinEmail,
          label: l10n?.email ?? 'Enter Email Address',
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 22),
        AuthTextField(
          controller: _joinPhone,
          label: l10n?.phoneNumber ?? 'Enter Phone Number',
          keyboardType: TextInputType.phone,
          errorText: _phoneError,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        const SizedBox(height: 22),
        AuthPasswordField(
          controller: _joinPassword,
          label: l10n?.password ?? 'Enter Password',
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        PasswordStrengthMeter(strength: strength),
        const SizedBox(height: 18),
        AuthButton(
          onPressed: busy ? null : _submitJoin,
          child: busy
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.fieldFill,
                  ),
                )
              : Text(
                  coolingDown
                      ? 'Create local account'
                      : (l10n?.createAccount ?? 'Create account'),
                ),
        ),
        if (coolingDown) ...[
          const SizedBox(height: 10),
          const SecurityInlineMessage(
            icon: Icons.schedule,
            text:
                'Email sending paused for a few minutes due to rate limits. You can still use guest mode.',
          ),
        ],
        const SizedBox(height: 14),
        AuthRememberRow(
          value: _remember,
          onChanged: (value) => setState(() => _remember = value),
        ),
        const SizedBox(height: 10),
        GuestAccessButton(onPressed: busy ? null : _continueAsGuest),
      ],
    );
  }

  Widget _passwordRecoveryForm() {
    final busy = context.watch<UstaadState>().authBusy;
    final colors = AuthPalette.of(context);
    final strength = calculatePasswordStrength(_recoveryPassword.text);
    return Column(
      key: const ValueKey('password-recovery'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SecurityInlineMessage(
          icon: Icons.verified_user_outlined,
          text:
              'Recovery link verified. Choose a new password for your account.',
        ),
        const SizedBox(height: 22),
        AuthPasswordField(
          controller: _recoveryPassword,
          label: 'New Password',
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        PasswordStrengthMeter(strength: strength),
        const SizedBox(height: 22),
        AuthPasswordField(
          controller: _recoveryConfirmPassword,
          label: 'Confirm Password',
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure),
        ),
        const SizedBox(height: 18),
        AuthButton(
          onPressed: busy ? null : _submitPasswordRecovery,
          child: busy
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.fieldFill,
                  ),
                )
              : const Text('Update password'),
        ),
      ],
    );
  }

  void _submitPhoneSend() {
    final phone = _phoneInput.text.trim();
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final regex = RegExp(r'^\+92[0-9]{10}$|^03[0-9]{9}$');
    if (!regex.hasMatch(cleanPhone)) {
      setState(() => _phoneError = 'Use Pakistani format: +923XXXXXXXXX');
      return;
    }
    setState(() {
      _phoneError = null;
      _otpSent = true;
      _otpCountdown = 60;
    });
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpCountdown > 0) {
        setState(() => _otpCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _submitOtpVerify() async {
    final code = _otpInput.text.trim();
    if (code.length != 6) {
      setState(() => _otpError = 'Enter the complete 6-digit code');
      return;
    }
    setState(() => _otpError = null);
    final ok = await context.read<UstaadState>().signInWithOtpMock(
          phone: _phoneInput.text.trim(),
          code: code,
          role: _selectedRole,
        );
    if (!mounted) return;
    if (!ok) {
      setState(() => _otpError = 'Invalid code. Please check and try again.');
    }
  }

  Future<void> _submitLogin() async {
    if (_loginLocked) {
      _show('Sign in is locked for $_loginCooldownLabel.');
      return;
    }
    final email = _loginEmail.text.trim();
    final password = _loginPassword.text.trim();
    if (!_validEmail(email)) {
      _show('Enter a valid email.');
      return;
    }
    if (password.isEmpty) {
      _show('Enter your password.');
      return;
    }

    final ok = await context.read<UstaadState>().signIn(
          email: email,
          password: password,
          remember: _remember,
        );
    if (!mounted) return;
    if (ok) {
      _clearLoginGuard();
      return;
    }
    _recordFailedLogin();
    _show(context.read<UstaadState>().bannerMessage ?? 'Login failed.');
  }

  Future<void> _submitJoin() async {
    final name = _joinName.text.trim();
    final email = _joinEmail.text.trim();
    final phone = _joinPhone.text.trim();
    final password = _joinPassword.text.trim();
    final phoneRegex = RegExp(r'^\+92[0-9]{10}$');

    setState(() {
      _emailError = _validEmail(email) ? null : 'Invalid email';
      _phoneError = phoneRegex.hasMatch(phone) ? null : 'Use +923001234567';
    });

    if (name.isEmpty) {
      _show('Enter your name.');
      return;
    }
    if (_emailError != null || _phoneError != null) return;
    final strength = calculatePasswordStrength(password);
    if (!strength.acceptable) {
      _show('Use 8+ chars with upper, lower, number, and symbol.');
      return;
    }

    final ok = await context.read<UstaadState>().join(
          name: name,
          email: email,
          phone: phone,
          password: password,
          remember: _remember,
        );
    if (!mounted) return;
    if (ok) {
      _joinPassword.clear();
      _loginEmail.text = email;
      setState(() => _creatingAccount = false);
      _show(context.read<UstaadState>().bannerMessage ??
          'Check your email to confirm your account.');
      return;
    }
    _show(context.read<UstaadState>().bannerMessage ?? 'Signup failed.');
  }

  Future<void> _continueAsGuest() async {
    await context.read<UstaadState>().continueAsGuest();
    if (!mounted) return;
    _show(context.read<UstaadState>().bannerMessage ?? 'Guest mode active.');
  }

  Future<void> _submitPasswordRecovery() async {
    final password = _recoveryPassword.text.trim();
    final confirm = _recoveryConfirmPassword.text.trim();
    final strength = calculatePasswordStrength(password);
    if (!strength.acceptable) {
      _show('Use 8+ chars with upper, lower, number, and symbol.');
      return;
    }
    if (password != confirm) {
      _show('Passwords do not match.');
      return;
    }
    final state = context.read<UstaadState>();
    final ok = await state.updatePassword(password);
    if (!mounted) return;
    if (!ok) {
      _show(state.bannerMessage ?? 'Password update failed.');
      return;
    }
    _recoveryPassword.clear();
    _recoveryConfirmPassword.clear();
  }

  bool _validEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showResetDialog() async {
    final email = TextEditingController(text: _loginEmail.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, email.text.trim()),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    email.dispose();
    if (result == null || result.isEmpty) return;
    if (!mounted) return;
    if (!_validEmail(result)) {
      _show('Enter a valid email.');
      return;
    }
    final state = context.read<UstaadState>();
    final ok = await state.resetPassword(result);
    if (!mounted) return;
    _show(state.bannerMessage ??
        (ok ? 'Password reset email sent.' : 'Password reset failed.'));
  }

  Future<void> _resendConfirmation(String email) async {
    final state = context.read<UstaadState>();
    final ok = await state.resendConfirmationEmail(email);
    if (!mounted) return;
    _show(state.bannerMessage ??
        (ok ? 'Confirmation email sent.' : 'Could not resend email.'));
  }

  bool get _loginLocked {
    final until = _loginLockedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  String get _loginCooldownLabel {
    final until = _loginLockedUntil;
    if (until == null) return 'Try again';
    final seconds = until.difference(DateTime.now()).inSeconds.clamp(1, 60);
    return 'Try again in ${seconds}s';
  }

  void _recordFailedLogin() {
    _failedLoginAttempts += 1;
    if (_failedLoginAttempts < 5) return;
    _loginLockedUntil = DateTime.now().add(const Duration(seconds: 30));
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_loginLocked) {
        _clearLoginGuard();
        return;
      }
      setState(() {});
    });
    setState(() {});
  }

  void _clearLoginGuard() {
    _failedLoginAttempts = 0;
    _loginLockedUntil = null;
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    if (mounted) setState(() {});
  }
}
