import 'package:chat_kare/features/contacts/domain/entities/contact_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactsModel extends ContactEntity {
  const ContactsModel({
    required super.contactUid,
    required super.name,
    super.starred,
    super.createdAt,
    super.updatedAt,
  });

  // from json
  factory ContactsModel.fromJson(Map<String, dynamic> json) {
    return ContactsModel(
      contactUid: json["contactUid"] ?? json["id"], // backward compatibility
      name: json["name"],
      starred:
          json["starred"] ?? json["stared"] ?? false, // backward compatibility
      createdAt: (json["createdAt"] as Timestamp?)?.toDate(),
      updatedAt: (json["updatedAt"] as Timestamp?)?.toDate(),
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      "contactUid": contactUid,
      "name": name,
      "starred": starred,
      "createdAt": createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      "updatedAt": updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // to entity
  ContactEntity toEntity() {
    return ContactEntity(
      contactUid: contactUid,
      name: name,
      starred: starred,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // from entity
  factory ContactsModel.fromEntity(ContactEntity entity) {
    return ContactsModel(
      contactUid: entity.contactUid,
      name: entity.name,
      starred: entity.starred,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
