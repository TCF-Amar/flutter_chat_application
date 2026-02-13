import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/contacts/domain/entities/contact_entity.dart';

abstract class ContactsRepository {
  Future<Result<List<UserEntity>>> getContacts();
  Future<Result<void>> addContact(ContactEntity entity, UserEntity me);
  Future<Result<void>> deleteContact(String uid);
  Future<Result<void>> updateContact(ContactEntity entity);
}
