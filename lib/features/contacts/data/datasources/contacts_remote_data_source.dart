// contacts_remote_data_source.dart

import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/data/models/user_model.dart';
import 'package:chat_kare/features/contacts/data/models/contacts_model.dart';
import 'package:get/get.dart';

abstract class ContactsRemoteDataSource {
  Future<List<ContactsModel>> getContacts();
  Future<void> addContact(ContactsModel contact);
  Future<bool> isContactExists(String contactUid);
  Future<bool> doesContactExist({
    required String targetUserId,
    required String contactId,
  });
  Future<UserModel?> getUserByEmail(String email);
  Future<UserModel?> getUserByPhone(String phone);

  Future<ContactsModel> getTempContact(String uid);
  Future<void> addTempContact({
    required String targetUserId,
    required ContactsModel contact,
  });
  Future<void> deleteTempContact(String uid);

  Future<void> removeContact(String contactId);
  Future<void> updateContactStar(String contactId, bool stared);
}

class ContactsRemoteDataSourceImpl implements ContactsRemoteDataSource {
  final fs = Get.find<FirebaseServices>();

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

  @override
  Future<void> addContact(ContactsModel model) async {
    await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('contacts')
        .doc(model.id)
        .set(model.toJson());
  }

  @override
  Future<void> addTempContact({
    required String targetUserId,
    required ContactsModel contact,
  }) async {
    await fs.firestore
        .collection('users')
        .doc(targetUserId)
        .collection('tempContacts')
        .doc(contact.id)
        .set(contact.toJson());
  }

  @override
  Future<void> deleteTempContact(String uid) async {
    await fs.firestore
        .collection('users')
        .doc(uid)
        .collection('tempContacts')
        .doc(fs.auth.currentUser?.uid)
        .delete();
  }

  @override
  Future<void> removeContact(String contactId) async {
    await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }

  @override
  Future<void> updateContactStar(String contactId, bool stared) async {
    await fs.firestore
        .collection('users')
        .doc(fs.auth.currentUser?.uid)
        .collection('contacts')
        .doc(contactId)
        .update({'stared': stared});
  }
}
