import 'package:equatable/equatable.dart';

class ContactEntity extends Equatable {
  final String contactUid;
  final String name;
  final bool starred;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? email;
  final String? phoneNumber;

  const ContactEntity({
    required this.contactUid,
    required this.name,
    this.starred = false,
    this.createdAt,
    this.updatedAt,
    this.email,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [
    contactUid,
    name,
    starred,
    createdAt,
    updatedAt,
    email,
    phoneNumber,
  ];

  ContactEntity copyWith({
    String? contactUid,
    String? name,
    bool? starred,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactEntity(
      contactUid: contactUid ?? this.contactUid,
      name: name ?? this.name,
      starred: starred ?? this.starred,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
