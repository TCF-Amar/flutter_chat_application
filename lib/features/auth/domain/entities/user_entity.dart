import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final bool isProfileCompleted;
  final String? status;
  final DateTime? lastSeen;

  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.isProfileCompleted,
    this.status,
    this.lastSeen,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    phoneNumber,
    isProfileCompleted,
    status,
    lastSeen,
  ];

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    bool? isProfileCompleted,
    String? status,
    DateTime? lastSeen,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
