/*
 * AuthRepositoryImpl - Authentication Repository Implementation
 * 
 * Implements the repository pattern for authentication operations.
 * Acts as a bridge between domain layer and data source layer.
 * 
 * Key Responsibilities:
 * - Delegates auth operations to AuthRemoteDataSource
 * - Handles FCM token initialization and cleanup
 * - Manages user document creation and updates
 * - Maps Firebase exceptions to domain failures
 * - Handles profile completion validation
 * 
 * Authentication Flow:
 * 1. Sign in/up via Firebase Auth
 * 2. Check/create user document in Firestore
 * 3. Initialize FCM token for notifications
 * 4. Return user entity to domain layer
 */

import 'package:chat_kare/core/errors/error_mapper.dart';
import 'package:chat_kare/core/errors/exceptions.dart' hide FirebaseException;
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chat_kare/core/services/notification_services.dart';
import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_kare/features/auth/data/models/user_model.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

/// Implementation of AuthRepository using Firebase services
class AuthRepositoryImpl implements AuthRepository {
  /// Remote data source for Firebase operations
  final AuthRemoteDataSource remoteDataSource = Get.find();

  /// Firebase services instance
  final FirebaseServices fs = Get.find();

  /// Notification services for FCM token management
  final NotificationServices notificationServices = Get.find();

  /// Logger for debugging and error tracking
  final Logger _logger = Logger();

  /// Signs in user with email and password
  ///
  /// Flow:
  /// 1. Authenticate with Firebase Auth
  /// 2. Fetch or create user document
  /// 3. Validate profile completion
  /// 4. Initialize FCM token
  ///
  /// Returns Right(UserEntity) on success, Left(Failure) on error.
  @override
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Repository: Attempting sign-in for $email');

      // Authenticate with Firebase
      final userCredential = await remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final uid = user.uid;
      _logger.i('Repository: Sign-in successful, uid: $uid');

      try {
        // Fetch existing user document
        final userDoc = await remoteDataSource.getUser(uid);

        // Validate profile completion
        if (userDoc.isProfileCompleted == false) {
          return Left(
            mapExceptionToFailure(Exception('Profile not completed')),
          );
        }

        // Initialize FCM token for push notifications
        await notificationServices.initializeFcmToken();
        return Right(userDoc);
      } on UserNotFoundException {
        // User document doesn't exist, create it
        final userModel = UserModel(
          photoUrl: user.photoURL,
          uid: uid,
          displayName: null,
          email: user.email!,
          isProfileCompleted: false,
          phoneNumber: user.phoneNumber,
        );

        await remoteDataSource.createUserDocument(userModel);
        return Right(userModel.toEntity());
      }
    } on FirebaseException catch (e) {
      _logger.e(
        'Repository: Sign-in failed with FirebaseException: ${e.message}',
      );
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('Repository: Sign-in failed with unexpected error: $e');
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  /// Creates new user account with email and password
  ///
  /// Flow:
  /// 1. Create Firebase Auth account
  /// 2. Create user document in Firestore
  ///
  /// Note: FCM token is initialized after profile completion.
  /// Returns Right(UserEntity) on success, Left(Failure) on error.
  @override
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Repository: Attempting sign-up for $email');

      // Create Firebase Auth user
      final credential = await remoteDataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      final uid = user.uid;
      _logger.i('Repository: Sign-up successful, uid: $uid');

      // Create user document with incomplete profile
      final userModel = UserModel(
        uid: uid,
        email: email,
        displayName: null,
        photoUrl: user.photoURL,
        phoneNumber: null,
        isProfileCompleted: false,
      );

      await remoteDataSource.createUserDocument(userModel);

      return Right(userModel.toEntity());
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  /// Retrieves user document from Firestore
  ///
  /// If user document doesn't exist but user is authenticated,
  /// creates a new document automatically.
  ///
  /// Returns Right(UserEntity) on success, Left(Failure) on error.
  @override
  Future<Result<UserEntity>> getUser(String uid) async {
    try {
      _logger.i('Repository: Fetching user for uid: $uid');

      final userModel = await remoteDataSource.getUser(uid);
      _logger.i('Repository: User fetched successfully');

      return Right(userModel.toEntity());
    } on UserNotFoundException {
      // User document doesn't exist, create it if user is authenticated
      _logger.w(
        'Repository: User document not found for uid: $uid. Creating new document.',
      );

      final currentUser = fs.auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        // Create document for authenticated user
        final userModel = UserModel(
          uid: uid,
          email: currentUser.email!,
          displayName: currentUser.displayName,
          photoUrl: currentUser.photoURL,
          phoneNumber: currentUser.phoneNumber,
          isProfileCompleted: false,
        );

        try {
          await remoteDataSource.createUserDocument(userModel);
          return Right(userModel.toEntity());
        } catch (e) {
          return Left(mapExceptionToFailure(Exception(e.toString())));
        }
      } else {
        return Left(mapExceptionToFailure(Exception('User not found')));
      }
    } on FirebaseException catch (e) {
      _logger.e(
        'Repository: Failed to fetch user - FirebaseException: ${e.message}',
      );
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('Repository: Failed to fetch user - Unexpected error: $e');
      if (e is Exception) {
        return Left(mapExceptionToFailure(e));
      }
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  /// Signs out current user
  ///
  /// Flow:
  /// 1. Remove device FCM token from Firestore
  /// 2. Sign out from Firebase Auth
  ///
  /// Returns Right(null) on success, Left(Failure) on error.
  @override
  Future<Result<void>> signOut() async {
    try {
      _logger.i('Repository: Attempting sign-out');

      // Remove current device's FCM token from Firestore
      _logger.d('Repository: Removing device FCM token');
      await notificationServices.deleteFcmToken();
      _logger.i('Repository: Device FCM token removed');

      // Sign out from Firebase Auth
      await remoteDataSource.signOut();

      _logger.i('Repository: Sign-out successful');
      return Right(null);
    } on FirebaseException catch (e) {
      _logger.e(
        'Repository: Sign-out failed with FirebaseException: ${e.message}',
      );
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('Repository: Sign-out failed with unexpected error: $e');
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  /// Updates user profile data
  ///
  /// Converts entity to model and updates in Firestore.
  /// Returns Right(UserEntity) on success, Left(Failure) on error.
  @override
  Future<Result<UserEntity>> updateUser(UserEntity user) async {
    try {
      _logger.i('Repository: Updating user: ${user.uid}');

      final userModel = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        phoneNumber: user.phoneNumber,
        isProfileCompleted: user.isProfileCompleted,
      );

      await remoteDataSource.updateUserData(userModel);
      _logger.i('Repository: User updated successfully');

      return Right(user);
    } on FirebaseException catch (e) {
      _logger.e(
        'Repository: Failed to update user - FirebaseException: ${e.message}',
      );
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('Repository: Failed to update user - Unexpected error: $e');
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

  /// Updates user online/offline status
  ///
  /// Non-critical operation - failures are logged but not thrown.
  Future<void> updateUserStatus({
    required String uid,
    required String status,
  }) async {
    try {
      _logger.i('Repository: Updating user status to $status');
      await remoteDataSource.updateUserStatus(uid: uid, status: status);
    } catch (e) {
      _logger.e('Repository: Failed to update user status: $e');
      // Don't throw - status updates are non-critical
    }
  }

  /// Gets the current authenticated user's UID
  @override
  String? get currentUid => remoteDataSource.currentUid;
}
