import 'package:chat_kare/core/errors/error_mapper.dart';
import 'package:chat_kare/core/errors/exceptions.dart';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/core/services/notification_services.dart';
import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_kare/features/auth/data/models/user_model.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource remoteDataSource = Get.find();
  final FirebaseServices fs = Get.find();
  final NotificationServices notificationServices = Get.find();
  final Logger _logger = Logger();

  Future<Result<void>> signIn(String email, String password) async {
    try {
      _logger.i('Repository: Attempting sign-in for $email');

      await remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = fs.auth.currentUser!.uid;
      _logger.i('Repository: Sign-in successful, uid: $uid');

      _logger.d('Repository: Initializing FCM token');
      await notificationServices.initializeFcmToken();
      _logger.i('Repository: FCM token initialized successfully');

      return Right(null);
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
        photoUrl: null,
        phoneNumber: user.photoURL,
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
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

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

  Future<Result<bool>> userExistsByPhone(String phone) async {
    try {
      _logger.i('Repository: Checking user existence for phone: $phone');
      final normalizedPhone = _normalizeIndianPhone(phone);
      _logger.d('Repository: Normalized phone: $normalizedPhone');

      final exists = await remoteDataSource.checkUserExistsByPhone(
        normalizedPhone,
      );

      _logger.i('Repository: User existence check completed: $exists');
      return Right(exists);
    } on FirebaseException catch (e) {
      _logger.e(
        'Repository: User existence check failed with FirebaseException: ${e.message}',
      );
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e(
        'Repository: User existence check failed with unexpected error: $e',
      );
      return Left(mapExceptionToFailure(Exception(e.toString())));
    }
  }

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

  String _normalizeIndianPhone(String phone) {
    final value = phone.replaceAll(RegExp(r'\s+'), '');

    if (value.startsWith('+91')) {
      return value;
    }

    if (value.startsWith('91') && value.length == 12) {
      return '+$value';
    }

    if (value.startsWith('0') && value.length == 11) {
      return '+91${value.substring(1)}';
    }

    if (value.length == 10) {
      return '+91$value';
    }
    if (value.length < 10) {
      throw Exception('Invalid phone number length');
    }

    throw Exception('Invalid phone number format');
  }
}
