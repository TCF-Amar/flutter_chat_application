class NotificationsModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String senderPhotoUrl;

  NotificationsModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.senderPhotoUrl,
  });

  factory NotificationsModel.fromJson(Map<String, dynamic> json) {
    return NotificationsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverName: json['receiverName'] ?? '',
      senderPhotoUrl: json['senderPhotoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'senderPhotoUrl': senderPhotoUrl,
    };
  }

  NotificationsModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? senderName,
    String? receiverName,
    String? senderPhotoUrl,
  }) {
    return NotificationsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    // Handle Firestore Timestamp
    if (timestamp is Map && timestamp.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    }

    // Handle ISO string
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle DateTime object (already parsed)
    if (timestamp is DateTime) {
      return timestamp;
    }

    return DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationsModel &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.timestamp == timestamp &&
        other.chatId == chatId &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.senderName == senderName &&
        other.receiverName == receiverName &&
        other.senderPhotoUrl == senderPhotoUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        body.hashCode ^
        timestamp.hashCode ^
        chatId.hashCode ^
        senderId.hashCode ^
        receiverId.hashCode ^
        senderName.hashCode ^
        receiverName.hashCode ^
        senderPhotoUrl.hashCode;
  }
}
