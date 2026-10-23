import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Representation of an offline-queued booking request.
class QueuedBookingRequest {
  const QueuedBookingRequest({
    required this.id,
    required this.providerId,
    required this.role,
    required this.offeredPrice,
    required this.address,
    required this.notes,
    required this.queuedAt,
    this.phone = '',
  });

  final String id;
  final String providerId;
  final String role;
  final int offeredPrice;
  final String address;
  final String notes;
  final DateTime queuedAt;
  final String phone;

  Map<String, dynamic> toMap() => {
        'id': id,
        'providerId': providerId,
        'role': role,
        'offeredPrice': offeredPrice,
        'address': address,
        'notes': notes,
        'queuedAt': queuedAt.toIso8601String(),
        'phone': phone,
      };

  factory QueuedBookingRequest.fromMap(Map<String, dynamic> map) {
    return QueuedBookingRequest(
      id: map['id']?.toString() ?? '',
      providerId: map['providerId']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      offeredPrice: (map['offeredPrice'] as num?)?.toInt() ?? 0,
      address: map['address']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      queuedAt: DateTime.tryParse(map['queuedAt']?.toString() ?? '') ??
          DateTime.now(),
      phone: map['phone']?.toString() ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory QueuedBookingRequest.fromJson(String source) =>
      QueuedBookingRequest.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Service that monitors device connectivity (WiFi, Cellular, None)
/// and manages offline-queued booking requests.
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    SharedPreferences? preferences,
  })  : _connectivity = connectivity ?? Connectivity(),
        _prefs = preferences {
    try {
      _subscription =
          _connectivity.onConnectivityChanged.listen(_handleStatusChange);
    } catch (_) {
      // Handle test environments where platform event channel is uninitialized
    }
  }

  static const String queueStorageKey = 'ustaad_offline_bookings_queue';

  final Connectivity _connectivity;
  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final _isOnlineController = StreamController<bool>.broadcast();
  Stream<bool> get isOnlineStream => _isOnlineController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    try {
      final results = await _connectivity.checkConnectivity();
      _updateOnlineStatus(results);
    } catch (_) {
      _isOnline = true;
      _isOnlineController.add(true);
    }
  }

  void _handleStatusChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _updateOnlineStatus(results);

    // If transitioned from offline to online, trigger automatic queue synchronization
    if (!wasOnline && _isOnline) {
      syncQueuedBookings();
    }
  }

  void _updateOnlineStatus(List<ConnectivityResult> results) {
    _isOnline = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    _isOnlineController.add(_isOnline);
  }

  /// Queues a booking request locally in persistent storage.
  Future<void> queueBooking(QueuedBookingRequest request) async {
    _prefs ??= await SharedPreferences.getInstance();
    final list = await getQueuedBookings();
    list.add(request);
    final serialized = list.map((b) => b.toJson()).toList();
    await _prefs!.setStringList(queueStorageKey, serialized);
  }

  /// Retrieves all pending offline-queued bookings.
  Future<List<QueuedBookingRequest>> getQueuedBookings() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getStringList(queueStorageKey) ?? [];
    return raw.map((item) => QueuedBookingRequest.fromJson(item)).toList();
  }

  /// Number of pending requests in the offline queue.
  Future<int> queuedCount() async {
    final list = await getQueuedBookings();
    return list.length;
  }

  /// Removes a specific booking from the offline queue.
  Future<void> removeQueuedBooking(String id) async {
    _prefs ??= await SharedPreferences.getInstance();
    final list = await getQueuedBookings();
    list.removeWhere((item) => item.id == id);
    final serialized = list.map((b) => b.toJson()).toList();
    await _prefs!.setStringList(queueStorageKey, serialized);
  }

  /// Clears the entire offline queue.
  Future<void> clearQueue() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(queueStorageKey);
  }

  /// Synchronizes all queued bookings using an external handler.
  Future<int> syncQueuedBookings({
    Future<bool> Function(QueuedBookingRequest request)? onSyncBooking,
  }) async {
    if (!_isOnline) return 0;
    final queued = await getQueuedBookings();
    if (queued.isEmpty) return 0;

    int syncedCount = 0;
    for (final request in List<QueuedBookingRequest>.from(queued)) {
      if (onSyncBooking != null) {
        final success = await onSyncBooking(request);
        if (success) {
          await removeQueuedBooking(request.id);
          syncedCount++;
        }
      } else {
        // Default sync: keep in queue until explicitly handled
        syncedCount++;
      }
    }
    return syncedCount;
  }

  void dispose() {
    _subscription?.cancel();
    _isOnlineController.close();
  }
}
