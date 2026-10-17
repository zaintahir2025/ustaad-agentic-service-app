import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../ustaad_state.dart';
import '../widgets/booking_card.dart';
import '../widgets/common_widgets.dart';

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

    return Stage(
      wideMaxWidth: 960,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBarLine(
            title: AppLocalizations.of(context)?.bookings ?? 'Bookings',
            subtitle: 'Status',
            leading: IconButton(
              tooltip: AppLocalizations.of(context)?.home ?? 'Home',
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
            EmptyState(
              icon: Icons.receipt_long,
              title: 'No bookings yet',
              actionLabel: 'Book a service',
              onAction: () => context.read<UstaadState>().openHome(),
            )
          else if (filtered.isEmpty)
            const InlineEmpty(
              icon: Icons.search_off,
              text: 'No bookings match this filter.',
            )
          else
            ...filtered.map((booking) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BookingCard(booking: booking),
              );
            }),
        ],
      ),
    );
  }
}
