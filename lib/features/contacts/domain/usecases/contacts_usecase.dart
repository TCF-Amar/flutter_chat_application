import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:chat_kare/features/contacts/domain/repositories/contacts_repository.dart';

class ContactsUsecase {
  final ContactsRepository repository;

  ContactsUsecase({required this.repository});

  Future<Result<void>> addContact(ContactsEntity entity, UserEntity me) async {
    return await repository.addContact(entity, me);
  }

  Future<Result<List<ContactsEntity>>> getContacts() async {
    return await repository.getContacts();
  }
}
