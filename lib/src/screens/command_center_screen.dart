import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../ustaad_state.dart';
import '../widgets/common_widgets.dart';

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
  int _locationResolveVersion = 0;
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

    return Stage(
      wideMaxWidth: 1080,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBarLine(
            title: user == null ? 'Book' : 'Hi ${user.firstName}',
            subtitle: state.backendOnline ? 'Connected' : 'Offline ready',
            actions: [
              IconButton(
                tooltip: AppLocalizations.of(context)?.aiAssistant ??
                    'Ustaad AI Assistant',
                icon: const Icon(Icons.smart_toy_outlined),
                onPressed: () => context.read<UstaadState>().openAIChat(),
              ),
            ],
            showNav: true,
          ),
          const SizedBox(height: 12),
          HomeDashboard(
            bookings: state.bookings,
            savedCount: state.savedProviderIds.length,
            recentRequests: state.recentRequests,
            onUseRecent: (request) {
              _problem.text = request.fullText;
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
    final l10n = AppLocalizations.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _location,
            decoration: InputDecoration(
              labelText: 'Location',
              prefixIcon: const Icon(Icons.place),
              suffixIcon: IconButton(
                tooltip: 'Search or track location',
                icon: _locating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore),
                onPressed: _locating ? null : _showLocationSearch,
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
            decoration: InputDecoration(
              labelText: 'Request',
              hintText: l10n?.requestPlaceholder ?? 'Describe what you need',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ExampleChip(
                label: 'AC',
                onTap: () {
                  _problem.text =
                      'Mujhe kal subah G-13 mein AC technician chahiye';
                },
              ),
              ExampleChip(
                label: 'Leak',
                onTap: () => _problem.text = 'Urgent pani leak in kitchen',
              ),
              ExampleChip(
                label: 'Urdu',
                onTap: () => _problem.text = 'اے سی ٹھنڈا نہیں ہو رہا',
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.search),
            label: Text(l10n?.findProviders ?? 'Find providers'),
          ),
        ],
      ),
    );
  }

  Widget _quickServices() {
    final l10n = AppLocalizations.of(context);
    final services = [
      (Icons.ac_unit, l10n?.acRepair ?? 'AC Repair', 'AC Repair'),
      (Icons.water_drop, l10n?.plumber ?? 'Plumber', 'Plumber'),
      (
        Icons.electrical_services,
        l10n?.electrician ?? 'Electrician',
        'Electrician'
      ),
      (Icons.cleaning_services, l10n?.cleaning ?? 'Cleaning', 'Cleaning'),
      (Icons.school, l10n?.tutor ?? 'Tutor', 'Tutor'),
      (
        Icons.face_retouching_natural,
        l10n?.beautician ?? 'Beautician',
        'Beautician'
      ),
    ];

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n?.quickBook ?? 'Quick book',
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
                  _problem.text = 'I need a ${service.$3} expert';
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

    final l10n = AppLocalizations.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.providerDirectory ?? 'Provider directory',
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
                  return [
                    PopupMenuItem(
                      value: 'Best match',
                      child: Text(l10n?.bestMatch ?? 'Best match'),
                    ),
                    PopupMenuItem(
                      value: 'Nearest',
                      child: Text(l10n?.nearest ?? 'Nearest'),
                    ),
                    PopupMenuItem(
                      value: 'Rating',
                      child: Text(l10n?.rating ?? 'Rating'),
                    ),
                    PopupMenuItem(
                      value: 'Price',
                      child: Text(l10n?.price ?? 'Price'),
                    ),
                  ];
                },
                icon: const Icon(Icons.sort),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              labelText: l10n?.searchProviders ?? 'Search providers',
              prefixIcon: const Icon(Icons.search),
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
            const InlineEmpty(
              icon: Icons.search_off,
              text: 'No providers match this search.',
            )
          else
            ...visible.take(5).map((provider) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ProviderListTile(provider: provider),
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

  Future<void> _showLocationSearch() async {
    final query = TextEditingController(text: _location.text);
    await context.read<UstaadState>().searchLocations(query.text);
    if (!mounted) {
      query.dispose();
      return;
    }

    final selected = await showModalBottomSheet<LocationSuggestion>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final state = context.watch<UstaadState>();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: query,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Search Islamabad sectors',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Search',
                          icon: state.locationSearchBusy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward),
                          onPressed: state.locationSearchBusy
                              ? null
                              : () async {
                                  await context
                                      .read<UstaadState>()
                                      .searchLocations(query.text);
                                  setSheetState(() {});
                                },
                        ),
                      ),
                      onSubmitted: (_) async {
                        await context
                            .read<UstaadState>()
                            .searchLocations(query.text);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.my_location),
                            title: const Text('Use live GPS'),
                            subtitle: const Text('Read this device location'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _toggleLocationTracking();
                            },
                          ),
                          ...state.locationSuggestions.map((item) {
                            return ListTile(
                              leading: const Icon(Icons.place_outlined),
                              title: Text(item.label),
                              subtitle: Text(
                                item.subtitle.isEmpty
                                    ? item.locationText
                                    : item.subtitle,
                              ),
                              onTap: () => Navigator.pop(sheetContext, item),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    query.dispose();

    if (selected == null || !mounted) return;
    context.read<UstaadState>().setActiveLocation(selected);
    setState(() {
      _location.text = selected.locationText;
      _locationStatus = 'Location selected with OpenStreetMap search.';
    });
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
      await _applyPosition(position, tracking: false);

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
        _locationStatus = 'Tracking this address. Accuracy: '
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

  Future<void> _applyPosition(Position position,
      {required bool tracking}) async {
    if (!mounted) return;
    final version = ++_locationResolveVersion;
    final state = context.read<UstaadState>();
    setState(() {
      _locationStatus = tracking
          ? 'Resolving live address... Accuracy: '
              '${position.accuracy.toStringAsFixed(0)} m.'
          : 'Resolving your address... Accuracy: '
              '${position.accuracy.toStringAsFixed(0)} m.';
    });

    final resolved = await state.resolveCurrentAddress(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted || version != _locationResolveVersion) return;

    setState(() {
      _location.text = resolved.locationText;
      _locationStatus = tracking
          ? 'Live location updated. Accuracy: '
              '${position.accuracy.toStringAsFixed(0)} m.'
          : 'Current location found. Accuracy: '
              '${position.accuracy.toStringAsFixed(0)} m.';
    });
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

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.bookings,
    required this.savedCount,
    required this.recentRequests,
    required this.onUseRecent,
  });

  final List<BookingRecord> bookings;
  final int savedCount;
  final List<SmartSuggestion> recentRequests;
  final ValueChanged<SmartSuggestion> onUseRecent;

  @override
  Widget build(BuildContext context) {
    final active = bookings
        .where((booking) =>
            booking.status != 'completed' && booking.status != 'cancelled')
        .length;
    final completed =
        bookings.where((booking) => booking.status == 'completed').length;

    final l10n = AppLocalizations.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryMetric(
                  icon: Icons.timeline,
                  label: l10n?.active ?? 'Active',
                  value: '$active',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryMetric(
                  icon: Icons.bookmark,
                  label: l10n?.saved ?? 'Saved',
                  value: '$savedCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryMetric(
                  icon: Icons.verified,
                  label: l10n?.done ?? 'Done',
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
                    request.label,
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

class SummaryMetric extends StatelessWidget {
  const SummaryMetric({
    super.key,
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

class ProviderListTile extends StatelessWidget {
  const ProviderListTile({super.key, required this.provider});

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
          Avatar(url: provider.avatarUrl, size: 46),
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
