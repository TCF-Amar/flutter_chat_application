// import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
// import 'package:chat_kare/features/contacts/domain/entities/contact_entity.dart';
// import 'package:equatable/equatable.dart';

// /// Composite entity that combines contact information with user profile data
// /// Used in presentation layer where both contact and user details are needed
// class ContactWithUserData extends Equatable {
//   final ContactEntity contact;
//   final UserEntity user;
//   final String? chatId;

//   const ContactWithUserData({
//     required this.contact,
//     required this.user,
//     this.chatId,
//   });

//   // Convenience getters
//   String get contactUid => contact.contactUid;
//   String get name => contact.name;
//   bool get starred => contact.starred;
//   String? get email => user.email;
//   String? get phoneNumber => user.phoneNumber;
//   String? get photoUrl => user.photoUrl;
//   String? get status => user.status;
//   DateTime? get lastSeen => user.lastSeen;

//   @override
//   List<Object?> get props => [contact, user, chatId];

//   ContactWithUserData copyWith({
//     ContactEntity? contact,
//     UserEntity? user,
//     String? chatId,
//   }) {
//     return ContactWithUserData(
//       contact: contact ?? this.contact,
//       user: user ?? this.user,
//       chatId: chatId ?? this.chatId,
//     );
//   }
// }
