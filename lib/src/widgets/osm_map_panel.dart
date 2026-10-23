import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../currency.dart';
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _SwitchItem(
              icon: Icons.view_agenda_outlined,
              label: 'Provider List',
              isSelected: !showMap,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SwitchItem(
              icon: Icons.map_outlined,
              label: 'Live Map',
              isSelected: showMap,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpenStreetMapPanel extends StatefulWidget {
  const OpenStreetMapPanel({super.key, required this.providers});

  final List<UstaadProviderProfile> providers;

  @override
  State<OpenStreetMapPanel> createState() => _OpenStreetMapPanelState();
}

class _OpenStreetMapPanelState extends State<OpenStreetMapPanel> {
  late final MapController _mapController;
  String? _selectedProviderId;
  bool _useOsmStandard = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.providers.isNotEmpty) {
      _selectedProviderId = widget.providers.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant OpenStreetMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedProviderId == null && widget.providers.isNotEmpty) {
      _selectedProviderId = widget.providers.first.id;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _selectProvider(UstaadProviderProfile provider) {
    setState(() => _selectedProviderId = provider.id);
    if (provider.latitude != null && provider.longitude != null) {
      _mapController.move(
        LatLng(provider.latitude!, provider.longitude!),
        13.5,
      );
    }
  }

  void _recenter() {
    final valid = widget.providers
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
    if (valid.isNotEmpty) {
      final avgLat =
          valid.map((p) => p.latitude!).reduce((a, b) => a + b) / valid.length;
      final avgLng =
          valid.map((p) => p.longitude!).reduce((a, b) => a + b) / valid.length;
      _mapController.move(LatLng(avgLat, avgLng), 12.0);
    } else {
      _mapController.move(const LatLng(33.6938, 73.0652), 12.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final validProviders = widget.providers
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();

    if (validProviders.isEmpty) {
      return const InlineEmpty(
        icon: Icons.map_outlined,
        text: 'Map coordinates are not available for these providers yet.',
      );
    }

    final selected = widget.providers.firstWhere(
      (p) => p.id == _selectedProviderId,
      orElse: () => validProviders.first,
    );

    // Initial map center
    final initialCenter = LatLng(
      selected.latitude ?? 33.6938,
      selected.longitude ?? 73.0652,
    );

    // Build markers with interactive tapping
    final markers = validProviders.map((provider) {
      final isSelected = provider.id == selected.id;
      final isBestMatch = provider.id == widget.providers.first.id;

      return Marker(
        width: isSelected ? 62 : 48,
        height: isSelected ? 62 : 48,
        point: LatLng(provider.latitude!, provider.longitude!),
        child: GestureDetector(
          onTap: () => _selectProvider(provider),
          child: Tooltip(
            message:
                '${provider.name} • ${provider.role}\n${provider.distanceKm} km • ${formatPkr(provider.price)}',
            child: MapPin(
              provider: provider,
              isSelected: isSelected,
              isBestMatch: isBestMatch,
            ),
          ),
        ),
      );
    }).toList();

    // Tile URLs
    final cartoUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
    const osmUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

    final tileUrl = _useOsmStandard ? osmUrl : cartoUrl;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Provider Map',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Tap a pin to inspect provider and lock booking',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: _useOsmStandard
                    ? 'Switch to Carto Voyager tiles'
                    : 'Switch to OpenStreetMap Standard tiles',
                icon: Icon(
                  _useOsmStandard ? Icons.layers : Icons.layers_outlined,
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _useOsmStandard = !_useOsmStandard);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const MapLegend(),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).width < 640 ? 380 : 440,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: 12.2,
                      minZoom: 8,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: tileUrl,
                        subdomains: const ['a', 'b', 'c', 'd'],
                        fallbackUrl: osmUrl,
                        userAgentPackageName: 'com.ustaad.service',
                        retinaMode: RetinaMode.isHighDensity(context),
                      ),
                      MarkerLayer(markers: markers),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'OpenStreetMap & CartoDB contributors',
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Floating Map Controls (Zoom in, Zoom out, Recenter)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _MapControlButton(
                          icon: Icons.add,
                          tooltip: 'Zoom in',
                          onTap: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        _MapControlButton(
                          icon: Icons.remove,
                          tooltip: 'Zoom out',
                          onTap: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        _MapControlButton(
                          icon: Icons.my_location,
                          tooltip: 'Center on providers',
                          onTap: _recenter,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          MapRecommendedProvider(
            provider: selected,
            isSelected: true,
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.provider,
    required this.isSelected,
    required this.isBestMatch,
  });

  final UstaadProviderProfile provider;
  final bool isSelected;
  final bool isBestMatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isBestMatch
        ? theme.colorScheme.primary
        : (isSelected ? Colors.tealAccent.shade700 : Colors.indigoAccent);

    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.55 : 0.35),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.white : theme.colorScheme.surface,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Center(
          child: Icon(
            isBestMatch
                ? Icons.star
                : switch (provider.role.toLowerCase()) {
                    'ac repair' => Icons.ac_unit,
                    'plumber' => Icons.water_drop,
                    'electrician' => Icons.electrical_services,
                    'cleaning' => Icons.cleaning_services,
                    'tutor' => Icons.school,
                    'beautician' => Icons.face_retouching_natural,
                    _ => Icons.handyman,
                  },
            color: isBestMatch ? theme.colorScheme.onPrimary : Colors.white,
            size: isSelected ? 24 : 18,
          ),
        ),
      ),
    );
  }
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        LegendItem(color: Color(0xFF10B981), label: 'Best Match'),
        LegendItem(color: Colors.indigoAccent, label: 'Verified Provider'),
        LegendItem(color: Colors.tealAccent, label: 'Selected Provider'),
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
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}

class MapRecommendedProvider extends StatelessWidget {
  const MapRecommendedProvider({
    super.key,
    required this.provider,
    this.isSelected = false,
  });

  final UstaadProviderProfile provider;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(url: provider.avatarUrl, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (provider.verified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${provider.role} • ${provider.distanceKm} km away • ${provider.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${provider.rating} ★ (${provider.jobsCompleted} jobs) • ${formatPkr(provider.price)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.read<UstaadState>().previewProvider(provider),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View Profile'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.bookingBusy
                      ? null
                      : () => context.read<UstaadState>().bookProvider(provider),
                  icon: state.bookingBusy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.handshake, size: 16),
                  label: Text(
                    state.bookingBusy ? 'Booking...' : 'Book (${formatPkr(provider.price)})',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
