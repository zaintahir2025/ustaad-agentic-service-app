import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'ustaad_state.dart';

class _AuthPalette {
  const _AuthPalette({
    required this.background,
    required this.panel,
    required this.fieldFill,
    required this.border,
    required this.accent,
    required this.warmAccent,
    required this.muted,
    required this.text,
    required this.error,
  });

  final Color background;
  final Color panel;
  final Color fieldFill;
  final Color border;
  final Color accent;
  final Color warmAccent;
  final Color muted;
  final Color text;
  final Color error;

  static _AuthPalette of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _AuthPalette(
      background: theme.scaffoldBackgroundColor,
      panel: theme.cardColor,
      fieldFill: theme.inputDecorationTheme.fillColor ?? scheme.surface,
      border: theme.dividerColor,
      accent: scheme.primary,
      warmAccent: scheme.secondary,
      muted: scheme.onSurfaceVariant,
      text: scheme.onSurface,
      error: scheme.error,
    );
  }
}

class UstaadRouter extends StatelessWidget {
  const UstaadRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();

    if (!state.bootstrapped) {
      return const _LoadingScreen();
    }

    final screen = switch (state.screen) {
      UstaadScreen.gateway => const GatewayScreen(),
      UstaadScreen.commandCenter => const CommandCenterScreen(),
      UstaadScreen.bookings => const BookingsScreen(),
      UstaadScreen.profile => const ProfileScreen(),
      UstaadScreen.selection => const SelectionScreen(),
      UstaadScreen.workflow => const WorkflowScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: screen,
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

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

  bool _creatingAccount = false;
  bool _remember = false;
  bool _obscure = true;
  int _failedLoginAttempts = 0;
  DateTime? _loginLockedUntil;
  Timer? _lockoutTimer;
  String? _emailError;
  String? _phoneError;

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
    _loginEmail.dispose();
    _loginPassword.dispose();
    _joinName.dispose();
    _joinEmail.dispose();
    _joinPhone.dispose();
    _joinPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
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
                        const Align(
                          alignment: Alignment.centerRight,
                          child: _AuthThemeButton(),
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.center,
                          child: _AuthBrandHeader(),
                        ),
                        const SizedBox(height: 20),
                        _AuthPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AuthTabs(
                                creatingAccount: _creatingAccount,
                                onLogin: () => setState(
                                  () => _creatingAccount = false,
                                ),
                                onJoin: () => setState(
                                  () => _creatingAccount = true,
                                ),
                              ),
                              const SizedBox(height: 22),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: _creatingAccount
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
    final busy = context.watch<UstaadState>().authBusy;
    final colors = _AuthPalette.of(context);
    final loginLocked = _loginLocked;
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthTextField(
          controller: _loginEmail,
          label: 'Enter Email Address',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 26),
        _AuthPasswordField(
          controller: _loginPassword,
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
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 18),
        _AuthButton(
          onPressed: busy || loginLocked ? null : _submitLogin,
          child: busy
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.fieldFill,
                  ),
                )
              : Text(loginLocked ? _loginCooldownLabel : 'Sign in'),
        ),
        if (loginLocked) ...[
          const SizedBox(height: 10),
          _SecurityInlineMessage(
            icon: Icons.lock_clock,
            text: 'Too many failed attempts. Sign in unlocks shortly.',
          ),
        ],
        const SizedBox(height: 14),
        _AuthRememberRow(
          value: _remember,
          onChanged: (value) => setState(() => _remember = value),
        ),
      ],
    );
  }

  Widget _joinForm() {
    final busy = context.watch<UstaadState>().authBusy;
    final colors = _AuthPalette.of(context);
    final strength = _passwordStrength(_joinPassword.text);
    return Column(
      key: const ValueKey('join'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthTextField(
          controller: _joinName,
          label: 'Enter Full Name',
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: 22),
        _AuthTextField(
          controller: _joinEmail,
          label: 'Enter Email Address',
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 22),
        _AuthTextField(
          controller: _joinPhone,
          label: 'Enter Phone Number',
          keyboardType: TextInputType.phone,
          errorText: _phoneError,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        const SizedBox(height: 22),
        _AuthPasswordField(
          controller: _joinPassword,
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        _PasswordStrengthMeter(strength: strength),
        const SizedBox(height: 18),
        _AuthButton(
          onPressed: busy ? null : _submitJoin,
          child: busy
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.fieldFill,
                  ),
                )
              : const Text('Create account'),
        ),
        const SizedBox(height: 14),
        _AuthRememberRow(
          value: _remember,
          onChanged: (value) => setState(() => _remember = value),
        ),
      ],
    );
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
    final strength = _passwordStrength(password);
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
    if (!mounted || ok) return;
    _show(context.read<UstaadState>().bannerMessage ?? 'Signup failed.');
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

class _AuthBrandHeader extends StatelessWidget {
  const _AuthBrandHeader();

  @override
  Widget build(BuildContext context) {
    final logoAsset = Theme.of(context).brightness == Brightness.light
        ? 'assets/branding/ustaad_logo_light.png'
        : 'assets/branding/ustaad_logo.png';
    return Semantics(
      label: 'USTAAD logo',
      image: true,
      child: Image.asset(
        logoAsset,
        width: 248,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(scale: value, child: animatedChild),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 380 ? 20 : 22,
          26,
          MediaQuery.sizeOf(context).width < 380 ? 20 : 22,
          18,
        ),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.accent.withValues(alpha: dark ? 0.24 : 0.34),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.42 : 0.10),
              blurRadius: dark ? 24 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}

class _AuthThemeButton extends StatelessWidget {
  const _AuthThemeButton();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final colors = _AuthPalette.of(context);
    return Tooltip(
      message: 'Switch theme',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.read<UstaadState>().toggleTheme(),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: state.isDark
                  ? colors.fieldFill
                  : colors.panel.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.isDark
                    ? colors.accent.withValues(alpha: 0.36)
                    : colors.warmAccent.withValues(alpha: 0.42),
              ),
            ),
            child: Icon(
              state.isDark ? Icons.dark_mode : Icons.wb_sunny_outlined,
              color: state.isDark ? colors.accent : colors.warmAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({
    required this.creatingAccount,
    required this.onLogin,
    required this.onJoin,
  });

  final bool creatingAccount;
  final VoidCallback onLogin;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AuthTabButton(
                label: 'Sign in',
                selected: !creatingAccount,
                onTap: onLogin,
              ),
            ),
            Expanded(
              child: _AuthTabButton(
                label: 'Create',
                selected: creatingAccount,
                onTap: onJoin,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(height: 1, color: colors.border),
            AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: creatingAccount
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(height: 2, color: colors.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 160),
          style: TextStyle(
            color: selected ? colors.accent : colors.muted,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? errorText;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthFieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          cursorColor: colors.accent,
          style: TextStyle(
            color: colors.text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          decoration: _authInputDecoration(
            context,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

class _AuthPasswordField extends StatelessWidget {
  const _AuthPasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AuthFieldLabel('Enter Password'),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscure,
          autofillHints: const [AutofillHints.password],
          cursorColor: colors.accent,
          style: TextStyle(
            color: colors.text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          decoration: _authInputDecoration(
            context,
            suffixIcon: IconButton(
              tooltip: obscure ? 'Show password' : 'Hide password',
              onPressed: onToggle,
              icon: Icon(
                obscure ? Icons.visibility : Icons.visibility_off,
                color: colors.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStrength {
  const _PasswordStrength({
    required this.score,
    required this.label,
    required this.acceptable,
  });

  final int score;
  final String label;
  final bool acceptable;
}

_PasswordStrength _passwordStrength(String password) {
  var score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[a-z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

  final label = switch (score) {
    0 || 1 => 'Weak',
    2 || 3 => 'Better',
    4 => 'Strong',
    _ => 'Excellent',
  };

  return _PasswordStrength(
    score: score,
    label: label,
    acceptable: score >= 5,
  );
}

class _PasswordStrengthMeter extends StatelessWidget {
  const _PasswordStrengthMeter({required this.strength});

  final _PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    final value = (strength.score / 5).clamp(0.0, 1.0);
    final color = strength.acceptable ? colors.accent : colors.warmAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            color: color,
            backgroundColor: colors.border,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Password ${strength.label.toLowerCase()} - use upper, lower, number, and symbol.',
          style: TextStyle(
            color: colors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SecurityInlineMessage extends StatelessWidget {
  const _SecurityInlineMessage({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.warmAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthFieldLabel extends StatelessWidget {
  const _AuthFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    return Text(
      label,
      style: TextStyle(
        color: colors.text,
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

InputDecoration _authInputDecoration(
  BuildContext context, {
  String? errorText,
  Widget? suffixIcon,
}) {
  final colors = _AuthPalette.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(7),
    borderSide: BorderSide(color: colors.border),
  );

  return InputDecoration(
    filled: true,
    fillColor: colors.fieldFill,
    errorText: errorText,
    errorStyle: TextStyle(color: colors.error, fontWeight: FontWeight.w700),
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: colors.accent, width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: colors.error, width: 1.2),
    ),
  );
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor: colors.accent.withValues(alpha: 0.55),
          disabledForegroundColor:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _AuthRememberRow extends StatelessWidget {
  const _AuthRememberRow({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = _AuthPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Keep me logged in',
            style: TextStyle(
              color: colors.muted.withValues(alpha: 0.82),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: colors.accent.withValues(alpha: 0.92),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: colors.border,
          trackOutlineColor: WidgetStateProperty.resolveWith(
            (_) => Colors.transparent,
          ),
        ),
      ],
    );
  }
}

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  final _location = TextEditingController(text: 'G-13, Islamabad');
  final _problem = TextEditingController();
  StreamSubscription<Position>? _locationSubscription;
  bool _locating = false;
  bool _trackingLocation = false;
  String? _locationStatus;
  String _providerQuery = '';
  String _serviceFilter = 'All';
  String _sortMode = 'Best match';

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _location.dispose();
    _problem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final user = state.user;
    final wide = MediaQuery.sizeOf(context).width >= 820;

    return _Stage(
      wideMaxWidth: 1080,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: user == null ? 'Book' : 'Hi ${user.firstName}',
            subtitle: state.backendOnline ? 'Connected' : 'Offline ready',
            showNav: true,
          ),
          const SizedBox(height: 12),
          _HomeDashboard(
            bookings: state.bookings,
            savedCount: state.savedProviderIds.length,
            recentRequests: state.recentRequests,
            onUseRecent: (request) {
              _problem.text = request;
              _analyze();
            },
          ),
          const SizedBox(height: 12),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _requestPanel()),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _quickServices()),
              ],
            )
          else ...[
            _requestPanel(),
            const SizedBox(height: 12),
            _quickServices(),
          ],
          const SizedBox(height: 12),
          _providerDirectory(state),
        ],
      ),
    );
  }

  Widget _requestPanel() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _location,
            decoration: InputDecoration(
              labelText: 'Location',
              prefixIcon: const Icon(Icons.place),
              suffixIcon: IconButton(
                tooltip: _trackingLocation
                    ? 'Stop location tracking'
                    : 'Track current location',
                icon: _locating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _trackingLocation
                            ? Icons.location_searching
                            : Icons.my_location,
                      ),
                onPressed: _locating ? null : _toggleLocationTracking,
              ),
            ),
          ),
          if (_locationStatus != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _trackingLocation
                      ? Icons.location_searching
                      : Icons.location_on_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _locationStatus!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _problem,
            minLines: 5,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Request',
              hintText: 'Describe what you need',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExampleChip(
                label: 'AC',
                onTap: () {
                  _problem.text =
                      'Mujhe kal subah G-13 mein AC technician chahiye';
                },
              ),
              _ExampleChip(
                label: 'Leak',
                onTap: () => _problem.text = 'Urgent pani leak in kitchen',
              ),
              _ExampleChip(
                label: 'Urdu',
                onTap: () => _problem.text =
                    '\u0627\u06d2 \u0633\u06cc \u0679\u06be\u0646\u0688\u0627 \u0646\u06c1\u06cc\u06ba \u06c1\u0648 \u0631\u06c1\u0627',
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.search),
            label: const Text('Find providers'),
          ),
        ],
      ),
    );
  }

  Widget _quickServices() {
    final services = [
      (Icons.ac_unit, 'AC Repair'),
      (Icons.water_drop, 'Plumber'),
      (Icons.electrical_services, 'Electrician'),
      (Icons.cleaning_services, 'Cleaning'),
      (Icons.school, 'Tutor'),
      (Icons.face_retouching_natural, 'Beautician'),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick book',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((service) {
              return ActionChip(
                avatar: Icon(service.$1, size: 18),
                label: Text(service.$2),
                onPressed: () {
                  _problem.text = 'I need a ${service.$2} expert';
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _providerDirectory(UstaadState state) {
    final roles = [
      'All',
      ...{for (final provider in state.providers) provider.role},
    ];
    final query = _providerQuery.trim().toLowerCase();
    var visible = state.providers.where((provider) {
      final matchesRole =
          _serviceFilter == 'All' || provider.role == _serviceFilter;
      final searchText =
          '${provider.name} ${provider.role} ${provider.city}'.toLowerCase();
      return matchesRole && (query.isEmpty || searchText.contains(query));
    }).toList();

    visible.sort((a, b) {
      return switch (_sortMode) {
        'Nearest' => a.distanceKm.compareTo(b.distanceKm),
        'Price' => a.price.compareTo(b.price),
        'Rating' => b.rating.compareTo(a.rating),
        _ => b.reliability.compareTo(a.reliability),
      };
    });

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Provider directory',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Sort providers',
                initialValue: _sortMode,
                onSelected: (value) => setState(() => _sortMode = value),
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                        value: 'Best match', child: Text('Best match')),
                    PopupMenuItem(value: 'Nearest', child: Text('Nearest')),
                    PopupMenuItem(value: 'Rating', child: Text('Rating')),
                    PopupMenuItem(value: 'Price', child: Text('Price')),
                  ];
                },
                icon: const Icon(Icons.sort),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search providers',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _providerQuery = value),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: roles.map((role) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _serviceFilter == role,
                    label: Text(role),
                    onSelected: (_) => setState(() => _serviceFilter = role),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const _InlineEmpty(
              icon: Icons.search_off,
              text: 'No providers match this search.',
            )
          else
            ...visible.take(5).map((provider) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProviderListTile(provider: provider),
              );
            }),
        ],
      ),
    );
  }

  void _analyze() {
    final problem = _problem.text.trim();
    if (problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the service first.')),
      );
      return;
    }
    context.read<UstaadState>().startAnalysis(problem, _location.text);
  }

  Future<void> _toggleLocationTracking() async {
    if (_trackingLocation) {
      await _stopLocationTracking();
      return;
    }

    await _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    setState(() {
      _locating = true;
      _locationStatus = 'Checking location permission...';
    });

    final ready = await _ensureLocationReady();
    if (!mounted) return;
    if (!ready) {
      setState(() => _locating = false);
      return;
    }

    const currentSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: Duration(seconds: 20),
    );
    const streamSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: currentSettings,
      );
      _applyPosition(position, tracking: false);

      await _locationSubscription?.cancel();
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: streamSettings,
      ).listen(
        (position) => _applyPosition(position, tracking: true),
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _trackingLocation = false;
            _locationStatus = _locationErrorMessage(error);
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _locating = false;
        _trackingLocation = true;
        _locationStatus = 'Tracking live location. Accuracy: '
            '${position.accuracy.toStringAsFixed(0)} m.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _trackingLocation = false;
        _locationStatus = _locationErrorMessage(error);
      });
    }
  }

  Future<void> _stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    if (!mounted) return;
    setState(() {
      _trackingLocation = false;
      _locationStatus = 'Location tracking stopped.';
    });
  }

  Future<bool> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Turn on location services to use tracking.';
        });
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Location permission was denied.';
        });
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationStatus =
              'Location permission is blocked. Enable it in settings.';
        });
      }
      return false;
    }

    return true;
  }

  void _applyPosition(Position position, {required bool tracking}) {
    if (!mounted) return;
    final label = _formatPosition(position);
    setState(() {
      _location.text = label;
      _locationStatus = tracking
          ? 'Live location updated. Accuracy: '
              '${position.accuracy.toStringAsFixed(0)} m.'
          : 'Current location found. Accuracy: '
              '${position.accuracy.toStringAsFixed(0)} m.';
    });
  }

  String _formatPosition(Position position) {
    final lat = position.latitude.toStringAsFixed(5);
    final lng = position.longitude.toStringAsFixed(5);
    return 'Current location: $lat, $lng';
  }

  String _locationErrorMessage(Object error) {
    if (error is TimeoutException) {
      return 'Location timed out. Try again near a window or outdoors.';
    }
    if (error is PermissionDeniedException) {
      return 'Location permission was denied.';
    }
    if (error is LocationServiceDisabledException) {
      return 'Turn on location services to use tracking.';
    }
    return 'Could not read location. Check permission and try again.';
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.bookings,
    required this.savedCount,
    required this.recentRequests,
    required this.onUseRecent,
  });

  final List<BookingRecord> bookings;
  final int savedCount;
  final List<String> recentRequests;
  final ValueChanged<String> onUseRecent;

  @override
  Widget build(BuildContext context) {
    final active = bookings
        .where((booking) =>
            booking.status != 'completed' && booking.status != 'cancelled')
        .length;
    final completed =
        bookings.where((booking) => booking.status == 'completed').length;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.timeline,
                  label: 'Active',
                  value: '$active',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.bookmark,
                  label: 'Saved',
                  value: '$savedCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.verified,
                  label: 'Done',
                  value: '$completed',
                ),
              ),
            ],
          ),
          if (recentRequests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentRequests.take(4).map((request) {
                return ActionChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: Text(
                    request,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => onUseRecent(request),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderListTile extends StatelessWidget {
  const _ProviderListTile({required this.provider});

  final UstaadProviderProfile provider;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final saved = state.isSavedProvider(provider.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _Avatar(url: provider.avatarUrl, size: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${provider.role} - ${provider.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${provider.rating} stars - ${provider.distanceKm} km - Rs. ${provider.price}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: saved ? 'Unsave provider' : 'Save provider',
            onPressed: () =>
                context.read<UstaadState>().toggleSavedProvider(provider.id),
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
          ),
          IconButton.filledTonal(
            tooltip: 'View match',
            onPressed: () =>
                context.read<UstaadState>().previewProvider(provider),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final intent = state.intent!;
    final quote = state.quote!;

    return _Stage(
      wideMaxWidth: 1080,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: 'Matches',
            subtitle: intent.location,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            showNav: true,
          ),
          const SizedBox(height: 16),
          _IntentSummary(intent: intent),
          const SizedBox(height: 12),
          _QuotePanel(quote: quote),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: state.rankedProviders.take(4).map((provider) {
                  return SizedBox(
                    width: wide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth,
                    child: _ProviderCard(
                      provider: provider,
                      best: provider == state.rankedProviders.first,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          _TracePanel(events: state.workflowEvents),
        ],
      ),
    );
  }
}

class WorkflowScreen extends StatelessWidget {
  const WorkflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final provider = state.selectedProvider!;
    final booking = state.latestBooking;
    final eta = booking?.etaMinutes ?? etaMinutesFor(provider);
    final saving = state.bookingBusy;

    return _Stage(
      wideMaxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: saving ? 'Confirming' : 'Confirmed',
            subtitle: 'ETA: $eta minutes',
            leading: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            showNav: true,
          ),
          const SizedBox(height: 18),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      saving ? Icons.sync : Icons.check,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    provider.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('${provider.role} - ${provider.rating} rating'),
                ),
                const SizedBox(height: 14),
                _ContactBar(
                  phone: booking?.providerPhone ?? provider.phone,
                  whatsapp: booking?.providerWhatsapp ?? provider.whatsapp,
                ),
                const SizedBox(height: 12),
                _StatusTile(
                  icon: Icons.calendar_month,
                  title: booking?.slotLabel ?? provider.nextSlot,
                  subtitle: booking?.confirmationMessage ??
                      'Confirmed for the selected slot.',
                ),
                const SizedBox(height: 10),
                _StatusTile(
                  icon: Icons.notifications_active,
                  title: 'Smart follow-up',
                  subtitle: 'Reminder and review prompt are ready.',
                ),
                if (state.bannerMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.bannerMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _TracePanel(
                  events: state.workflowEvents,
                  initiallyExpanded: false,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: booking == null
                            ? null
                            : () => _showReviewDialog(
                                  context,
                                  providerId: booking.providerId,
                                  providerName: booking.providerName,
                                  bookingId: booking.id,
                                ),
                        icon: const Icon(Icons.star),
                        label: const Text('Review'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.read<UstaadState>().openBookings(),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Bookings'),
                      ),
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
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _filter = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final filtered = state.bookings.where((booking) {
      final matchesFilter = switch (_filter) {
        'Active' =>
          booking.status != 'completed' && booking.status != 'cancelled',
        'Completed' => booking.status == 'completed',
        'Issues' => booking.status == 'issue_reported',
        _ => true,
      };
      final text =
          '${booking.providerName} ${booking.serviceRole} ${booking.problemText}'
              .toLowerCase();
      return matchesFilter && text.contains(_query.trim().toLowerCase());
    }).toList();

    return _Stage(
      wideMaxWidth: 960,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: 'Bookings',
            subtitle: 'Status',
            leading: IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            showNav: true,
          ),
          const SizedBox(height: 16),
          if (state.bookings.isNotEmpty) ...[
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search bookings',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Active', 'Completed', 'Issues'].map((label) {
                return ChoiceChip(
                  selected: _filter == label,
                  label: Text(label),
                  onSelected: (_) => setState(() => _filter = label),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (state.bookings.isEmpty)
            _EmptyState(
              icon: Icons.receipt_long,
              title: 'No bookings yet',
              actionLabel: 'Book a service',
              onAction: () => context.read<UstaadState>().openHome(),
            )
          else if (filtered.isEmpty)
            const _InlineEmpty(
              icon: Icons.search_off,
              text: 'No bookings match this filter.',
            )
          else
            ...filtered.map((booking) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BookingCard(booking: booking),
              );
            }),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _bio = TextEditingController();
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    final user = context.read<UstaadState>().user;
    if (user != null) {
      _name.text = user.name;
      _phone.text = user.phone ?? '';
      _city.text = user.city;
      _address.text = user.address;
      _bio.text = user.bio;
      _language = user.preferredLanguage;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final user = state.user;
    if (user == null) {
      return const GatewayScreen();
    }

    return _Stage(
      wideMaxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: 'Profile',
            subtitle: user.email,
            leading: IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            showNav: true,
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      _Avatar(url: user.avatarUrl, size: 96),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          tooltip: 'Change photo',
                          onPressed: state.profileBusy ? null : _pickPhoto,
                          icon: state.profileBusy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.camera_alt),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SecurityPanel(
                  email: user.email,
                  sessionExpiresAt: state.sessionExpiresAt,
                  rememberedEmail: state.savedEmail.isNotEmpty,
                ),
                const SizedBox(height: 18),
                _SavedProvidersPanel(providers: state.savedProviders),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _city,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _language,
                        decoration: const InputDecoration(
                          labelText: 'Language',
                          prefixIcon: Icon(Icons.translate),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'English',
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: 'Urdu',
                            child: Text('Urdu'),
                          ),
                          DropdownMenuItem(
                            value: 'Roman Urdu',
                            child: Text('Roman Urdu'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _language = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bio,
                  minLines: 3,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: state.profileBusy ? null : _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save profile'),
                ),
                if (state.bannerMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    state.bannerMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final appState = context.read<UstaadState>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 84,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    final ok = await appState.uploadProfilePhoto(
      bytes: bytes,
      fileName: picked.name,
      contentType: picked.mimeType ?? _contentTypeFor(picked.name),
    );
    if (!mounted) return;
    _show(appState.bannerMessage ??
        (ok ? 'Profile photo updated.' : 'Photo upload failed.'));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _show('Enter your name.');
      return;
    }
    final ok = await context.read<UstaadState>().saveProfile(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          city: _city.text.trim().isEmpty ? 'Islamabad' : _city.text.trim(),
          address: _address.text.trim(),
          preferredLanguage: _language,
          bio: _bio.text.trim(),
        );
    if (!mounted) return;
    _show(context.read<UstaadState>().bannerMessage ??
        (ok ? 'Profile updated.' : 'Profile could not be saved.'));
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.child,
    this.wideMaxWidth = 520,
  });

  final Widget child;
  final double wideMaxWidth;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 640;
    final horizontal = width >= 760 ? 28.0 : 14.0;
    final shellScreen = state.screen == UstaadScreen.commandCenter ||
        state.screen == UstaadScreen.bookings ||
        state.screen == UstaadScreen.profile;
    final showBottomNav = compact && state.isSignedIn && shellScreen;

    return Scaffold(
      bottomNavigationBar: showBottomNav ? const _BottomNav() : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wideMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                compact ? 12 : 18,
                horizontal,
                showBottomNav ? 18 : (compact ? 12 : 18),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel({
    required this.email,
    required this.sessionExpiresAt,
    required this.rememberedEmail,
  });

  final String email;
  final DateTime? sessionExpiresAt;
  final bool rememberedEmail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: scheme.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Security',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Chip(
                avatar: const Icon(Icons.verified_user, size: 16),
                label: const Text('Protected'),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: scheme.primary.withValues(alpha: 0.42)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SecurityStatusRow(
            icon: Icons.alternate_email,
            label: 'Account',
            value: email,
          ),
          _SecurityStatusRow(
            icon: Icons.timer,
            label: 'Session',
            value: sessionExpiresAt == null
                ? 'Managed by Supabase'
                : 'Refreshes until ${_shortDateTime(sessionExpiresAt!)}',
          ),
          _SecurityStatusRow(
            icon: rememberedEmail ? Icons.mark_email_read : Icons.privacy_tip,
            label: 'Remember email',
            value: rememberedEmail ? 'Enabled on this device' : 'Off',
          ),
        ],
      ),
    );
  }
}

class _SavedProvidersPanel extends StatelessWidget {
  const _SavedProvidersPanel({required this.providers});

  final List<UstaadProviderProfile> providers;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const _InlineEmpty(
        icon: Icons.bookmark_border,
        text: 'Saved providers will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Saved providers',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        ...providers.take(3).map((provider) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ProviderListTile(provider: provider),
          );
        }),
      ],
    );
  }
}

class _SecurityStatusRow extends StatelessWidget {
  const _SecurityStatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day} $hour:$minute';
}

class _AppBarLine extends StatelessWidget {
  const _AppBarLine({
    required this.title,
    required this.subtitle,
    this.leading,
    this.showNav = false,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final bool showNav;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              if (subtitle.isNotEmpty && !compact)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (showNav && state.isSignedIn && !compact) ...[
          IconButton(
            tooltip: 'Bookings',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.read<UstaadState>().openBookings(),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.read<UstaadState>().openProfile(),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<UstaadState>().signOut(),
          ),
        ],
        if (showNav && state.isSignedIn && compact)
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<UstaadState>().signOut(),
          ),
        const _ThemeButton(),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final selectedIndex = switch (state.screen) {
      UstaadScreen.bookings => 1,
      UstaadScreen.profile => 2,
      _ => 0,
    };

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        final state = context.read<UstaadState>();
        if (index == 0) {
          state.openHome();
        } else if (index == 1) {
          state.openBookings();
        } else {
          state.openProfile();
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    return IconButton(
      tooltip: 'Switch theme',
      onPressed: () => context.read<UstaadState>().toggleTheme(),
      icon: Icon(state.isDark ? Icons.dark_mode : Icons.wb_sunny_outlined),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: animatedChild,
          ),
        );
      },
      child: Container(
        padding:
            EdgeInsets.all(MediaQuery.sizeOf(context).width < 640 ? 14 : 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _QuotePanel extends StatelessWidget {
  const _QuotePanel({required this.quote});

  final QuoteEstimate quote;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Expanded(child: _QuoteText(label: 'Base', value: quote.basePrice)),
          Expanded(
            child: _QuoteText(label: 'Distance', value: quote.distancePrice),
          ),
          Expanded(
            child: _QuoteText(
              label: 'Total',
              value: quote.total,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteText extends StatelessWidget {
  const _QuoteText({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Text(
          'Rs. $value',
          style: TextStyle(
            color: highlight ? Theme.of(context).colorScheme.primary : null,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.bolt, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _IntentSummary extends StatelessWidget {
  const _IntentSummary({required this.intent});

  final ServiceIntent intent;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Type', intent.role),
      ('Time', intent.timeLabel),
      ('Lang', intent.language),
      ('Match', '${(intent.confidence * 100).round()}%'),
    ];

    return _Panel(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          return Chip(
            label: Text('${item.$1}: ${item.$2}'),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }
}

class _TracePanel extends StatelessWidget {
  const _TracePanel({
    required this.events,
    this.initiallyExpanded = false,
  });

  final List<WorkflowEvent> events;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return _Panel(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: initiallyExpanded,
        title: const Text(
          'Trace',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        children: events.map((event) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(event.step),
            subtitle: Text(
              event.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

class _ProviderCard extends StatefulWidget {
  const _ProviderCard({
    required this.provider,
    required this.best,
  });

  final UstaadProviderProfile provider;
  final bool best;

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UstaadState>().loadReviews(widget.provider.id);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ProviderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.id != widget.provider.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<UstaadState>().loadReviews(widget.provider.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final state = context.watch<UstaadState>();
    final saved = state.isSavedProvider(provider.id);
    final score = (provider.score.clamp(0, 100)).toDouble() / 100;
    final reviews = state.providerReviews[provider.id] ?? const [];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.best) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Best match'),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              _Avatar(url: provider.avatarUrl, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text('${provider.role} • ${provider.distanceKm} km'),
                    Text('${provider.rating} ★ • Rs. ${provider.price}'),
                  ],
                ),
              ),
              IconButton(
                tooltip: saved ? 'Unsave provider' : 'Save provider',
                onPressed: () => context
                    .read<UstaadState>()
                    .toggleSavedProvider(provider.id),
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StatusTile(
            icon: Icons.event_available,
            title: provider.nextSlot,
            subtitle: '${provider.responseTimeMinutes} min response',
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: score,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetricChip(
                icon: Icons.timer,
                label: '${provider.jobsCompleted} jobs',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: provider.verified ? Icons.verified : Icons.info,
                label: provider.verified ? 'Verified' : 'New',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ContactBar(phone: provider.phone, whatsapp: provider.whatsapp),
          const SizedBox(height: 10),
          _ReviewsPreview(providerId: provider.id, reviews: reviews),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.read<UstaadState>().bookProvider(provider),
            icon: const Icon(Icons.calendar_month),
            label: const Text('Book slot'),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final BookingRecord booking;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(url: booking.providerAvatarUrl, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text('${booking.serviceRole} - Rs. ${booking.quoteTotal}'),
                  ],
                ),
              ),
              _StatusChip(label: booking.statusLabel, status: booking.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.problemText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          _StatusTile(
            icon: Icons.calendar_month,
            title: booking.slotLabel,
            subtitle: booking.location,
          ),
          const SizedBox(height: 10),
          _ContactBar(
            phone: booking.providerPhone,
            whatsapp: booking.providerWhatsapp,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: booking.status == 'completed'
                    ? null
                    : () => context
                        .read<UstaadState>()
                        .updateBookingStatus(booking, 'completed'),
                icon: const Icon(Icons.check_circle),
                label: const Text('Complete'),
              ),
              OutlinedButton.icon(
                onPressed: booking.status == 'cancelled'
                    ? null
                    : () => context
                        .read<UstaadState>()
                        .updateBookingStatus(booking, 'cancelled'),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
              ),
              OutlinedButton.icon(
                onPressed: booking.status == 'issue_reported'
                    ? null
                    : () => _showIssueDialog(context, booking),
                icon: const Icon(Icons.report_problem),
                label: const Text('Issue'),
              ),
              OutlinedButton.icon(
                onPressed: () => _rebook(context, booking),
                icon: const Icon(Icons.replay),
                label: const Text('Rebook'),
              ),
              FilledButton.icon(
                onPressed: () => _showReviewDialog(
                  context,
                  providerId: booking.providerId,
                  providerName: booking.providerName,
                  bookingId: booking.id,
                ),
                icon: const Icon(Icons.star),
                label: const Text('Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _rebook(BuildContext context, BookingRecord booking) {
    final state = context.read<UstaadState>();
    final provider = state.providers.firstWhere(
      (item) => item.id == booking.providerId,
      orElse: () => UstaadProviderProfile(
        id: booking.providerId,
        name: booking.providerName,
        role: booking.serviceRole,
        reliability: 0.86,
        distanceKm: 5,
        rating: booking.providerRating == 0 ? 4.6 : booking.providerRating,
        price: booking.quoteTotal,
        avatarUrl: booking.providerAvatarUrl,
        verified: true,
        city: booking.location,
        phone: booking.providerPhone,
        whatsapp: booking.providerWhatsapp,
        availabilitySlots: [booking.slotLabel],
      ),
    );
    state.previewProvider(provider);
  }
}

class _ReviewsPreview extends StatelessWidget {
  const _ReviewsPreview({
    required this.providerId,
    required this.reviews,
  });

  final String providerId;
  final List<ReviewRecord> reviews;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(
        reviews.isEmpty ? 'Reviews' : 'Reviews (${reviews.length})',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: reviews.isEmpty
          ? const Text('No reviews yet')
          : Text(_stars(_averageRating(reviews))),
      children: [
        if (reviews.isEmpty)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.rate_review),
            title: Text('Be the first to review'),
          )
        else
          ...reviews.take(3).map((review) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _Avatar(url: review.customerAvatarUrl, size: 36),
              title: Text(
                  '${_stars(review.rating.toDouble())}  ${review.customerName}'),
              subtitle: Text(review.comment),
            );
          }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _showReviewDialog(
              context,
              providerId: providerId,
              providerName: 'provider',
            ),
            icon: const Icon(Icons.add_comment),
            label: const Text('Add review'),
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  const _ContactBar({
    required this.phone,
    required this.whatsapp,
  });

  final String phone;
  final String whatsapp;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ContactChip(
          icon: Icons.phone,
          label: phone.isEmpty ? 'Phone pending' : phone,
          value: phone,
        ),
        _ContactChip(
          icon: Icons.chat,
          label: whatsapp.isEmpty ? 'WhatsApp pending' : whatsapp,
          value: whatsapp,
        ),
      ],
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: value.isEmpty
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact copied.')),
                );
              }
            },
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      'completed' => Colors.green,
      'cancelled' => Colors.redAccent,
      'issue_reported' => Colors.amber,
      'en_route' => scheme.primary,
      _ => scheme.secondary,
    };
    return Chip(
      label: Text(label),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          Icon(icon, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _AvatarFallback(size: size);
    }
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _AvatarFallback(size: size);
        },
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person),
    );
  }
}

Future<void> _showIssueDialog(
  BuildContext context,
  BookingRecord booking,
) async {
  final note = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Report ${booking.providerName}'),
        content: TextField(
          controller: note,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Issue details',
            hintText: 'Late arrival, pricing concern, or service problem',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, note.text),
            child: const Text('Submit'),
          ),
        ],
      );
    },
  );
  note.dispose();
  if (result == null || !context.mounted) return;
  final state = context.read<UstaadState>();
  final ok = await state.reportBookingIssue(booking, result);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        state.bannerMessage ??
            (ok ? 'Issue reported.' : 'Issue could not be reported.'),
      ),
    ),
  );
}

Future<void> _showReviewDialog(
  BuildContext context, {
  required String providerId,
  required String providerName,
  String? bookingId,
}) async {
  final comment = TextEditingController();
  var rating = 5;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final busy = context.watch<UstaadState>().reviewBusy;
          return AlertDialog(
            title: Text('Review $providerName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 6,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return ChoiceChip(
                      selected: rating == value,
                      label: Text('$value'),
                      avatar: const Icon(Icons.star, size: 16),
                      onSelected: (_) => setState(() => rating = value),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: comment,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Review',
                    hintText: 'Share your experience',
                  ),
                ),
                if (busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final ok =
                            await context.read<UstaadState>().submitReview(
                                  providerId: providerId,
                                  rating: rating,
                                  comment: comment.text,
                                  bookingId: bookingId,
                                );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, ok);
                        }
                      },
                child: const Text('Post'),
              ),
            ],
          );
        },
      );
    },
  );
  comment.dispose();
  if (context.mounted && result == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review posted.')),
    );
  }
}

String _stars(double rating) {
  final rounded = rating.round().clamp(1, 5);
  return '${'★' * rounded}${'☆' * (5 - rounded)}';
}

double _averageRating(List<ReviewRecord> reviews) {
  if (reviews.isEmpty) return 0;
  final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
  return total / reviews.length;
}

String _contentTypeFor(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
