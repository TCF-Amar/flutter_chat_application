import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/chat/data/models/chats_model.dart';
import 'package:chat_kare/features/chat/data/models/chat_meta_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatsRemoteDataSourceImpl {
  final FirebaseServices fs;
  ChatsRemoteDataSourceImpl({required this.fs});

  // send message
  Future<void> sendMessage(ChatsModel message) async {
    await fs.firestore
        .collection('chats')
        .doc(message.chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toJson());

    await fs.firestore.collection('notifications').add({
      'title': 'New Message',
      'body': message.text,
      'timestamp': message.timestamp,
      'chatId': message.chatId,
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'senderName': message.senderName,
      'receiverName': message.receiverName,
      'senderPhotoUrl': message.senderPhotoUrl,
    });
    // send notification
    // await NotificationServices.instance.sendNotificationToUser(
    //   userId: message.receiverId,
    //   title: message.senderName,
    //   body: message.text,
    // );

    // Update Chat Metadata for Sender
    final senderChatRef = fs.firestore
        .collection('users')
        .doc(message.senderId)
        .collection('chats')
        .doc(message.chatId);

    await senderChatRef.set({
      'chatId': message.chatId,
      'receiverId': message.receiverId,
      'receiverName': message.receiverName,
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp,
      'unreadCount': 0, // Sender has read their own message
    }, SetOptions(merge: true));

    // Update Chat Metadata for Receiver
    final receiverChatRef = fs.firestore
        .collection('users')
        .doc(message.receiverId)
        .collection('chats')
        .doc(message.chatId);

    await receiverChatRef.set({
      'chatId': message.chatId,
      'receiverId': message.senderId,
      'receiverName': message.senderName,
      'receiverPhotoUrl': message.senderPhotoUrl,
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // get messages
  Stream<List<ChatsModel>> getMessages(String chatId, int limit) {
    return fs.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .limit(limit)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatsModel.fromJson(doc.data()))
              .toList();
        });
  }

  // mark as read
  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    await fs.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'readBy': FieldValue.arrayUnion([userId]),
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });

    await fs.firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .update({'unreadCount': FieldValue.increment(-1)});
  }

  Future<void> sendTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    await fs.firestore.collection('chats').doc(chatId).set({
      'typingUsers': isTyping
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    }, SetOptions(merge: true));
  }

  // get chat stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getChatStream(String chatId) {
    return fs.firestore.collection('chats').doc(chatId).snapshots();
  }

  Stream<int> getUnreadCountStream(String chatId, String userId) {
    return fs.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAllMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    final query = await fs.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = fs.firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();

    await fs.firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .update({'unreadCount': 0});
  }

  // get chats stream
  Stream<List<ChatMetaData>> getChatsStream(String userId) {
    return fs.firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMetaData.fromMap(doc.data()))
              .toList();
        });
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) async {
    await fs.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'text': text, 'isEdited': true});
  }
}
