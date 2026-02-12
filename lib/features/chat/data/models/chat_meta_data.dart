import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMetaData {
  final String chatId;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;
  final String? lastMessageSenderPhotoUrl;
  final int unreadCount;

  ChatMetaData({
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.lastMessageSenderPhotoUrl,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderName': lastMessageSenderName,
      'lastMessageSenderPhotoUrl': lastMessageSenderPhotoUrl,
      'unreadCount': unreadCount,
    };
  }

  factory ChatMetaData.fromMap(Map<String, dynamic> map) {
    return ChatMetaData(
      chatId: map['chatId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? 'Unknown',
      receiverPhotoUrl: map['receiverPhotoUrl'],
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageSenderName: map['lastMessageSenderName'],
      lastMessageSenderPhotoUrl: map['lastMessageSenderPhotoUrl'],
      unreadCount: map['unreadCount']?.toInt() ?? 0,
    );
  }
}
