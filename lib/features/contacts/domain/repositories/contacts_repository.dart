import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';

abstract class ContactsRepository {
  Future<Result<List<ContactsEntity>>> getContacts();
  Future<Result<void>> addContact(ContactsEntity entity, UserEntity me);
}
