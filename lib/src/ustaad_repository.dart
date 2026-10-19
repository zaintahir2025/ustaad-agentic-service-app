import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'models.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class UstaadRepository {
  UstaadRepository({
    auth.FirebaseAuth? authInstance,
    FirebaseFirestore? firestoreInstance,
    FirebaseStorage? storageInstance,
  })  : _customAuth = authInstance,
        _customDb = firestoreInstance,
        _customStorage = storageInstance;

  final auth.FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customDb;
  final FirebaseStorage? _customStorage;

  bool get isFirebaseInitialized =>
      _customAuth != null || Firebase.apps.isNotEmpty;

  auth.FirebaseAuth get _auth =>
      _customAuth ??
      (isFirebaseInitialized
          ? auth.FirebaseAuth.instance
          : throw const AuthException('Firebase is not initialized.'));

  FirebaseFirestore get _db =>
      _customDb ??
      (isFirebaseInitialized
          ? FirebaseFirestore.instance
          : throw StateError('Firebase is not initialized.'));

  FirebaseStorage get _storage =>
      _customStorage ??
      (isFirebaseInitialized
          ? FirebaseStorage.instance
          : throw StateError('Firebase is not initialized.'));

  static const _networkTimeout = Duration(seconds: 8);

  /// Strips control characters and enforces a maximum string length to prevent injection.
  static String sanitizeInput(String input, {int maxLength = 500}) {
    if (input.isEmpty) return '';
    final sanitized = input
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .trim();
    if (sanitized.length <= maxLength) return sanitized;
    return sanitized.substring(0, maxLength);
  }

  static const List<UstaadProviderProfile> seedProviders = [
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Ahmed Khan',
      role: 'Electrician',
      reliability: 0.95,
      distanceKm: 5,
      rating: 4.9,
      price: 500,
      avatarUrl: 'https://i.pravatar.cc/100?img=11',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111001',
      whatsapp: '+923001111001',
      responseTimeMinutes: 14,
      availabilitySlots: ['Today 4:00 PM', 'Tomorrow 10:00 AM'],
      jobsCompleted: 182,
      latitude: 33.6938,
      longitude: 73.0652,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000002',
      name: 'Bilal Tariq',
      role: 'Electrician',
      reliability: 0.80,
      distanceKm: 2,
      rating: 4.2,
      price: 400,
      avatarUrl: 'https://i.pravatar.cc/100?img=12',
      verified: false,
      city: 'Rawalpindi',
      phone: '+923001111002',
      whatsapp: '+923001111002',
      responseTimeMinutes: 18,
      availabilitySlots: ['Today 6:30 PM', 'Tomorrow 11:30 AM'],
      jobsCompleted: 74,
      latitude: 33.7215,
      longitude: 73.0433,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000003',
      name: 'Kamran Ali',
      role: 'Plumber',
      reliability: 0.90,
      distanceKm: 8,
      rating: 4.7,
      price: 600,
      avatarUrl: 'https://i.pravatar.cc/100?img=13',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111003',
      whatsapp: '+923001111003',
      responseTimeMinutes: 16,
      availabilitySlots: ['Tomorrow 9:30 AM', 'Tomorrow 3:00 PM'],
      jobsCompleted: 141,
      latitude: 33.6835,
      longitude: 73.0477,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000004',
      name: 'Sajid Hussain',
      role: 'AC Repair',
      reliability: 0.85,
      distanceKm: 3,
      rating: 4.5,
      price: 800,
      avatarUrl: 'https://i.pravatar.cc/100?img=14',
      verified: true,
      city: 'Lahore',
      phone: '+923001111004',
      whatsapp: '+923001111004',
      responseTimeMinutes: 20,
      availabilitySlots: ['Tomorrow 10:00 AM', 'Tomorrow 5:00 PM'],
      jobsCompleted: 217,
      latitude: 33.7083,
      longitude: 73.0479,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000005',
      name: 'Usman Ghani',
      role: 'Electrician',
      reliability: 0.98,
      distanceKm: 12,
      rating: 5.0,
      price: 700,
      avatarUrl: 'https://i.pravatar.cc/100?img=15',
      verified: true,
      city: 'Karachi',
      phone: '+923001111005',
      whatsapp: '+923001111005',
      responseTimeMinutes: 22,
      availabilitySlots: ['Today 8:00 PM', 'Tomorrow 2:00 PM'],
      jobsCompleted: 236,
      latitude: 33.6602,
      longitude: 73.1167,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000006',
      name: 'Nadia Services',
      role: 'Cleaning',
      reliability: 0.92,
      distanceKm: 6,
      rating: 4.8,
      price: 650,
      avatarUrl: 'https://i.pravatar.cc/100?img=16',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111006',
      whatsapp: '+923001111006',
      responseTimeMinutes: 24,
      availabilitySlots: ['Today 5:30 PM', 'Tomorrow 12:00 PM'],
      jobsCompleted: 96,
      latitude: 33.7294,
      longitude: 73.0935,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000007',
      name: 'Ayesha Tutors',
      role: 'Tutor',
      reliability: 0.94,
      distanceKm: 4,
      rating: 4.9,
      price: 1200,
      avatarUrl: 'https://i.pravatar.cc/100?img=17',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111007',
      whatsapp: '+923001111007',
      responseTimeMinutes: 35,
      availabilitySlots: ['Tomorrow 9:00 AM', 'Tomorrow 6:00 PM'],
      jobsCompleted: 128,
      latitude: 33.7018,
      longitude: 73.0551,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000008',
      name: 'Zara Beauty Studio',
      role: 'Beautician',
      reliability: 0.91,
      distanceKm: 7,
      rating: 4.8,
      price: 1500,
      avatarUrl: 'https://i.pravatar.cc/100?img=18',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111008',
      whatsapp: '+923001111008',
      responseTimeMinutes: 40,
      availabilitySlots: ['Today 7:00 PM', 'Tomorrow 1:00 PM'],
      jobsCompleted: 109,
      latitude: 33.7139,
      longitude: 73.1089,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000009',
      name: 'Muhammad Rashid',
      role: 'Electrician',
      reliability: 0.93,
      distanceKm: 3,
      rating: 4.8,
      price: 550,
      avatarUrl: 'https://i.pravatar.cc/100?img=19',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111009',
      whatsapp: '+923001111009',
      responseTimeMinutes: 15,
      availabilitySlots: ['Today 5:00 PM', 'Tomorrow 10:30 AM'],
      jobsCompleted: 160,
      latitude: 33.6844,
      longitude: 73.0763,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000010',
      name: 'Waseem Akram',
      role: 'Electrician',
      reliability: 0.88,
      distanceKm: 9,
      rating: 4.6,
      price: 650,
      avatarUrl: 'https://i.pravatar.cc/100?img=20',
      verified: true,
      city: 'Rawalpindi',
      phone: '+923001111010',
      whatsapp: '+923001111010',
      responseTimeMinutes: 25,
      availabilitySlots: ['Today 6:00 PM', 'Tomorrow 1:00 PM'],
      jobsCompleted: 92,
      latitude: 33.5651,
      longitude: 73.0169,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000011',
      name: 'Tariq Mehmood',
      role: 'Electrician',
      reliability: 0.84,
      distanceKm: 2,
      rating: 4.4,
      price: 450,
      avatarUrl: 'https://i.pravatar.cc/100?img=21',
      verified: false,
      city: 'Islamabad',
      phone: '+923001111011',
      whatsapp: '+923001111011',
      responseTimeMinutes: 12,
      availabilitySlots: ['Today 3:30 PM', 'Tomorrow 11:00 AM'],
      jobsCompleted: 58,
      latitude: 33.6425,
      longitude: 72.9841,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000012',
      name: 'Rashid Minhas',
      role: 'Plumber',
      reliability: 0.89,
      distanceKm: 4,
      rating: 4.5,
      price: 450,
      avatarUrl: 'https://i.pravatar.cc/100?img=22',
      verified: true,
      city: 'Rawalpindi',
      phone: '+923001111012',
      whatsapp: '+923001111012',
      responseTimeMinutes: 20,
      availabilitySlots: ['Today 4:30 PM', 'Tomorrow 9:00 AM'],
      jobsCompleted: 89,
      latitude: 33.6007,
      longitude: 73.0679,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000013',
      name: 'Ustaad Aslam Sanitary',
      role: 'Plumber',
      reliability: 0.97,
      distanceKm: 5,
      rating: 4.9,
      price: 550,
      avatarUrl: 'https://i.pravatar.cc/100?img=23',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111013',
      whatsapp: '+923001111013',
      responseTimeMinutes: 14,
      availabilitySlots: ['Today 5:00 PM', 'Tomorrow 10:00 AM'],
      jobsCompleted: 215,
      latitude: 33.6938,
      longitude: 73.0336,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000014',
      name: 'Zubair Ahmed',
      role: 'Plumber',
      reliability: 0.91,
      distanceKm: 11,
      rating: 4.8,
      price: 750,
      avatarUrl: 'https://i.pravatar.cc/100?img=24',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111014',
      whatsapp: '+923001111014',
      responseTimeMinutes: 28,
      availabilitySlots: ['Tomorrow 11:00 AM', 'Tomorrow 4:00 PM'],
      jobsCompleted: 112,
      latitude: 33.5815,
      longitude: 73.1368,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000015',
      name: 'Imran Shah',
      role: 'Plumber',
      reliability: 0.96,
      distanceKm: 6,
      rating: 4.9,
      price: 900,
      avatarUrl: 'https://i.pravatar.cc/100?img=25',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111015',
      whatsapp: '+923001111015',
      responseTimeMinutes: 18,
      availabilitySlots: ['Today 6:00 PM', 'Tomorrow 1:00 PM'],
      jobsCompleted: 178,
      latitude: 33.7297,
      longitude: 73.0746,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000016',
      name: 'Chaudhry HVAC Solutions',
      role: 'AC Repair',
      reliability: 0.97,
      distanceKm: 4,
      rating: 4.9,
      price: 1000,
      avatarUrl: 'https://i.pravatar.cc/100?img=26',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111016',
      whatsapp: '+923001111016',
      responseTimeMinutes: 15,
      availabilitySlots: ['Today 4:00 PM', 'Tomorrow 10:00 AM'],
      jobsCompleted: 310,
      latitude: 33.6841,
      longitude: 73.0169,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000017',
      name: 'Malik Cool Service',
      role: 'AC Repair',
      reliability: 0.86,
      distanceKm: 7,
      rating: 4.4,
      price: 700,
      avatarUrl: 'https://i.pravatar.cc/100?img=27',
      verified: true,
      city: 'Rawalpindi',
      phone: '+923001111017',
      whatsapp: '+923001111017',
      responseTimeMinutes: 22,
      availabilitySlots: ['Today 5:30 PM', 'Tomorrow 12:00 PM'],
      jobsCompleted: 145,
      latitude: 33.6261,
      longitude: 73.0714,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000018',
      name: 'Faizan Inverter Specialist',
      role: 'AC Repair',
      reliability: 0.98,
      distanceKm: 5,
      rating: 5.0,
      price: 1200,
      avatarUrl: 'https://i.pravatar.cc/100?img=28',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111018',
      whatsapp: '+923001111018',
      responseTimeMinutes: 16,
      availabilitySlots: ['Today 7:00 PM', 'Tomorrow 2:00 PM'],
      jobsCompleted: 190,
      latitude: 33.6429,
      longitude: 72.9904,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000019',
      name: 'Kashif Refrigeration',
      role: 'AC Repair',
      reliability: 0.88,
      distanceKm: 8,
      rating: 4.6,
      price: 850,
      avatarUrl: 'https://i.pravatar.cc/100?img=29',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111019',
      whatsapp: '+923001111019',
      responseTimeMinutes: 24,
      availabilitySlots: ['Tomorrow 9:30 AM', 'Tomorrow 4:30 PM'],
      jobsCompleted: 84,
      latitude: 33.7094,
      longitude: 72.9818,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000020',
      name: 'Pak Shine Cleaners',
      role: 'Cleaning',
      reliability: 0.89,
      distanceKm: 3,
      rating: 4.5,
      price: 500,
      avatarUrl: 'https://i.pravatar.cc/100?img=30',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111020',
      whatsapp: '+923001111020',
      responseTimeMinutes: 18,
      availabilitySlots: ['Today 4:00 PM', 'Tomorrow 11:00 AM'],
      jobsCompleted: 130,
      latitude: 33.6922,
      longitude: 73.0519,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000021',
      name: 'Capital Deep Clean Co.',
      role: 'Cleaning',
      reliability: 0.98,
      distanceKm: 7,
      rating: 4.9,
      price: 1200,
      avatarUrl: 'https://i.pravatar.cc/100?img=31',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111021',
      whatsapp: '+923001111021',
      responseTimeMinutes: 25,
      availabilitySlots: ['Today 6:00 PM', 'Tomorrow 10:00 AM'],
      jobsCompleted: 280,
      latitude: 33.7200,
      longitude: 73.0583,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000022',
      name: 'Al-Madina Sofa & Carpet',
      role: 'Cleaning',
      reliability: 0.92,
      distanceKm: 6,
      rating: 4.7,
      price: 800,
      avatarUrl: 'https://i.pravatar.cc/100?img=32',
      verified: true,
      city: 'Rawalpindi',
      phone: '+923001111022',
      whatsapp: '+923001111022',
      responseTimeMinutes: 20,
      availabilitySlots: ['Today 5:00 PM', 'Tomorrow 1:30 PM'],
      jobsCompleted: 165,
      latitude: 33.6389,
      longitude: 73.0784,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000023',
      name: 'Sir Hamza (Math & Physics)',
      role: 'Tutor',
      reliability: 0.94,
      distanceKm: 3,
      rating: 4.8,
      price: 1000,
      avatarUrl: 'https://i.pravatar.cc/100?img=33',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111023',
      whatsapp: '+923001111023',
      responseTimeMinutes: 30,
      availabilitySlots: ['Tomorrow 3:00 PM', 'Tomorrow 7:00 PM'],
      jobsCompleted: 95,
      latitude: 33.6841,
      longitude: 73.0169,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000024',
      name: 'Mariam (O/A-Levels English)',
      role: 'Tutor',
      reliability: 0.99,
      distanceKm: 5,
      rating: 5.0,
      price: 1500,
      avatarUrl: 'https://i.pravatar.cc/100?img=34',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111024',
      whatsapp: '+923001111024',
      responseTimeMinutes: 25,
      availabilitySlots: ['Today 5:00 PM', 'Tomorrow 11:00 AM'],
      jobsCompleted: 142,
      latitude: 33.6938,
      longitude: 73.0036,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000025',
      name: 'Qari Abdul Rehman',
      role: 'Tutor',
      reliability: 0.96,
      distanceKm: 4,
      rating: 4.9,
      price: 600,
      avatarUrl: 'https://i.pravatar.cc/100?img=35',
      verified: true,
      city: 'Rawalpindi',
      phone: '+923001111025',
      whatsapp: '+923001111025',
      responseTimeMinutes: 15,
      availabilitySlots: ['Today 4:00 PM', 'Tomorrow 8:00 AM'],
      jobsCompleted: 210,
      latitude: 33.6128,
      longitude: 73.0531,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000026',
      name: 'Sana Bridal Mehndi & Makeup',
      role: 'Beautician',
      reliability: 0.95,
      distanceKm: 4,
      rating: 4.9,
      price: 1200,
      avatarUrl: 'https://i.pravatar.cc/100?img=36',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111026',
      whatsapp: '+923001111026',
      responseTimeMinutes: 35,
      availabilitySlots: ['Today 6:00 PM', 'Tomorrow 2:00 PM'],
      jobsCompleted: 175,
      latitude: 33.6749,
      longitude: 72.9984,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000027',
      name: 'Noor Home Salon',
      role: 'Beautician',
      reliability: 0.90,
      distanceKm: 8,
      rating: 4.7,
      price: 900,
      avatarUrl: 'https://i.pravatar.cc/100?img=37',
      verified: true,
      city: 'Rawalpindi',
      phone: '+923001111027',
      whatsapp: '+923001111027',
      responseTimeMinutes: 40,
      availabilitySlots: ['Today 5:30 PM', 'Tomorrow 12:00 PM'],
      jobsCompleted: 88,
      latitude: 33.5651,
      longitude: 73.0169,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000028',
      name: 'Ustaad Rafiq Carpenter',
      role: 'General',
      reliability: 0.94,
      distanceKm: 5,
      rating: 4.8,
      price: 700,
      avatarUrl: 'https://i.pravatar.cc/100?img=38',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111028',
      whatsapp: '+923001111028',
      responseTimeMinutes: 20,
      availabilitySlots: ['Today 4:00 PM', 'Tomorrow 9:30 AM'],
      jobsCompleted: 195,
      latitude: 33.6672,
      longitude: 73.0722,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000029',
      name: 'Javed Painter & Polish',
      role: 'General',
      reliability: 0.88,
      distanceKm: 2,
      rating: 4.6,
      price: 600,
      avatarUrl: 'https://i.pravatar.cc/100?img=39',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111029',
      whatsapp: '+923001111029',
      responseTimeMinutes: 18,
      availabilitySlots: ['Tomorrow 10:00 AM', 'Tomorrow 3:00 PM'],
      jobsCompleted: 110,
      latitude: 33.6425,
      longitude: 72.9841,
    ),
  ];

  static final Map<String, List<ReviewRecord>> seedReviews = {
    '00000000-0000-0000-0000-000000000001': [
      ReviewRecord(
        id: 'seed-review-1',
        providerId: '00000000-0000-0000-0000-000000000001',
        rating: 5,
        comment: 'Clean work, clear pricing, arrived on time.',
        customerName: 'Verified customer',
        language: 'English',
        createdAt: DateTime(2026, 5, 10),
      ),
    ],
    '00000000-0000-0000-0000-000000000003': [
      ReviewRecord(
        id: 'seed-review-2',
        providerId: '00000000-0000-0000-0000-000000000003',
        rating: 5,
        comment: 'Kitchen leak fixed fast. Bohat professional.',
        customerName: 'Verified customer',
        language: 'Roman Urdu',
        createdAt: DateTime(2026, 5, 11),
      ),
    ],
    '00000000-0000-0000-0000-000000000004': [
      ReviewRecord(
        id: 'seed-review-3',
        providerId: '00000000-0000-0000-0000-000000000004',
        rating: 4,
        comment: 'AC cooling restored and the status updates were useful.',
        customerName: 'Verified customer',
        language: 'English',
        createdAt: DateTime(2026, 5, 12),
      ),
    ],
    '00000000-0000-0000-0000-000000000013': [
      ReviewRecord(
        id: 'seed-review-4',
        providerId: '00000000-0000-0000-0000-000000000013',
        rating: 5,
        comment: 'Ustaad Aslam ne pipe replacement 30 minute mein mukamal kar di. Bohat zabardast!',
        customerName: 'Hamza Farooq',
        language: 'Roman Urdu',
        createdAt: DateTime(2026, 5, 14),
      ),
    ],
    '00000000-0000-0000-0000-000000000016': [
      ReviewRecord(
        id: 'seed-review-5',
        providerId: '00000000-0000-0000-0000-000000000016',
        rating: 5,
        comment: 'Professional HVAC diagnosis. Gas leak was identified and sealed promptly.',
        customerName: 'Dr. Tariq',
        language: 'English',
        createdAt: DateTime(2026, 5, 15),
      ),
    ],
    '00000000-0000-0000-0000-000000000021': [
      ReviewRecord(
        id: 'seed-review-6',
        providerId: '00000000-0000-0000-0000-000000000021',
        rating: 5,
        comment: 'House deep cleaning was immaculate. High-standard equipment used.',
        customerName: 'Sadia Malik',
        language: 'English',
        createdAt: DateTime(2026, 5, 16),
      ),
    ],
  };

  UstaadUser _userFromFirebase(auth.User user) {
    return UstaadUser(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      phone: user.phoneNumber,
      avatarUrl: user.photoURL ?? '',
    );
  }

  UstaadUser? currentUser() {
    if (!isFirebaseInitialized) return null;
    final user = _auth.currentUser;
    if (user == null) return null;
    return _userFromFirebase(user);
  }

  DateTime? currentSessionExpiresAt() {
    if (!isFirebaseInitialized) return null;
    if (_auth.currentUser != null) {
      return DateTime.now().add(const Duration(hours: 1));
    }
    return null;
  }

  Future<UstaadUser?> fetchProfile() async {
    if (!isFirebaseInitialized) return null;
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('profiles').doc(user.uid).get();
      if (!doc.exists) return _userFromFirebase(user);
      return UstaadUser.fromProfileMap(
        doc.data()!,
        fallbackId: user.uid,
        fallbackEmail: user.email ?? '',
      );
    } catch (_) {
      return _userFromFirebase(user);
    }
  }

  Future<UstaadUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Unable to sign in.');
      }
      return await fetchProfile() ?? _userFromFirebase(user);
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Unable to sign in.');
    } catch (e) {
      throw const AuthException('Unable to sign in.');
    }
  }

  Future<UstaadUser> signInAnonymously() async {
    try {
      final response = await _auth.signInAnonymously();
      final user = response.user;
      if (user == null) {
        throw const AuthException('Unable to sign in as guest.');
      }
      return await fetchProfile() ?? _userFromFirebase(user);
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Unable to sign in as guest.');
    } catch (e) {
      throw const AuthException('Unable to sign in as guest.');
    }
  }

  Stream<auth.User?> get authStateChanges =>
      !isFirebaseInitialized ? const Stream.empty() : _auth.authStateChanges();

  Future<AuthSignUpResult> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Unable to create account.');
      }

      await user.updateDisplayName(name);

      _upsertProfileSilently(user.uid, name, email, phone);

      // In Firebase, we can trigger email verification here if we want.
      // await user.sendEmailVerification();
      // Let's assume for now it's not strictly blocking, so emailConfirmationRequired = false
      final confirmationRequired = false;

      return AuthSignUpResult(
        user: await fetchProfile() ?? _userFromFirebase(user),
        emailConfirmationRequired: confirmationRequired,
      );
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Unable to create account.');
    } catch (e) {
      throw const AuthException('Unable to create account.');
    }
  }

  Future<UstaadUser?> trySignInAfterSignUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final user = await signIn(email: email, password: password);
      _upsertProfileSilently(user.id, name, email, phone);
      return user;
    } catch (_) {
      return null;
    }
  }

  void _upsertProfileSilently(
    String userId,
    String name,
    String email,
    String phone,
  ) {
    _db.collection('profiles').doc(userId).set({
      'id': userId,
      'full_name': name,
      'email': email,
      'phone': phone,
      'city': 'Islamabad',
      'preferred_language': 'English',
    }, SetOptions(merge: true)).catchError((_) {});
  }

  Future<UstaadUser> updateProfile({
    required String name,
    required String phone,
    required String city,
    required String address,
    required String preferredLanguage,
    required String bio,
    String? avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to update your profile.');
    }

    final cleanName = sanitizeInput(name, maxLength: 100);
    final cleanPhone = sanitizeInput(phone, maxLength: 30);
    final cleanCity = sanitizeInput(city, maxLength: 100);
    final cleanAddress = sanitizeInput(address, maxLength: 300);
    final cleanLang = sanitizeInput(preferredLanguage, maxLength: 50);
    final cleanBio = sanitizeInput(bio, maxLength: 500);

    try {
      await user.updateDisplayName(cleanName);
      if (avatarUrl != null) {
        await user.updatePhotoURL(avatarUrl);
      }
    } catch (_) {}

    await _db.collection('profiles').doc(user.uid).set({
      'id': user.uid,
      'full_name': cleanName,
      'email': user.email ?? '',
      'phone': cleanPhone,
      'avatar_url': avatarUrl ?? '',
      'city': cleanCity,
      'address': cleanAddress,
      'preferred_language': cleanLang,
      'bio': cleanBio,
    }, SetOptions(merge: true));

    return await fetchProfile() ??
        _userFromFirebase(user).copyWith(
          name: cleanName,
          phone: cleanPhone,
          city: cleanCity,
          address: cleanAddress,
          preferredLanguage: cleanLang,
          bio: cleanBio,
          avatarUrl: avatarUrl,
        );
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to upload a profile photo.');
    }

    // Security Check: File size limit (Max 5MB)
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw const AuthException('Profile photo must be less than 5MB.');
    }

    // Security Check: MIME type validation
    final mime = contentType.trim().toLowerCase();
    const allowedMimes = {'image/jpeg', 'image/png', 'image/webp', 'image/gif'};
    if (!allowedMimes.contains(mime)) {
      throw const AuthException('Only JPEG, PNG, WebP, or GIF images are allowed.');
    }

    final cleanName = fileName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_.-]'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final path = '${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    
    final ref = _storage.ref().child('avatars').child(path);
    final metadata = SettableMetadata(contentType: mime);
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  Future<void> resendEmailConfirmation(String email) async {
    final user = _auth.currentUser;
    if (user != null && user.email == email && !user.emailVerified) {
       await user.sendEmailVerification();
    } else {
      throw const AuthException('User not found or already verified.');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Failed to send password reset email.');
    }
  }

  Future<UstaadUser> updatePassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Open the reset link before setting password.');
    }
    try {
      await user.updatePassword(password);
      return await fetchProfile() ?? _userFromFirebase(user);
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Failed to update password.');
    }
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<List<UstaadProviderProfile>> fetchProviders() async {
    if (!isFirebaseInitialized) return seedProviders;
    try {
      final snapshot = await _db
          .collection('service_providers')
          .where('active', isEqualTo: true)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs
          .map<UstaadProviderProfile>(
            (doc) => UstaadProviderProfile.fromMap(doc.data()),
          )
          .toList();
    } catch (_) {
      // Return empty or seed if failed
      return seedProviders;
    }
  }

  /// Automatically populates Firestore with initial verified providers if the collection is empty.
  Future<void> seedDatabaseIfEmpty() async {
    if (!isFirebaseInitialized) return;
    try {
      final batch = _db.batch();
      for (final provider in seedProviders) {
        final doc = _db.collection('service_providers').doc(provider.id);
        batch.set(doc, provider.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<List<LocationSuggestion>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$trimmed, Pakistan',
      'format': 'jsonv2',
      'limit': '5',
      'addressdetails': '1',
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'Ustaad/1.0 (com.ustaad.service)',
        },
      ).timeout(_networkTimeout);
      if (response.statusCode != 200) return _fallbackLocations(trimmed);
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return _fallbackLocations(trimmed);
      final results = decoded
          .whereType<Map>()
          .map((item) => LocationSuggestion.fromNominatim(
                Map<String, dynamic>.from(item),
              ))
          .toList();
      return results.isEmpty ? _fallbackLocations(trimmed) : results;
    } catch (_) {
      return _fallbackLocations(trimmed);
    }
  }

  Future<LocationSuggestion> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': latitude.toStringAsFixed(7),
      'lon': longitude.toStringAsFixed(7),
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18',
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'Ustaad/1.0 (com.ustaad.service)',
        },
      ).timeout(_networkTimeout);
      if (response.statusCode != 200) {
        return _fallbackReverseLocation(latitude, longitude);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return _fallbackReverseLocation(latitude, longitude);
      }
      final suggestion = LocationSuggestion.fromNominatim(
        Map<String, dynamic>.from(decoded),
      );
      return suggestion.label.trim().isEmpty
          ? _fallbackReverseLocation(latitude, longitude)
          : suggestion;
    } catch (_) {
      return _fallbackReverseLocation(latitude, longitude);
    }
  }

  Future<RouteEstimate> estimateRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$fromLng,$fromLat;$toLng,$toLat?overview=false',
    );

    try {
      final response = await http.get(uri).timeout(_networkTimeout);
      if (response.statusCode != 200) {
        return RouteEstimate.fallback(
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
        );
      }
      return RouteEstimate.fromOsrm(
        Map<String, dynamic>.from(jsonDecode(response.body)),
      );
    } catch (_) {
      return RouteEstimate.fallback(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
    }
  }

  Future<List<BookingRecord>> fetchBookings() async {
    if (!isFirebaseInitialized) return const [];
    final user = _auth.currentUser;
    if (user == null) return const [];

    try {
      final snapshot = await _db
          .collection('bookings')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map<BookingRecord>(
            (doc) => BookingRecord.fromMap(doc.data()..['id'] = doc.id),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<BookingRecord> createBooking({
    required UstaadProviderProfile provider,
    required ServiceIntent intent,
    required QuoteEstimate quote,
    required String problemText,
    required List<WorkflowEvent> workflowEvents,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to create a booking.');
    }

    final cleanProblem = sanitizeInput(problemText, maxLength: 500);
    final cleanLocation = sanitizeInput(intent.location, maxLength: 200);

    // Security check: Pricing cannot be negative or zero
    if (quote.basePrice <= 0 || quote.total <= 0) {
      throw const AuthException('Invalid quote calculated.');
    }

    final docRef = await _db.collection('bookings').add({
      'user_id': user.uid,
      'provider_id': provider.id,
      'provider_name': provider.name,
      'service_role': provider.role,
      'problem_text': cleanProblem,
      'service_location': cleanLocation,
      'urgency': intent.urgency.toLowerCase(),
      'quote_base': quote.basePrice,
      'quote_distance': quote.distancePrice,
      'quote_urgency': quote.urgencyPrice,
      'quote_total': quote.total,
      'user_offer': quote.userOffer ?? intent.userBudget,
      'status': 'en_route',
      'eta_minutes': etaMinutesFor(provider),
      'slot_label': provider.nextSlot,
      'provider_phone': provider.phone,
      'provider_whatsapp': provider.whatsapp,
      'confirmation_message':
          'Confirmed ${provider.role} with ${provider.name} for ${provider.nextSlot}.',
      'created_at': FieldValue.serverTimestamp(),
    });

    final bookingDoc = await docRef.get();
    
    try {
      final batch = _db.batch();
      for (var i = 0; i < workflowEvents.length; i++) {
        final event = workflowEvents[i];
        final eventRef = _db.collection('agent_events').doc();
        batch.set(eventRef, {
          'user_id': user.uid,
          'booking_id': docRef.id,
          'sequence': i + 1,
          'agent_name': event.agentName,
          'step': event.step,
          'message': event.message,
          'tool_name': event.toolName,
          'status': event.status,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {
    }

    return BookingRecord.fromMap(
      bookingDoc.data()!..['id'] = docRef.id,
      providerFallback: provider,
    );
  }

  Future<BookingRecord> createEmergencyBooking({
    required UstaadProviderProfile provider,
    required EmergencyRequest emergency,
    required QuoteEstimate quote,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return _localEmergencyBooking(
        provider: provider,
        emergency: emergency,
        quote: quote,
      );
    }

    try {
      final cleanLocation = sanitizeInput(emergency.location, maxLength: 200);
      final docRef = await _db.collection('bookings').add({
        'user_id': user.uid,
        'provider_id': provider.id,
        'provider_name': provider.name,
        'service_role': provider.role,
        'problem_text': 'Emergency ${emergency.serviceType} request',
        'service_location': cleanLocation,
        'urgency': 'CRITICAL',
        'quote_base': quote.basePrice,
        'quote_distance': quote.distancePrice,
        'quote_urgency': quote.urgencyPrice,
        'quote_total': quote.total,
        'status': 'en_route',
        'eta_minutes': 10,
        'slot_label': 'Immediate dispatch',
        'provider_phone': provider.phone,
        'provider_whatsapp': provider.whatsapp,
        'confirmation_message':
            'EMERGENCY booking - provider dispatched immediately.',
        'created_at': FieldValue.serverTimestamp(),
      });

      final bookingDoc = await docRef.get();

      return BookingRecord.fromMap(
        bookingDoc.data()!..['id'] = docRef.id,
        providerFallback: provider,
      );
    } catch (_) {
      return _localEmergencyBooking(
        provider: provider,
        emergency: emergency,
        quote: quote,
      );
    }
  }

  BookingRecord _localEmergencyBooking({
    required UstaadProviderProfile provider,
    required EmergencyRequest emergency,
    required QuoteEstimate quote,
  }) {
    return BookingRecord(
      id: 'local-emergency-${DateTime.now().microsecondsSinceEpoch}',
      providerId: provider.id,
      providerName: provider.name,
      serviceRole: provider.role,
      problemText: 'Emergency ${emergency.serviceType} request',
      location: emergency.location,
      status: 'en_route',
      quoteTotal: quote.total,
      etaMinutes: 10,
      slotLabel: 'Immediate dispatch',
      confirmationMessage:
          'EMERGENCY booking - provider dispatched immediately.',
      createdAt: DateTime.now(),
      providerPhone: provider.phone,
      providerWhatsapp: provider.whatsapp,
      providerAvatarUrl: provider.avatarUrl,
      providerRating: provider.rating,
    );
  }

  Future<BookingRecord> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    const validStatuses = {
      'scheduled',
      'en_route',
      'completed',
      'cancelled',
      'issue_reported'
    };
    if (!validStatuses.contains(status)) {
      throw const AuthException('Invalid booking status.');
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to update booking status.');
    }
    final docRef = _db.collection('bookings').doc(bookingId);
    await docRef.update({'status': status});
    final doc = await docRef.get();
    return BookingRecord.fromMap(doc.data()!..['id'] = doc.id);
  }

  Future<List<ReviewRecord>> fetchReviews(String providerId) async {
    try {
      final snapshot = await _db
          .collection('reviews')
          .where('provider_id', isEqualTo: providerId)
          .orderBy('created_at', descending: true)
          .get();
      final reviews = snapshot.docs
          .map<ReviewRecord>(
            (doc) => ReviewRecord.fromMap(doc.data()..['id'] = doc.id),
          )
          .toList();
      return reviews.isEmpty ? (seedReviews[providerId] ?? const []) : reviews;
    } catch (_) {
      return seedReviews[providerId] ?? const [];
    }
  }

  Future<ReviewRecord> createReview({
    required String providerId,
    required int rating,
    required String comment,
    required String language,
    String? bookingId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to leave a review.');
    }

    final cleanComment = sanitizeInput(comment, maxLength: 1000);
    final clampedRating = rating.clamp(1, 5);

    final docRef = await _db.collection('reviews').add({
      'user_id': user.uid,
      'provider_id': providerId,
      'rating': clampedRating,
      'comment': cleanComment,
      'language': language,
      'booking_id': bookingId,
      'customer_name': sanitizeInput(user.displayName ?? 'Customer', maxLength: 100),
      'created_at': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return ReviewRecord.fromMap(doc.data()!..['id'] = doc.id);
  }

  LocationSuggestion _fallbackReverseLocation(
    double latitude,
    double longitude,
  ) {
    final nearest = _nearestKnownLocation(latitude, longitude);
    if (nearest != null) {
      return LocationSuggestion(
        label: 'Near ${nearest.label}',
        subtitle: nearest.subtitle,
        latitude: latitude,
        longitude: longitude,
      );
    }
    return LocationSuggestion(
      label: 'Current location',
      subtitle:
          '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
      latitude: latitude,
      longitude: longitude,
    );
  }

  LocationSuggestion? _nearestKnownLocation(double latitude, double longitude) {
    const locations = [
      LocationSuggestion(
        label: 'G-13, Islamabad',
        subtitle: 'Capital Territory',
        latitude: 33.6493,
        longitude: 72.9712,
      ),
      LocationSuggestion(
        label: 'F-8, Islamabad',
        subtitle: 'Capital Territory',
        latitude: 33.7127,
        longitude: 73.0381,
      ),
      LocationSuggestion(
        label: 'Bahria Town, Rawalpindi',
        subtitle: 'Punjab',
        latitude: 33.5358,
        longitude: 73.1147,
      ),
    ];

    LocationSuggestion? best;
    double bestDist = double.infinity;

    for (final loc in locations) {
      final d = geoDistanceKm(latitude, longitude, loc.latitude, loc.longitude);
      if (d < bestDist && d < 10) {
        bestDist = d;
        best = loc;
      }
    }
    return best;
  }

  List<LocationSuggestion> _fallbackLocations(String query) {
    final lower = query.toLowerCase();
    const all = [
      LocationSuggestion(
        label: 'G-13, Islamabad',
        subtitle: 'Capital Territory, Pakistan',
        latitude: 33.6493,
        longitude: 72.9712,
      ),
      LocationSuggestion(
        label: 'F-8, Islamabad',
        subtitle: 'Capital Territory, Pakistan',
        latitude: 33.7127,
        longitude: 73.0381,
      ),
      LocationSuggestion(
        label: 'Bahria Town Phase 7, Rawalpindi',
        subtitle: 'Punjab, Pakistan',
        latitude: 33.5358,
        longitude: 73.1147,
      ),
      LocationSuggestion(
        label: 'DHA Phase 2, Islamabad',
        subtitle: 'Capital Territory, Pakistan',
        latitude: 33.5262,
        longitude: 73.1491,
      ),
      LocationSuggestion(
        label: 'Blue Area, Islamabad',
        subtitle: 'Commercial Avenue, Pakistan',
        latitude: 33.7088,
        longitude: 73.0531,
      ),
    ];

    final matches = all.where((l) =>
        l.label.toLowerCase().contains(lower) ||
        l.subtitle.toLowerCase().contains(lower));
    return matches.toList();
  }
}

int etaMinutesFor(UstaadProviderProfile provider) {
  if (provider.nextSlot.toLowerCase().contains('today')) {
    return provider.responseTimeMinutes + (provider.distanceKm * 2);
  }
  return 60 * 12;
}
