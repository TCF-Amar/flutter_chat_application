class ChatsEntity {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String? senderPhotoUrl;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final String? mediaUrl;
  final int? mediaSize;
  final MessageStatus status;
  final bool isEdited;
  final String? replyToMessageId;
  final String? replyToSenderName;
  final String? replyToText;
  final MessageType? replyToType;

  ChatsEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    this.senderPhotoUrl,
    required this.text,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.mediaUrl,
    this.mediaSize,
    this.status = MessageStatus.sent,
    this.isEdited = false,
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToText,
    this.replyToType,
  });
}

enum MessageType { text, image, video, audio, document, location }

enum MessageStatus { sending, sent, delivered, read }

class ChatMetadataEntity {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;
  final DateTime createdAt;
  final ChatType type;
  final bool isEdited;

  ChatMetadataEntity({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    required this.createdAt,
    this.type = ChatType.direct,
    this.isEdited = false,
  });
}

enum ChatType { direct, group }
