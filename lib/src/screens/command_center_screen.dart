import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../currency.dart';
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
  final _budget = TextEditingController();
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
    _budget.dispose();
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
                Expanded(flex: 5, child: _requestPanel(state)),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _quickServices()),
              ],
            )
          else ...[
            _requestPanel(state),
            const SizedBox(height: 12),
            _quickServices(),
          ],
          const SizedBox(height: 12),
          _providerDirectory(state),
        ],
      ),
    );
  }

  Widget _requestPanel(UstaadState state) {
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
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    'Quick:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final sector in [
                  'G-13',
                  'F-10',
                  'E-11',
                  'Bahria Town',
                  'DHA-2',
                  'I-8',
                  'F-7'
                ]) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.near_me_outlined, size: 13),
                      label: Text(sector, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        final fullName = sector == 'Bahria Town'
                            ? 'Bahria Town, Rawalpindi'
                            : (sector == 'DHA-2'
                                ? 'DHA Phase 2, Islamabad'
                                : '$sector, Islamabad');
                        setState(() {
                          _location.text = fullName;
                          _locationStatus = 'Selected $fullName';
                        });
                        context.read<UstaadState>().setActiveLocation(
                              LocationSuggestion(
                                label: fullName,
                                subtitle: 'Islamabad / Rawalpindi',
                                latitude: 33.6844,
                                longitude: 73.0479,
                              ),
                            );
                      },
                    ),
                  ),
                ],
              ],
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
                label: 'AC (${formatPkr(1200)})',
                onTap: () {
                  _problem.text =
                      'Mujhe kal subah G-13 mein AC technician chahiye';
                  _budget.text = '1200';
                },
              ),
              ExampleChip(
                label: 'Leak (${formatPkr(600)})',
                onTap: () {
                  _problem.text = 'Urgent pani leak in kitchen';
                  _budget.text = '600';
                },
              ),
              ExampleChip(
                label: 'Urdu (${formatPkr(1200)})',
                onTap: () {
                  _problem.text = 'اے سی ٹھنڈا نہیں ہو رہا';
                  _budget.text = '1200';
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your Offer / Budget (InDrive Style)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _budget,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Offer (PKR)',
                          hintText: 'e.g. 600',
                          prefixText: 'PKR ',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Decrease by ${formatPkr(50)}',
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () {
                        final val = int.tryParse(_budget.text) ?? 600;
                        final newVal = (val - 50).clamp(200, 20000);
                        setState(() => _budget.text = '$newVal');
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      tooltip: 'Increase by ${formatPkr(50)}',
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        final val = int.tryParse(_budget.text) ?? 600;
                        final newVal = (val + 50).clamp(200, 20000);
                        setState(() => _budget.text = '$newVal');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [400, 600, 800, 1000, 1500].map((preset) {
                    final isSelected = _budget.text == '$preset';
                    return ChoiceChip(
                      label: Text(formatPkr(preset)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _budget.text = '$preset'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: state.isAnalyzing ? null : _analyze,
            icon: state.isAnalyzing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(state.isAnalyzing
                ? 'Finding providers...'
                : (l10n?.findProviders ?? 'Find providers')),
          ),
        ],
      ),
    );
  }

  Widget _quickServices() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final services = [
      (
        icon: Icons.ac_unit,
        label: l10n?.acRepair ?? 'AC Repair',
        role: 'AC Repair',
        price: 1200,
        color: const Color(0xFF0EA5E9),
      ),
      (
        icon: Icons.water_drop,
        label: l10n?.plumber ?? 'Plumber',
        role: 'Plumber',
        price: 600,
        color: const Color(0xFF06B6D4),
      ),
      (
        icon: Icons.electrical_services,
        label: l10n?.electrician ?? 'Electrician',
        role: 'Electrician',
        price: 800,
        color: const Color(0xFFF59E0B),
      ),
      (
        icon: Icons.cleaning_services,
        label: l10n?.cleaning ?? 'Cleaning',
        role: 'Cleaning',
        price: 1000,
        color: const Color(0xFF10B981),
      ),
      (
        icon: Icons.school,
        label: l10n?.tutor ?? 'Home Tutor',
        role: 'Tutor',
        price: 1500,
        color: const Color(0xFF8B5CF6),
      ),
      (
        icon: Icons.face_retouching_natural,
        label: l10n?.beautician ?? 'Beautician',
        role: 'Beautician',
        price: 1500,
        color: const Color(0xFFEC4899),
      ),
    ];

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.quickBook ?? 'Popular Services',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '1-Tap Match',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 380;
              final crossAxisCount = isWide ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isWide ? 1.15 : 1.35,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  final isSelected = _serviceFilter == service.role;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      _problem.text = 'I need a professional ${service.role}';
                      setState(() {
                        _budget.text = '${service.price}';
                        _serviceFilter = service.role;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor.withValues(alpha: 0.5),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: service.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              service.icon,
                              size: 20,
                              color: service.color,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'from ${formatPkr(service.price)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
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
    final state = context.read<UstaadState>();
    if (state.isAnalyzing) return;
    final problem = _problem.text.trim();
    if (problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the service first.')),
      );
      return;
    }
    final budgetStr = _budget.text.trim();
    int? parsedBudget;
    if (budgetStr.isNotEmpty) {
      parsedBudget = int.tryParse(budgetStr);
      if (parsedBudget == null || parsedBudget <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid numeric budget (e.g. 600).'),
          ),
        );
        return;
      }
    }
    state.startAnalysis(
      problem,
      _location.text,
      initialOffer: parsedBudget,
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: scheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Avatar(url: provider.avatarUrl, size: 50),
              if (provider.verified)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 10,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      provider.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${provider.rating}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${provider.role} • ${provider.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_outlined,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${provider.distanceKm} km',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formatPkr(provider.price),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: saved ? 'Unsave provider' : 'Save provider',
            onPressed: () =>
                context.read<UstaadState>().toggleSavedProvider(provider.id),
            icon: Icon(
              saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? scheme.primary : null,
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () =>
                context.read<UstaadState>().previewProvider(provider),
            child: const Text('Book',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
