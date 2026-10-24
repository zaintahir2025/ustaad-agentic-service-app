import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Industrial Push Notifications Service powered by Firebase Cloud Messaging (FCM).
class NotificationService {
  final FirebaseMessaging _fcm;
  final FirebaseFirestore _firestore;

  NotificationService({
    FirebaseMessaging? fcm,
    FirebaseFirestore? firestore,
  })  : _fcm = fcm ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Requests notification permissions for iOS and Android 13+.
  Future<NotificationSettings> requestPermissions() async {
    return await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  /// Registers device token to the authenticated user's profile in Firestore.
  Future<void> registerDeviceToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[NotificationService] Failed to register token: $e');
    }
  }

  /// Removes device token on sign-out to prevent privacy leakage.
  Future<void> unregisterDeviceToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (_) {}
  }

  /// Subscribes to a booking topic for two-way lifecycle notifications.
  Future<void> subscribeToBooking(String bookingId) async {
    if (!kIsWeb) {
      await _fcm.subscribeToTopic('booking_$bookingId');
    }
  }

  /// Unsubscribes from a completed or cancelled booking.
  Future<void> unsubscribeFromBooking(String bookingId) async {
    if (!kIsWeb) {
      await _fcm.unsubscribeFromTopic('booking_$bookingId');
    }
  }

  /// Sets up foreground notification stream.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  /// Sets up notification tapped stream for navigation.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
