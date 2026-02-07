// chats/{chatId}/messages/{messageId}
import 'package:chat_kare/features/chats/domain/entities/chats_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatsModel extends ChatsEntity {
  // final String id;
  // final String chatId;
  // final String senderId;
  // final String senderName;
  // final String? senderPhotoUrl;
  // final String text;
  // final MessageType type;
  // final DateTime timestamp;
  // final bool isRead;
  // final List<String> readBy;
  // final String? mediaUrl;
  // final int? mediaSize;

  ChatsModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.senderName,
    super.senderPhotoUrl,
    required super.text,
    super.type = MessageType.text,
    required super.timestamp,
    super.isRead = false,
    super.readBy = const [],
    super.mediaUrl,
    super.mediaSize,
  });

  factory ChatsModel.fromJson(Map<String, dynamic> json) {
    return ChatsModel(
      id: json["id"],
      chatId: json["chatId"],
      senderId: json["senderId"],
      senderName: json["senderName"],
      senderPhotoUrl: json["senderPhotoUrl"],
      text: json["text"],
      type: MessageType.values.firstWhere((e) => e.name == json["type"]),
      timestamp: (json["timestamp"] as Timestamp).toDate(),
      isRead: json["isRead"],
      readBy: List<String>.from(json["readBy"]),
      mediaUrl: json["mediaUrl"],
      mediaSize: json["mediaSize"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "chatId": chatId,
      "senderId": senderId,
      "senderName": senderName,
      "senderPhotoUrl": senderPhotoUrl,
      "text": text,
      "type": type.name,
      "timestamp": timestamp,
      "isRead": isRead,
      "readBy": readBy,
      "mediaUrl": mediaUrl,
      "mediaSize": mediaSize,
    };
  }

  ChatsEntity toEntity() {
    return ChatsEntity(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      type: type,
      timestamp: timestamp,
      isRead: isRead,
      readBy: readBy,
      mediaUrl: mediaUrl,
      mediaSize: mediaSize,
    );
  }
}
