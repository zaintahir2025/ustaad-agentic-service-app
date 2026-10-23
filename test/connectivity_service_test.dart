import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustaad_flutter/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QueuedBookingRequest Serialization Tests', () {
    test('serializes to Map and JSON accurately', () {
      final now = DateTime(2026, 10, 24, 12, 0);
      final request = QueuedBookingRequest(
        id: 'offline_123',
        providerId: 'prov_456',
        role: 'Electrician',
        offeredPrice: 700,
        address: 'House 14, G-13/2, Islamabad',
        notes: 'Fan short circuit',
        queuedAt: now,
        phone: '+923001234567',
      );

      final json = request.toJson();
      final deserialized = QueuedBookingRequest.fromJson(json);

      expect(deserialized.id, equals('offline_123'));
      expect(deserialized.providerId, equals('prov_456'));
      expect(deserialized.role, equals('Electrician'));
      expect(deserialized.offeredPrice, equals(700));
      expect(deserialized.address, equals('House 14, G-13/2, Islamabad'));
      expect(deserialized.notes, equals('Fan short circuit'));
      expect(deserialized.phone, equals('+923001234567'));
    });
  });

  group('ConnectivityService Offline Queue Tests', () {
    test('queues requests and retrieves them persistently', () async {
      final service = ConnectivityService();
      await service.initialize();

      expect(await service.queuedCount(), equals(0));

      final req1 = QueuedBookingRequest(
        id: 'req_1',
        providerId: 'prov_1',
        role: 'Plumber',
        offeredPrice: 500,
        address: 'Street 4, F-10, Islamabad',
        notes: 'Kitchen sink pipe repair',
        queuedAt: DateTime.now(),
      );

      final req2 = QueuedBookingRequest(
        id: 'req_2',
        providerId: 'prov_2',
        role: 'AC Repair',
        offeredPrice: 1200,
        address: 'DHA Phase 2, Rawalpindi',
        notes: 'AC Gas Refill',
        queuedAt: DateTime.now(),
      );

      await service.queueBooking(req1);
      expect(await service.queuedCount(), equals(1));

      await service.queueBooking(req2);
      expect(await service.queuedCount(), equals(2));

      final all = await service.getQueuedBookings();
      expect(all.length, equals(2));
      expect(all[0].id, equals('req_1'));
      expect(all[1].id, equals('req_2'));

      // Remove single
      await service.removeQueuedBooking('req_1');
      expect(await service.queuedCount(), equals(1));
      final remaining = await service.getQueuedBookings();
      expect(remaining.first.id, equals('req_2'));

      // Clear all
      await service.clearQueue();
      expect(await service.queuedCount(), equals(0));
    });

    test('syncQueuedBookings executes handler and flushes synchronized bookings', () async {
      final service = ConnectivityService();
      await service.initialize();

      final req = QueuedBookingRequest(
        id: 'sync_me',
        providerId: 'prov_ahmed',
        role: 'Electrician',
        offeredPrice: 800,
        address: 'G-11, Islamabad',
        notes: 'Breaker replacement',
        queuedAt: DateTime.now(),
      );

      await service.queueBooking(req);
      expect(await service.queuedCount(), equals(1));

      final synced = await service.syncQueuedBookings(
        onSyncBooking: (r) async {
          expect(r.id, equals('sync_me'));
          return true; // Synchronization successful
        },
      );

      expect(synced, equals(1));
      expect(await service.queuedCount(), equals(0));
    });
  });
}
