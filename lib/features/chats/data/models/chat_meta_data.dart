// chats/{chatId}
class ChatMetadata {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;
  final DateTime createdAt;
  final ChatType type; // direct, group

  ChatMetadata({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    required this.createdAt,
    this.type = ChatType.direct,
  });
}

enum ChatType { direct, group }
