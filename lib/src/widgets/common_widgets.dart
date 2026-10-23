import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../currency.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../ustaad_state.dart';

class Stage extends StatelessWidget {
  const Stage({
    super.key,
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
      bottomNavigationBar: showBottomNav ? const BottomNav() : null,
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

class AppBarLine extends StatelessWidget {
  const AppBarLine({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.actions,
    this.showNav = false,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showNav;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final l10n = AppLocalizations.of(context);
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
        if (actions != null) ...actions!,
        if (showNav && state.isSignedIn && !compact) ...[
          IconButton(
            tooltip: l10n?.bookings ?? 'Bookings',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.read<UstaadState>().openBookings(),
          ),
          IconButton(
            tooltip: l10n?.profile ?? 'Profile',
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.read<UstaadState>().openProfile(),
          ),
          IconButton(
            tooltip: l10n?.signOut ?? 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<UstaadState>().signOut(),
          ),
        ],
        if (showNav && state.isSignedIn && compact)
          IconButton(
            tooltip: l10n?.signOut ?? 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<UstaadState>().signOut(),
          ),
        const LanguageButton(),
        const ThemeButton(),
      ],
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final selectedIndex = switch (state.screen) {
      UstaadScreen.bookings => 1,
      UstaadScreen.profile => 2,
      _ => 0,
    };

    final l10n = AppLocalizations.of(context);
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
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n?.home ?? 'Home',
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l10n?.bookings ?? 'Bookings',
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n?.profile ?? 'Profile',
        ),
      ],
    );
  }
}

class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

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

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final current = state.selectedLanguage;

    return PopupMenuButton<String>(
      tooltip: 'Change language',
      icon: const Icon(Icons.translate),
      initialValue: current,
      onSelected: (lang) => context.read<UstaadState>().setLanguage(lang),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'English',
          child: Text('English'),
        ),
        PopupMenuItem(
          value: 'Urdu',
          child: Text('اردو (Urdu)'),
        ),
        PopupMenuItem(
          value: 'Roman Urdu',
          child: Text('Roman Urdu'),
        ),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});

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
      child: Material(
        color: Theme.of(context).cardColor,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
          ),
        ),
        child: Padding(
          padding:
              EdgeInsets.all(MediaQuery.sizeOf(context).width < 640 ? 16 : 20),
          child: child,
        ),
      ),
    );
  }
}

class QuotePanel extends StatelessWidget {
  const QuotePanel({super.key, required this.quote});

  final QuoteEstimate quote;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (quote.userOffer != null)
                Expanded(
                  child: QuoteText(
                    label: 'Your Offer',
                    value: quote.userOffer!,
                  ),
                ),
              Expanded(child: QuoteText(label: 'Base Rate', value: quote.basePrice)),
              Expanded(
                child: QuoteText(label: 'Distance', value: quote.distancePrice),
              ),
              Expanded(
                child: QuoteText(
                  label: 'Total',
                  value: quote.total,
                  highlight: true,
                ),
              ),
            ],
          ),
          if (quote.userOffer != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: quote.isWithinOffer
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    quote.isWithinOffer
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 16,
                    color: quote.isWithinOffer
                        ? Colors.green
                        : Colors.amber.shade800,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quote.isWithinOffer
                          ? (quote.differenceWithOffer < 0
                              ? 'Provider base rate is ${formatPkr(-quote.differenceWithOffer)} under your offer!'
                              : 'Provider base rate matches your offer!')
                          : 'Provider rate is ${formatPkr(quote.differenceWithOffer)} above your offer.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: quote.isWithinOffer
                            ? Colors.green.shade700
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QuoteText extends StatelessWidget {
  const QuoteText({
    super.key,
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
          formatPkr(value),
          style: TextStyle(
            color: highlight ? Theme.of(context).colorScheme.primary : null,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class ExampleChip extends StatelessWidget {
  const ExampleChip({
    super.key,
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

class IntentSummary extends StatelessWidget {
  const IntentSummary({super.key, required this.intent});

  final ServiceIntent intent;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Type', intent.role),
      ('Time', intent.timeLabel),
      ('Lang', intent.language),
      ('Match', '${(intent.confidence * 100).round()}%'),
    ];

    return Panel(
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

class TracePanel extends StatelessWidget {
  const TracePanel({
    super.key,
    required this.events,
    this.initiallyExpanded = false,
  });

  final List<WorkflowEvent> events;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Panel(
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

class MetricChip extends StatelessWidget {
  const MetricChip({
    super.key,
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
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

enum ContactType { phone, whatsapp }

class ContactBar extends StatelessWidget {
  const ContactBar({
    super.key,
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
        ContactChip(
          icon: Icons.phone,
          label: phone.isEmpty ? 'Phone pending' : phone,
          value: phone,
          type: ContactType.phone,
        ),
        ContactChip(
          icon: Icons.chat,
          label: whatsapp.isEmpty ? 'WhatsApp pending' : whatsapp,
          value: whatsapp,
          type: ContactType.whatsapp,
        ),
      ],
    );
  }
}

class ContactChip extends StatelessWidget {
  const ContactChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.type,
  });

  final IconData icon;
  final String label;
  final String value;
  final ContactType type;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: value.isEmpty ? null : () => _showContactActions(context),
    );
  }

  Future<void> _showContactActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    Icon(type == ContactType.phone ? Icons.phone : Icons.chat),
                title: Text(type == ContactType.phone
                    ? 'Call provider'
                    : 'Open WhatsApp'),
                onTap: () => Navigator.pop(context, 'open'),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy contact'),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
            ],
          ),
        );
      },
    );
    if (action == null) return;

    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: value));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact copied.')),
        );
      }
      return;
    }

    final clean = value.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = type == ContactType.phone
        ? Uri(scheme: 'tel', path: clean)
        : Uri.parse('https://wa.me/${clean.replaceAll('+', '')}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class StatusTile extends StatelessWidget {
  const StatusTile({
    super.key,
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
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

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.status});

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

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
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
    return Panel(
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

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return AvatarFallback(size: size);
    }
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return AvatarFallback(size: size);
        },
      ),
    );
  }
}

class AvatarFallback extends StatelessWidget {
  const AvatarFallback({super.key, required this.size});

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

class InlineEmpty extends StatelessWidget {
  const InlineEmpty({
    super.key,
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
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

String shortDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day} $hour:$minute';
}

String stars(double rating) {
  final rounded = rating.round().clamp(1, 5);
  return '${'★' * rounded}${'☆' * (5 - rounded)}';
}

double averageRating(List<ReviewRecord> reviews) {
  if (reviews.isEmpty) return 0;
  final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
  return total / reviews.length;
}

String contentTypeFor(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

Future<void> showIssueDialog(
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

Future<void> showReviewDialog(
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
