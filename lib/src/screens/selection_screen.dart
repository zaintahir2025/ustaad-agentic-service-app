import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ustaad_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/osm_map_panel.dart';
import '../widgets/provider_card.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final intent = state.intent;
    final quote = state.quote;

    if (intent == null || quote == null) {
      return Stage(
        child: Column(
          children: [
            const AppBarLine(
              title: 'Matches',
              subtitle: 'No active search',
              showNav: true,
            ),
            const SizedBox(height: 20),
            EmptyState(
              icon: Icons.search_off,
              title: 'No search active',
              actionLabel: 'Go to Home',
              onAction: () => context.read<UstaadState>().openHome(),
            ),
          ],
        ),
      );
    }

    return Stage(
      wideMaxWidth: 1080,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBarLine(
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
          ViewSwitcher(
            showMap: _showMap,
            onChanged: (value) => setState(() => _showMap = value),
          ),
          const SizedBox(height: 12),
          IntentSummary(intent: intent),
          const SizedBox(height: 12),
          const InDriveOfferBar(),
          const SizedBox(height: 12),
          QuotePanel(quote: quote),
          const SizedBox(height: 12),
          if (_showMap)
            OpenStreetMapPanel(providers: state.rankedProviders)
          else
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
                      child: ProviderCard(
                        provider: provider,
                        best: provider == state.rankedProviders.first,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          const SizedBox(height: 12),
          TracePanel(events: state.workflowEvents),
        ],
      ),
    );
  }
}

class InDriveOfferBar extends StatelessWidget {
  const InDriveOfferBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final activeOffer = state.activeOffer;
    final colorScheme = Theme.of(context).colorScheme;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_offer,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your InDrive Offer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Rs. $activeOffer',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PKR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit'),
                onPressed: () => _showEditOfferDialog(context, activeOffer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Raise / Lower Offer:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _adjustButton(context, -50, '-50'),
              const SizedBox(width: 6),
              _adjustButton(context, 50, '+50'),
              const SizedBox(width: 6),
              _adjustButton(context, 100, '+100'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adjustButton(BuildContext context, int delta, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => context.read<UstaadState>().adjustUserOffer(delta),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showEditOfferDialog(BuildContext context, int currentOffer) {
    final controller = TextEditingController(text: '$currentOffer');
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set Your Offer'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Offer (PKR)',
              prefixText: 'Rs. ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val >= 200) {
                  context.read<UstaadState>().setUserOffer(val);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Update Offer'),
            ),
          ],
        );
      },
    );
  }
}
