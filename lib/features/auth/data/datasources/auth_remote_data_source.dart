import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class AuthRemoteDataSource {
  final FirebaseServices fs = Get.find<FirebaseServices>();
  final Logger _logger = Logger();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('DataSource: Attempting Firebase sign-in for $email');

      await fs.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logger.i('DataSource: Firebase sign-in successful for $email');
    } on FirebaseException catch (e) {
      _logger.e(
        'DataSource: Firebase sign-in failed - Code: ${e.code}, Message: ${e.message}',
      );
      rethrow; // Rethrow FirebaseException to be handled by repository
    }
  }

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
    } on FirebaseException catch (e) {
      rethrow;
    }
  }

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

  /// Get user from Firestore
  Future<UserModel> getUser(String uid) async {
    try {
      _logger.i('DataSource: Fetching user document for uid: $uid');

      final doc = await fs.firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        _logger.e('DataSource: User document not found for uid: $uid');
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

  Future<bool> checkUserExistsByPhone(String normalizedPhone) async {
    try {
      _logger.i(
        'DataSource: Checking if user exists with phone: $normalizedPhone',
      );

      final query = await fs.firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      final exists = query.docs.isNotEmpty;
      _logger.i('DataSource: User exists check result: $exists');
      return exists;
    } on FirebaseException catch (e) {
      _logger.e(
        'DataSource: Failed to check user existence - Code: ${e.code}, Message: ${e.message}',
      );
      rethrow;
    }
  }

  Future<void> updateUserData(UserModel user) async {
    try {
      _logger.i('DataSource: Updating user document for ${user.uid}');
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
}
