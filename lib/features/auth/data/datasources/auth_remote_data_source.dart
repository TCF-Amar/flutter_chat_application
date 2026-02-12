import 'package:chat_kare/core/errors/exceptions.dart' hide FirebaseException;
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:get/get.dart';
import 'package:logger/logger.dart';

abstract class AuthRemoteDataSource {
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> createUserDocument(UserModel user);
  Future<UserModel> getUser(String uid);
  Future<void> updateUserData(UserModel user);
  Future<void> updateUserStatus({required String uid, required String status});
  String? get currentUid;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseServices fs = Get.find<FirebaseServices>();
  final Logger _logger = Logger();
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('DataSource: Attempting Firebase sign-in for $email');

      final userCredential = await fs.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logger.i('DataSource: Firebase sign-in successful for $email');
      return userCredential;
    } on FirebaseException catch (e) {
      _logger.e(
        'DataSource: Firebase sign-in failed - Code: ${e.code}, Message: ${e.message}',
      );
      rethrow; // Rethrow FirebaseException to be handled by repository
    }
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await fs.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      _logger.i('DataSource: Attempting Firebase sign-out');
      await fs.auth.signOut();
      _logger.i('DataSource: Firebase sign-out successful');
    } catch (e) {
      _logger.e('DataSource: Firebase sign-out failed: $e');
      throw Exception(e.toString());
    }
  }

  @override
  /// Create user document in Firestore
  Future<void> createUserDocument(UserModel user) async {
    try {
      _logger.i('DataSource: Creating user document for ${user.email}');

      await fs.firestore.collection('users').doc(user.uid).set(user.toMap());

      _logger.i(
        'DataSource: User document created successfully for ${user.uid}',
      );
    } on FirebaseException catch (e) {
      _logger.e(
        'DataSource: Failed to create user document - Code: ${e.code}, Message: ${e.message}',
      );
      rethrow;
    }
  }

  @override
  /// Get user from Firestore
  Future<UserModel> getUser(String uid) async {
    try {
      _logger.i('DataSource: Fetching user document for uid: $uid');

      final doc = await fs.firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        _logger.e('DataSource: User document not found for uid: $uid');
        throw UserNotFoundException('User not found');
      }

      _logger.i('DataSource: User document fetched successfully for uid: $uid');
      return UserModel.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      _logger.e(
        'DataSource: Failed to fetch user - Code: ${e.code}, Message: ${e.message}',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateUserData(UserModel user) async {
    try {
      _logger.i('DataSource: Updating user document for ${user.uid}');
      final phoneNumber = user.phoneNumber;
      final exist = await fs.firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      if (exist.docs.isNotEmpty) {
        _logger.e(
          'DataSource: User already exists with phone number: $phoneNumber',
        );
        throw Exception('User already exists with phone number: $phoneNumber');
      }

      await fs.firestore.collection('users').doc(user.uid).update(user.toMap());
      _logger.i(
        'DataSource: User document updated successfully for ${user.uid}',
      );
    } on FirebaseException catch (e) {
      _logger.e(
        'DataSource: Failed to update user document - Code: ${e.code}, Message: ${e.message}',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateUserStatus({
    required String uid,
    required String status,
  }) async {
    try {
      _logger.i('DataSource: Updating user status to $status for uid: $uid');
      await fs.firestore.collection('users').doc(uid).update({
        'status': status,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      _logger.i('DataSource: User status updated successfully');
    } on FirebaseException catch (e) {
      _logger.e(
        'DataSource: Failed to update user status - Code: ${e.code}, Message: ${e.message}',
      );
      // Don't rethrow - status update failures shouldn't break the app
    }
  }

  @override
  String? get currentUid => fs.auth.currentUser?.uid;
}
