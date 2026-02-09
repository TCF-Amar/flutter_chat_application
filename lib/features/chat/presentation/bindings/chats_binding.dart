import 'package:chat_kare/features/chat/data/datasources/chats_firebase_data_source.dart';
import 'package:chat_kare/features/chat/data/repositories/chats_repository_impl.dart';
import 'package:chat_kare/features/chat/domain/usecases/chats_usecase.dart';
import 'package:get/get.dart';

import 'package:chat_kare/features/chat/domain/repositories/chats_repository.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_list_controller.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';

class ChatsBinding {
  static void init() {
    // datasource
    Get.lazyPut(() => ChatsRemoteDataSourceImpl(fs: Get.find()));

    // repository
    Get.lazyPut<ChatsRepository>(
      () => ChatsRepositoryImpl(chatFirebaseDataSource: Get.find()),
    );

    // usecase
    Get.lazyPut(
      () => ChatsUsecase(chatsRepository: Get.find<ChatsRepository>()),
    );

    // controller
    Get.lazyPut(
      () => ChatListController(
        chatsUsecase: Get.find(),
        authUseCase: Get.find<AuthUsecase>(),
      ),
    );
  }
}
