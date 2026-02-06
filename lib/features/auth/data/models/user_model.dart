import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.photoUrl,
    required super.isProfileCompleted,
    required super.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      isProfileCompleted: json['isProfileCompleted'],
      phoneNumber: json['phoneNumber'],
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
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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
    );
  }
}
