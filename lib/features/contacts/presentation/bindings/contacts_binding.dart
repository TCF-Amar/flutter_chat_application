import 'package:chat_kare/features/contacts/data/datasources/contacts_remote_data_source.dart';
import 'package:chat_kare/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:chat_kare/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:chat_kare/features/contacts/domain/usecases/contacts_usecase.dart';
import 'package:chat_kare/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:get/get.dart';

class ContactsBinding {
  static Future<void> init() async {
    Get.put<ContactsRemoteDataSource>(ContactsRemoteDataSourceImpl());
    Get.put<ContactsRepository>(
      ContactsRepositoryImpl(remoteDataSource: Get.find()),
    );
    Get.put<ContactsUsecase>(ContactsUsecase(repository: Get.find()));

    Get.put(ContactsController());
  }
}
