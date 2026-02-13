/*
 * ContactsRepositoryImpl - Contacts Repository Implementation
 * 
 * Implements the repository pattern for contacts management.
 * Acts as a bridge between domain layer and data source layer.
 * 
 * Key Responsibilities:
 * - Manages contact CRUD operations
 * - Handles temporary contacts (pending requests)
 * - Fetches full user details for contacts
 * - Validates contact operations (duplicates, self-add)
 * - Maps Firebase exceptions to domain failures
 * 
 * Contact Flow:
 * 1. User adds contact by email/phone
 * 2. System finds target user and validates
 * 3. Adds to current user's contacts
 * 4. Creates temp contact for target user (if they haven't added you)
 * 5. When target user adds you, temp contact is removed
 */

import 'package:chat_kare/core/errors/error_mapper.dart';
import 'package:chat_kare/core/errors/exceptions.dart';
import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/contacts/data/datasources/contacts_remote_data_source.dart';
import 'package:chat_kare/features/contacts/data/models/contacts_model.dart';
import 'package:chat_kare/features/auth/data/models/user_model.dart';
import 'package:chat_kare/features/contacts/domain/entities/contact_entity.dart';
import 'package:chat_kare/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:dartz/dartz.dart';

//* Implementation of ContactsRepository using Firebase data source
class ContactsRepositoryImpl extends ContactsRepository {
  //* Remote data source for Firebase operations
  final ContactsRemoteDataSource remoteDataSource;

  ContactsRepositoryImpl({required this.remoteDataSource});

  //* Gets all contacts for current user with full user details
  //*
  //* Flow:
  //* 1. Fetch contact entities from contacts subcollection
  //* 2. For each contact, fetch full user details from users collection
  //* 3. Override display name with custom contact name if set
  //*
  //* Returns Right([List]<[UserEntity]>) on success, Left(Failure) on error.
  @override
  Future<Result<List<UserEntity>>> getContacts() async {
    try {
      // Step 1: Fetch contact entities from contacts subcollection
      final contactModels = await remoteDataSource.getContacts();

      // Step 2: Fetch full user entities for each contact
      final List<UserEntity> userEntities = [];

      for (final contact in contactModels) {
        try {
          // Fetch user data from users collection
          final userModel = await remoteDataSource.getUserById(
            contact.contactUid,
          );

          if (userModel != null) {
            // Override displayName with contact's custom name if it exists
            final userEntity = userModel.toEntity().copyWith(
              displayName: contact.name.isNotEmpty
                  ? contact.name
                  : userModel.displayName,
            );

            userEntities.add(userEntity);
          }
        } catch (e) {
          // Skip contacts that can't be fetched
          continue;
        }
      }

      return Right(userEntities);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  //* Adds a new contact for the current user
  //*
  //* Flow:
  //* 1. Validate input (email or phone required)
  //* 2. Find target user by email or phone
  //* 3. Prevent self-addition
  //* 4. Check for duplicate contacts
  //* 5. Check for pending temp contact (mutual add)
  //* 6. Add to current user's contacts
  //* 7. Add temp contact for target user (if needed)
  //*
  //* Returns Right(null) on success, Left(Failure) on error.
  @override
  Future<Result<void>> addContact(ContactEntity entity, UserEntity me) async {
    try {
      // Validate input - require email or phone
      if ((entity.email == null || entity.email!.isEmpty) &&
          (entity.phoneNumber == null || entity.phoneNumber!.isEmpty)) {
        return Left(
          mapExceptionToFailure(Exception("Email or phone number is required")),
        );
      }

      // 1. Find target user by email or phone
      UserModel? targetUser;
      if (entity.email != null && entity.email!.isNotEmpty) {
        targetUser = await remoteDataSource.getUserByEmail(entity.email!);
      } else if (entity.phoneNumber != null && entity.phoneNumber!.isNotEmpty) {
        targetUser = await remoteDataSource.getUserByPhone(entity.phoneNumber!);
      }

      // User not found
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

      // 5. Check for a pending contact request (temporary contact) from the target user.
      // This scenario occurs if the target user has already added the current user.
      try {
        // Attempt to delete a temporary contact where the current user is the 'temp' contact
        // for the target user. If successful, it means a mutual addition has occurred,
        // and the temporary status is no longer needed.
        await remoteDataSource.deleteTempContact(targetUser.uid);
      } catch (e) {
        // If no temporary contact exists, the `deleteTempContact` might throw an error.
        // This is an expected scenario and means the target user hasn't added the current user yet.
        // We simply ignore this error and proceed.
      }

      // 6. Add the target user to the current user's contacts list.
      // Create a ContactsModel for the new contact, using the target user's UID
      // and either the custom name provided in the entity or the target user's display name.
      final newContact = ContactsModel(
        contactUid: targetUser.uid,
        name: targetUser.displayName ?? entity.name,
        createdAt: DateTime.now(),
      );

      await remoteDataSource.addContact(newContact);

      // 7. Add myself to target user's contacts (if they haven't added me yet)
      final myContact = ContactsModel(
        contactUid: me.uid,
        name: me.displayName ?? me.email,
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

  //* Removes a contact from current user's contact list
  //*
  //* Returns Right(null) on success, Left(Failure) on error.
  @override
  Future<Result<void>> deleteContact(String contactId) async {
    try {
      await remoteDataSource.removeContact(contactId);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  //* Updates a contact's details (currently only name)
  //*
  //* Returns Right(null) on success, Left(Failure) on error.
  @override
  Future<Result<void>> updateContact(ContactEntity entity) async {
    try {
      // Update name if changed
      if (entity.name.isNotEmpty) {
        await remoteDataSource.updateContactName(
          entity.contactUid,
          entity.name,
        );
      }
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  //* Toggles starred/favorited status for a contact
  //*
  //* Returns Right(null) on success, Left(Failure) on error.
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
