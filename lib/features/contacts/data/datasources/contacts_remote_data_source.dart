/*
 * ContactsRemoteDataSource - Firebase Data Source for Contacts
 * 
 * Handles all Firestore operations for contacts management.
 * 
 * Key Features:
 * - Contact CRUD operations
 * - User lookup by email, phone, or UID
 * - Temporary contacts (pending contact requests)
 * - Contact starring/favoriting
 * 
 * Firestore Structure:
 * - /users/{userId}/contacts/{contactId} - User's contact list
 * - /users/{userId}/tempContacts/{contactId} - Pending contact requests
 * - /users - User profiles for lookup
 */

import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/data/models/user_model.dart';
import 'package:chat_kare/features/contacts/data/models/contacts_model.dart';
import 'package:get/get.dart';

//* Abstract interface for contacts data source
abstract class ContactsRemoteDataSource {
  //* Get all contacts for current user
  Future<List<ContactsModel>> getContacts();

  //* Add a contact to current user's contact list
  Future<void> addContact(ContactsModel contact);

  //* Check if contact exists in current user's contacts
  Future<bool> isContactExists(String contactUid);

  //* Check if contact exists for a specific user
  Future<bool> doesContactExist({
    required String targetUserId,
    required String contactId,
  });

  //* Find user by email address
  Future<UserModel?> getUserByEmail(String email);

  //* Find user by phone number
  Future<UserModel?> getUserByPhone(String phone);

  //* Get user by UID
  Future<UserModel?> getUserById(String uid);

  //* Get temporary contact (pending request)
  Future<ContactsModel> getTempContact(String uid);

  //* Add temporary contact for a user
  Future<void> addTempContact({
    required String targetUserId,
    required ContactsModel contact,
  });

  //* Delete temporary contact
  Future<void> deleteTempContact(String uid);

  //* Remove contact from current user's list
  Future<void> removeContact(String contactId);

  //* Update contact starred status
  Future<void> updateContactStar(String contactId, bool stared);

  //* Update contact name
  Future<void> updateContactName(String contactId, String newName);
}

//* Firebase implementation of contacts data source
class ContactsRemoteDataSourceImpl implements ContactsRemoteDataSource {
  //* Firebase services instance
  final fs = Get.find<FirebaseServices>();

  //* Finds user by email address
  //*
  //* Returns null if no user found with that email.
  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final query = await fs.firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return UserModel.fromJson(doc.data());
  }

  //* Finds user by phone number
  //*
  //* Returns null if no user found with that phone.
  @override
  Future<UserModel?> getUserByPhone(String phone) async {
    final query = await fs.firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return UserModel.fromJson(doc.data());
  }

  //* Gets user by UID
  //*
  //* Returns null if user document doesn't exist.
  @override
  Future<UserModel?> getUserById(String uid) async {
    final doc = await fs.firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromJson(doc.data()!);
  }

  //* Gets all contacts for current user
  //*
  //* Returns list of contact models from user's contacts subcollection.
  @override
  Future<List<ContactsModel>> getContacts() async {
    final doc = await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('contacts')
        .get();

    final models = doc.docs
        .map((e) => ContactsModel.fromJson(e.data()))
        .toList();

    return models;
  }

  //* Checks if contact exists in current user's contacts
  //*
  //* Returns true if contact with given UID exists.
  @override
  Future<bool> isContactExists(String contactUid) async {
    final doc = await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('contacts')
        .doc(contactUid)
        .get();

    return doc.exists;
  }

  //* Checks if contact exists for a specific user
  //*
  //* Used to check if target user already has current user in their contacts.
  @override
  Future<bool> doesContactExist({
    required String targetUserId,
    required String contactId,
  }) async {
    final doc = await fs.firestore
        .collection('users')
        .doc(targetUserId)
        .collection('contacts')
        .doc(contactId)
        .get();

    return doc.exists;
  }

  //* Gets temporary contact from current user's tempContacts
  //*
  //* Throws exception if temp contact not found.
  @override
  Future<ContactsModel> getTempContact(String uid) async {
    final doc = await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('tempContacts')
        .doc(uid)
        .get();

    if (!doc.exists) {
      throw Exception('Temp contact not found');
    }

    return ContactsModel.fromJson(doc.data()!);
  }

  //* Adds contact to current user's contacts
  @override
  Future<void> addContact(ContactsModel model) async {
    await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('contacts')
        .doc(model.contactUid)
        .set(model.toJson());
  }

  //* Adds temporary contact to target user's tempContacts
  //*
  //* Used when adding a contact who hasn't added you yet.
  @override
  Future<void> addTempContact({
    required String targetUserId,
    required ContactsModel contact,
  }) async {
    await fs.firestore
        .collection('users')
        .doc(targetUserId)
        .collection('tempContacts')
        .doc(contact.contactUid)
        .set(contact.toJson());
  }

  //* Deletes temporary contact from user's tempContacts
  //*
  //* Called when contact request is accepted.
  @override
  Future<void> deleteTempContact(String uid) async {
    await fs.firestore
        .collection('users')
        .doc(uid)
        .collection('tempContacts')
        .doc(fs.auth.currentUser?.uid)
        .delete();
  }

  //* Removes contact from current user's contacts
  @override
  Future<void> removeContact(String contactId) async {
    await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }

  //* Updates contact's starred/favorited status
  @override
  Future<void> updateContactStar(String contactId, bool starred) async {
    await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('contacts')
        .doc(contactId)
        .update({'starred': starred});
  }

  //* Updates contact's name
  @override
  Future<void> updateContactName(String contactId, String newName) async {
    await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('contacts')
        .doc(contactId)
        .update({'name': newName});
  }
}
