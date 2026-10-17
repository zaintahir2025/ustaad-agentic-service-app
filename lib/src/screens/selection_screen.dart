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
