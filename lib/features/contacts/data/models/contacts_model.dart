import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactsModel extends ContactsEntity {
  const ContactsModel({
    required super.id,
    required super.name,
    super.email,
    super.phoneNumber,
    super.photoUrl,
    super.stared,
    super.chatId,
    super.createdAt,
  });

  // from json
  factory ContactsModel.fromJson(Map<String, dynamic> json) {
    return ContactsModel(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      phoneNumber: json["phoneNumber"],
      photoUrl: json["photoUrl"],
      stared: json["stared"],
      chatId: json["chatId"],
      createdAt: (json["createdAt"] as Timestamp?)?.toDate(),
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phoneNumber": phoneNumber,
      "photoUrl": photoUrl,
      "stared": stared,
      "chatId": chatId,
      "createdAt": createdAt,
    };
  }

  // to entity
  ContactsEntity toEntity() {
    return ContactsEntity(
      id: id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      stared: stared,
      chatId: chatId,
      createdAt: createdAt,
    );
  }

  // from entity
  factory ContactsModel.fromEntity(ContactsEntity entity) {
    return ContactsModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      photoUrl: entity.photoUrl,
      stared: entity.stared,
      chatId: entity.chatId,
      createdAt: entity.createdAt,
    );
  }
}
