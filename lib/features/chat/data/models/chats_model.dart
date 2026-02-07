// chats/{chatId}/messages/{messageId}
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatsModel extends ChatsEntity {
  ChatsModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.receiverId,
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
      receiverId: json["receiverId"],
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
      "receiverId": receiverId,
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
      receiverId: receiverId,
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

  // form entity
  factory ChatsModel.fromEntity(ChatsEntity entity) {
    return ChatsModel(
      id: entity.id,
      chatId: entity.chatId,
      senderId: entity.senderId,
      receiverId: entity.receiverId,
      senderName: entity.senderName,
      senderPhotoUrl: entity.senderPhotoUrl,
      text: entity.text,
      type: entity.type,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
      readBy: entity.readBy,
      mediaUrl: entity.mediaUrl,
      mediaSize: entity.mediaSize,
    );
  }
}
