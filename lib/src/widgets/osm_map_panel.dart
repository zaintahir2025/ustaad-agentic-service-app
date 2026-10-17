import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../ustaad_state.dart';
import 'common_widgets.dart';

class ViewSwitcher extends StatelessWidget {
  const ViewSwitcher({
    super.key,
    required this.showMap,
    required this.onChanged,
  });

  final bool showMap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.list),
          label: Text('List'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.map),
          label: Text('Map'),
        ),
      ],
      selected: {showMap},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class OpenStreetMapPanel extends StatelessWidget {
  const OpenStreetMapPanel({super.key, required this.providers});

  final List<UstaadProviderProfile> providers;

  @override
  Widget build(BuildContext context) {
    final best = providers.isEmpty ? null : providers.first;
    final markers = providers
        .where((provider) =>
            provider.latitude != null && provider.longitude != null)
        .map((provider) {
      final recommended = best?.id == provider.id;
      return Marker(
        width: recommended ? 54 : 46,
        height: recommended ? 54 : 46,
        point: LatLng(provider.latitude!, provider.longitude!),
        child: Tooltip(
          message:
              '${provider.name}\n${provider.role} - ${provider.distanceKm} km - ${provider.rating} rating',
          child: MapPin(provider: provider, recommended: recommended),
        ),
      );
    }).toList();

    if (markers.isEmpty) {
      return const InlineEmpty(
        icon: Icons.map_outlined,
        text: 'Map coordinates are not available for these providers yet.',
      );
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MapLegend(),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).width < 640 ? 360 : 430,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(33.6938, 73.0652),
                  initialZoom: 11.6,
                  minZoom: 9,
                  maxZoom: 17,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ustaad.service',
                    retinaMode: RetinaMode.isHighDensity(context),
                  ),
                  MarkerLayer(markers: markers),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (best != null) ...[
            const SizedBox(height: 12),
            MapRecommendedProvider(provider: best),
          ],
        ],
      ),
    );
  }
}

class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.provider,
    required this.recommended,
  });

  final UstaadProviderProfile provider;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final color =
        recommended ? Theme.of(context).colorScheme.primary : Colors.blueAccent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
      child: Icon(
        recommended ? Icons.star : Icons.handyman,
        color: recommended
            ? Theme.of(context).colorScheme.onPrimary
            : Colors.white,
        size: recommended ? 24 : 20,
      ),
    );
  }
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: const [
        LegendItem(color: Colors.lightGreenAccent, label: 'Best match'),
        LegendItem(color: Colors.blueAccent, label: 'Available'),
        LegendItem(color: Colors.orangeAccent, label: 'Nearby sectors'),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  const LegendItem({
    super.key,
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }
}

class MapRecommendedProvider extends StatelessWidget {
  const MapRecommendedProvider({super.key, required this.provider});

  final UstaadProviderProfile provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Avatar(url: provider.avatarUrl, size: 48),
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
                Text(
                  '${provider.role} - ${provider.distanceKm} km - Rs. ${provider.price}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.read<UstaadState>().bookProvider(provider),
            icon: const Icon(Icons.calendar_month),
            label: const Text('Book'),
          ),
        ],
      ),
    );
  }
}
