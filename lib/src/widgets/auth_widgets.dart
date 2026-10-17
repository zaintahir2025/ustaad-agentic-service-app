import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../ustaad_state.dart';

class AuthPalette {
  const AuthPalette({
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

  static AuthPalette of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AuthPalette(
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

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

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

class AuthPanel extends StatelessWidget {
  const AuthPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
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

class AuthThemeButton extends StatelessWidget {
  const AuthThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final colors = AuthPalette.of(context);
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

class AuthTabs extends StatelessWidget {
  const AuthTabs({
    super.key,
    required this.creatingAccount,
    required this.onLogin,
    required this.onJoin,
  });

  final bool creatingAccount;
  final VoidCallback onLogin;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AuthTabButton(
                label: AppLocalizations.of(context)?.signIn ?? 'Sign in',
                selected: !creatingAccount,
                onTap: onLogin,
              ),
            ),
            Expanded(
              child: AuthTabButton(
                label: AppLocalizations.of(context)?.createAccount ?? 'Create',
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

class AuthTabButton extends StatelessWidget {
  const AuthTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
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

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
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
    final colors = AuthPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFieldLabel(label),
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
          decoration: authInputDecoration(
            context,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.label = 'Enter Password',
    this.onChanged,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFieldLabel(label),
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
          decoration: authInputDecoration(
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

class PasswordStrength {
  const PasswordStrength({
    required this.score,
    required this.label,
    required this.acceptable,
  });

  final int score;
  final String label;
  final bool acceptable;
}

PasswordStrength calculatePasswordStrength(String password) {
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

  return PasswordStrength(
    score: score,
    label: label,
    acceptable: score >= 5,
  );
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
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

class SecurityInlineMessage extends StatelessWidget {
  const SecurityInlineMessage({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
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

class EmailConfirmationNotice extends StatelessWidget {
  const EmailConfirmationNotice({
    super.key,
    required this.email,
    required this.onResend,
    this.cooldownSeconds = 0,
  });

  final String email;
  final VoidCallback? onResend;
  final int cooldownSeconds;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.mark_email_unread_outlined,
                  size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirm your email',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cooldownSeconds > 0
                ? 'Email verification is cooling down. Try resend again in ${cooldownSeconds}s.'
                : 'We sent a confirmation link to $email. Open it, then sign in.',
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onResend,
              style: TextButton.styleFrom(
                foregroundColor: colors.accent,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Text(
                cooldownSeconds > 0
                    ? 'Resend available soon'
                    : 'Resend confirmation',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuestAccessButton extends StatelessWidget {
  const GuestAccessButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.person_outline, size: 18),
      label: Text(
        AppLocalizations.of(context)?.continueAsGuest ?? 'Continue as guest',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.accent,
        side: BorderSide(color: colors.accent.withValues(alpha: 0.55)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
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

InputDecoration authInputDecoration(
  BuildContext context, {
  String? errorText,
  Widget? suffixIcon,
}) {
  final colors = AuthPalette.of(context);
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

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
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

class AuthRememberRow extends StatelessWidget {
  const AuthRememberRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AuthPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context)?.keepMeLoggedIn ??
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
