import 'package:equatable/equatable.dart';

class ContactsEntity extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final bool stared;
  final String? chatId;
  final DateTime? createdAt;

  const ContactsEntity({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.stared = false,
    this.chatId,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, email, phoneNumber, photoUrl, stared, chatId, createdAt];

  // copy
  ContactsEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    bool? stared,
    String? chatId,
    DateTime? createdAt,
  }) {
    return ContactsEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      stared: stared ?? this.stared,
      chatId: chatId ?? this.chatId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
