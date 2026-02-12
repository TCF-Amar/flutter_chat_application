/*
 * AuthRemoteDataSource - Firebase Authentication Data Source
 * 
 * Handles all Firebase Authentication and Firestore user document operations.
 * 
 * Key Responsibilities:
 * - Firebase Auth operations (sign in, sign up, sign out)
 * - User document CRUD in Firestore
 * - User status updates (online/offline)
 * - Error handling and logging
 * 
 * Firestore Structure:
 * - /users/{uid} - User profile documents
 */

import 'package:chat_kare/core/errors/exceptions.dart' hide FirebaseException;
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:get/get.dart';
import 'package:logger/logger.dart';

//* Abstract interface for authentication data source
abstract class AuthRemoteDataSource {
  //* Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  //* Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  //* Sign out current user
  Future<void> signOut();

  //* Create user document in Firestore
  Future<void> createUserDocument(UserModel user);

  //* Get user document from Firestore
  Future<UserModel> getUser(String uid);

  //* Update user profile data
  Future<void> updateUserData(UserModel user);

  //* Update user online/offline status
  Future<void> updateUserStatus({required String uid, required String status});

  //* Get current user's UID
  String? get currentUid;
}

//* Firebase implementation of authentication data source
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  //* Firebase services instance
  final FirebaseServices fs = Get.find<FirebaseServices>();

  //* Logger for debugging and error tracking
  final Logger _logger = Logger();

  //* Signs in user with email and password
  //*
  //* Throws FirebaseException on authentication errors.
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
      rethrow; // Rethrow to be handled by repository
    }
  }

  //* Creates new user account with email and password
  //*
  //* Throws FirebaseException on account creation errors.
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

  //* Signs out the current user
  //*
  //* Logs the operation for debugging purposes.
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

  //* Creates a new user document in Firestore
  //*
  //* Called after successful sign-up to store user profile data.
  //* Throws FirebaseException on Firestore errors.
  @override
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

  //* Retrieves user document from Firestore
  //*
  //* Throws UserNotFoundException if user document doesn't exist.
  //* Throws FirebaseException on Firestore errors.
  @override
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

  //* Updates user profile data in Firestore
  //*
  //* Validates phone number uniqueness before updating.
  //* Throws Exception if phone number already exists.
  //* Throws FirebaseException on Firestore errors.
  @override
  Future<void> updateUserData(UserModel user) async {
    try {
      _logger.i('DataSource: Updating user document for ${user.uid}');

      // Check if phone number is already used by another user
      final phoneNumber = user.phoneNumber;
      final exist = await fs.firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (exist.docs.isNotEmpty) {
        final existingUserDoc = exist.docs.first;
        if (existingUserDoc.id != user.uid) {
          _logger.e(
            'DataSource: User already exists with phone number: $phoneNumber',
          );
          throw Exception(
            'User already exists with phone number: $phoneNumber',
          );
        }
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

  //* Updates user's online/offline status
  //*
  //* Also updates lastSeen timestamp to server time.
  //* Failures are logged but not thrown (non-critical operation).
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

  //* Gets the current authenticated user's UID
  @override
  String? get currentUid => fs.auth.currentUser?.uid;
}
