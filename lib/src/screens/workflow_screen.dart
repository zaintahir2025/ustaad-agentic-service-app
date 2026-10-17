import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../ustaad_state.dart';
import '../widgets/common_widgets.dart';

class WorkflowScreen extends StatelessWidget {
  const WorkflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final provider = state.selectedProvider;

    if (provider == null) {
      return Stage(
        child: Column(
          children: [
            const AppBarLine(
              title: 'Workflow',
              subtitle: 'No active booking',
              showNav: true,
            ),
            const SizedBox(height: 20),
            EmptyState(
              icon: Icons.receipt_long,
              title: 'No active booking in progress',
              actionLabel: 'Go to Home',
              onAction: () => context.read<UstaadState>().openHome(),
            ),
          ],
        ),
      );
    }

    final booking = state.latestBooking;
    final eta = booking?.etaMinutes ?? etaMinutesFor(provider);
    final saving = state.bookingBusy;

    return Stage(
      wideMaxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBarLine(
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
          Panel(
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
                ContactBar(
                  phone: booking?.providerPhone ?? provider.phone,
                  whatsapp: booking?.providerWhatsapp ?? provider.whatsapp,
                ),
                const SizedBox(height: 12),
                StatusTile(
                  icon: Icons.calendar_month,
                  title: booking?.slotLabel ?? provider.nextSlot,
                  subtitle: booking?.confirmationMessage ??
                      'Confirmed for the selected slot.',
                ),
                const SizedBox(height: 10),
                const StatusTile(
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
                TracePanel(
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
                            : () => showReviewDialog(
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
