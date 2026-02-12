import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.photoUrl,
    required super.isProfileCompleted,
    required super.phoneNumber,
    super.status,
    super.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      isProfileCompleted: json['isProfileCompleted'] ?? false,
      phoneNumber: json['phoneNumber'] ?? '',
      status: json['status'],
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      "isProfileCompleted": isProfileCompleted,
      "phoneNumber": phoneNumber,
      "status": status,
      "lastSeen": lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? fmcToken,
    bool? isProfileCompleted,
    String? phoneNumber,
    String? status,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  // entity
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isProfileCompleted: isProfileCompleted,
      phoneNumber: phoneNumber,
      status: status,
      lastSeen: lastSeen,
    );
  }
}
