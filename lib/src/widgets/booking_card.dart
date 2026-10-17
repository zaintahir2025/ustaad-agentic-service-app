import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../ustaad_state.dart';
import 'common_widgets.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});

  final BookingRecord booking;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(url: booking.providerAvatarUrl, size: 52),
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
              StatusChip(label: booking.statusLabel, status: booking.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.problemText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          StatusTile(
            icon: Icons.calendar_month,
            title: booking.slotLabel,
            subtitle: booking.location,
          ),
          const SizedBox(height: 10),
          ContactBar(
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
                    : () => showIssueDialog(context, booking),
                icon: const Icon(Icons.report_problem),
                label: Text(
                  AppLocalizations.of(context)?.reportIssue ?? 'Issue',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _rebook(context, booking),
                icon: const Icon(Icons.replay),
                label: Text(
                  AppLocalizations.of(context)?.rebook ?? 'Rebook',
                ),
              ),
              FilledButton.icon(
                onPressed: () => showReviewDialog(
                  context,
                  providerId: booking.providerId,
                  providerName: booking.providerName,
                  bookingId: booking.id,
                ),
                icon: const Icon(Icons.star),
                label: Text(
                  AppLocalizations.of(context)?.review ?? 'Review',
                ),
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
