import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/contacts/domain/entities/contact_entity.dart';
import 'package:chat_kare/features/contacts/domain/repositories/contacts_repository.dart';

class ContactsUsecase {
  final ContactsRepository repository;

  ContactsUsecase({required this.repository});

  Future<Result<void>> addContact(ContactEntity entity, UserEntity me) async {
    return await repository.addContact(entity, me);
  }

  Future<Result<List<UserEntity>>> getContacts() async {
    return await repository.getContacts();
  }
}
