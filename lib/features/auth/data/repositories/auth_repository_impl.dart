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

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource = Get.find();
  final FirebaseServices fs = Get.find();
  final NotificationServices notificationServices = Get.find();
  final Logger _logger = Logger();
  @override
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Repository: Attempting sign-in for $email');

      final userCredential = await remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;
      final uid = user.uid;
      _logger.i('Repository: Sign-in successful, uid: $uid');

      try {
        final userDoc = await remoteDataSource.getUser(uid);
        if (userDoc.isProfileCompleted == false) {
          return Left(
            mapExceptionToFailure(Exception('Profile not completed')),
          );
        }

        await notificationServices.initializeFcmToken();
        return Right(userDoc);
      } on UserNotFoundException {
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

      // Get FCM token

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

  @override
  Future<Result<UserEntity>> getUser(String uid) async {
    try {
      _logger.i('Repository: Fetching user for uid: $uid');

      final userModel = await remoteDataSource.getUser(uid);
      _logger.i('Repository: User fetched successfully');

      return Right(userModel.toEntity());
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

  @override
  String? get currentUid => remoteDataSource.currentUid;
}
