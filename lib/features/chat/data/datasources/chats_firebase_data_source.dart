import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/chat/data/models/chats_model.dart';
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
    });
    // send notification
    // await NotificationServices.instance.sendNotificationToUser(
    //   userId: message.receiverId,
    //   title: message.senderName,
    //   body: message.text,
    // );
  }

  // get messages
  Stream<List<ChatsModel>> getMessages(String chatId) {
    return fs.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatsModel.fromJson(doc.data()))
              .toList();
        });
  }

  // mark as read
  Future<void> markAsRead({
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
          'isRead': true, // Optionally mark as read if logic dictates
        });
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
}
