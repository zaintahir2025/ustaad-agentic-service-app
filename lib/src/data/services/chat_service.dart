import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final List<String> readBy;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.readBy = const [],
  });

  factory ChatMessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      readBy: (data['readBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': readBy,
    };
  }
}

/// Industrial In-App Chat Service with real-time Firestore listeners.
class ChatService {
  final FirebaseFirestore _firestore;

  ChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Ensures a chat thread exists between the customer and provider for a booking.
  Future<String> getOrCreateChat({
    required String bookingId,
    required String customerId,
    required String providerId,
  }) async {
    final chatId = 'chat_$bookingId';
    final chatRef = _firestore.collection('chats').doc(chatId);

    final doc = await chatRef.get();
    if (!doc.exists) {
      await chatRef.set({
        'bookingId': bookingId,
        'participants': [customerId, providerId],
        'customerId': customerId,
        'providerId': providerId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  /// Real-time stream of messages in a chat thread.
  Stream<List<ChatMessageModel>> messageStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessageModel.fromDoc(doc)).toList());
  }

  /// Sends a new message in the chat and triggers FCM push notifications.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final batch = _firestore.batch();
    final msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'text': clean,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    });

    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': clean,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Marks unread messages as read by current user.
  Future<void> markAsRead({
    required String chatId,
    required String userId,
  }) async {
    final unread = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      final readBy = (doc.data()['readBy'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      if (!readBy.contains(userId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
    await batch.commit();
  }
}
