import 'package:chat_kare/core/errors/error_mapper.dart';
import 'package:chat_kare/core/errors/exceptions.dart';
import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/contacts/data/datasources/contacts_remote_data_source.dart';
import 'package:chat_kare/features/contacts/data/models/contacts_model.dart';
import 'package:chat_kare/features/auth/data/models/user_model.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:chat_kare/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:dartz/dartz.dart';

class ContactsRepositoryImpl extends ContactsRepository {
  final ContactsRemoteDataSource remoteDataSource;

  ContactsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<ContactsEntity>>> getContacts() async {
    try {
      final models = await remoteDataSource.getContacts();
      return Right(models.map((e) => e.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  @override
  Future<Result<void>> addContact(ContactsEntity entity, UserEntity me) async {
    try {
      // Validate input
      if ((entity.email == null || entity.email!.isEmpty) &&
          (entity.phoneNumber == null || entity.phoneNumber!.isEmpty)) {
        return Left(
          mapExceptionToFailure(Exception("Email or phone number is required")),
        );
      }

      // 1. Find target user
      UserModel? targetUser;
      if (entity.email != null && entity.email!.isNotEmpty) {
        targetUser = await remoteDataSource.getUserByEmail(entity.email!);
      } else if (entity.phoneNumber != null && entity.phoneNumber!.isNotEmpty) {
        targetUser = await remoteDataSource.getUserByPhone(entity.phoneNumber!);
      }

      if (targetUser == null) {
        return Left(mapExceptionToFailure(Exception("User not found")));
      }

      // 2. Prevent self-addition
      if (targetUser.uid == me.uid) {
        return Left(
          mapExceptionToFailure(Exception("Cannot add yourself as a contact")),
        );
      }

      // 3. Check if contact already exists (by UID)
      final contactExists = await remoteDataSource.isContactExists(
        targetUser.uid,
      );
      if (contactExists) {
        return Left(
          mapExceptionToFailure(
            DuplicateContactException("Contact already exists"),
          ),
        );
      }

      // 4. Check for pending contact request (temp contact)
      ContactsModel? existingTempContact;
      try {
        existingTempContact = await remoteDataSource.getTempContact(
          targetUser.uid,
        );
        // If temp contact exists, remove it (this means the target user already added me)
        await remoteDataSource.deleteTempContact(targetUser.uid);
      } catch (e) {
        // No temp contact exists, that's fine
      }

      // 5. Generate chat ID (use existing one from temp contact if available, otherwise create new)
      final chatId =
          existingTempContact?.chatId ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // 6. Add target user to my contacts
      final newContact = ContactsModel(
        id: targetUser.uid,
        name: targetUser.displayName ?? entity.name ,
        email: targetUser.email,
        phoneNumber: targetUser.phoneNumber,
        photoUrl: targetUser.photoUrl,
        stared: false,
        chatId: chatId,
        createdAt: DateTime.now(),
      );

      await remoteDataSource.addContact(newContact);

      // 7. Add myself to target user's contacts (if they haven't added me yet)
      final myContact = ContactsModel(
        id: me.uid,
        name: me.displayName ?? me.email,
        email: me.email,
        phoneNumber: me.phoneNumber,
        photoUrl: me.photoUrl,
        stared: false,
        chatId: chatId, // Same chat ID for both contacts
        createdAt: DateTime.now(),
      );

      // Check if target user already has me in their contacts
      final targetUserHasMe = await remoteDataSource.doesContactExist(
        targetUserId: targetUser.uid,
        contactId: me.uid,
      );

      if (!targetUserHasMe) {
        // Add me as a temp contact for the target user
        await remoteDataSource.addTempContact(
          targetUserId: targetUser.uid,
          contact: myContact,
        );
      }

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  Future<Result<void>> removeContact(String contactId) async {
    try {
      await remoteDataSource.removeContact(contactId);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  Future<Result<void>> toggleStarContact(String contactId, bool stared) async {
    try {
      await remoteDataSource.updateContactStar(contactId, stared);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }
}
