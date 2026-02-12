/*
 * ChatsRemoteDataSourceImpl - Firebase Data Source for Chat Operations
 * 
 * Handles all direct Firebase Firestore operations for chat functionality.
 * 
 * Key Features:
 * - Message CRUD operations (create, read, update, delete)
 * - Real-time message streams
 * - Typing indicators
 * - Read receipts and unread counts
 * - Chat metadata management for both sender and receiver
 * - Notification document creation for FCM
 * 
 * Firestore Structure:
 * - /chats/{chatId}/messages/{messageId} - Individual messages
 * - /users/{userId}/chats/{chatId} - Chat metadata per user
 * - /notifications - Notification queue for FCM
 */

import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/chat/data/models/chats_model.dart';
import 'package:chat_kare/features/chat/data/models/chat_meta_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//* Firebase implementation of chat data source
class ChatsRemoteDataSourceImpl {
  //* Firebase services instance
  final FirebaseServices fs;

  ChatsRemoteDataSourceImpl({required this.fs});

  //* Sends a message and updates chat metadata
  //*
  //* This method performs multiple operations:
  //* 1. Saves message to /chats/{chatId}/messages/{messageId}
  //* 2. Creates notification document for FCM
  //* 3. Updates sender's chat metadata (marks as read, updates last message)
  //* 4. Updates receiver's chat metadata (increments unread count, updates last message)
  //*
  //* The metadata ensures both users see the chat in their chat list with correct info.
  Future<void> sendMessage(ChatsModel message) async {
    // Save message to Firestore
    await fs.firestore
        .collection('chats')
        .doc(message.chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toJson());

    // Create notification document for FCM processing
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

    // Update Chat Metadata for Sender
    // Sender sees the chat with their own message marked as read
    final senderChatRef = fs.firestore
        .collection('users')
        .doc(message.senderId)
        .collection('chats')
        .doc(message.chatId);

    await senderChatRef.set({
      'chatId': message.chatId,
      'receiverId': message.receiverId,
      'receiverName': message.receiverName,
      'receiverPhotoUrl': message.receiverPhotoUrl,
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp,
      'lastMessageSenderId': message.senderId,
      'lastMessageSenderName': message.senderName,
      'lastMessageSenderPhotoUrl': message.senderPhotoUrl,
      'lastMessageType': message.type.name,
      'isRead': true,
      'readBy': [message.senderId],
      'unreadCount': 0, // Sender has read their own message
    }, SetOptions(merge: true));

    // Update Chat Metadata for Receiver
    // Receiver sees the chat with incremented unread count
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
      'lastMessageSenderId': message.senderId,
      'lastMessageSenderName': message.senderName,
      'lastMessageSenderPhotoUrl': message.senderPhotoUrl,
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp,
      'lastMessageType': message.type.name,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  //* Gets real-time stream of messages for a chat
  //*
  //* Messages are ordered by timestamp (newest first) and limited.
  //*
  //* Parameters:
  //* - [chatId]: Unique chat identifier
  //* - [limit]: Maximum number of messages to fetch
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

  //* Marks a message as read by a user
  //*
  //* Updates:
  //* 1. Message document - adds user to readBy array, sets isRead flag
  //* 2. User's chat metadata - decrements unread count
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

  //* Updates typing status for a user in a chat
  //*
  //* Adds or removes user ID from typingUsers array in chat document.
  //* Other users listen to this array to show typing indicators.
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

  //* Gets real-time stream of chat document
  //*
  //* Used to monitor typing users and other chat-level data.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getChatStream(String chatId) {
    return fs.firestore.collection('chats').doc(chatId).snapshots();
  }

  //* Gets real-time count of unread messages for a user in a chat
  //*
  //* Counts messages where user is receiver and isRead is false.
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

  //* Marks all unread messages in a chat as read for a user
  //*
  //* Uses batch write to update multiple messages efficiently.
  //* Also resets unread count in user's chat metadata to 0.
  Future<void> markAllMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    // Find all unread messages for this user
    final query = await fs.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    // Batch update all messages
    final batch = fs.firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();

    // Reset unread count in chat metadata
    await fs.firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .update({'unreadCount': 0});
  }

  //* Gets real-time stream of all chats for a user
  //*
  //* Returns chat metadata ordered by last message time (newest first).
  //* Each metadata contains info about the other participant and last message.
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

  //* Edits a message's text content
  //*
  //* Updates text and sets isEdited flag to true.
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

  //* Deletes a message for a specific user only
  //*
  //* Adds user ID to deletedBy array. Message remains visible to others.
  //* The UI filters out messages where current user is in deletedBy array.
  Future<void> deleteMessageForMe({
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
          'deletedBy': FieldValue.arrayUnion([userId]),
        });
  }

  //* Deletes a message for all participants
  //*
  //* Sets isDeletedForEveryone flag and clears all content.
  //* Only the sender should be able to call this.
  //* The UI shows a "This message was deleted" placeholder.
  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
  }) async {
    await fs.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'isDeletedForEveryone': true,
          'text': '',
          'mediaUrl': null,
          'replyToText': null,
          'replyToMediaUrl': null,
        });
  }
}
