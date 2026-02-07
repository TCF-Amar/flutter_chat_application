import 'package:chat_kare/features/chat/data/datasources/chats_firebase_data_source.dart';
import 'package:chat_kare/features/chat/data/repositories/chats_repository_impl.dart';
import 'package:chat_kare/features/chat/domain/usecases/chats_usecase.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:get/get.dart';

class ChatsBinding {
  static void init() {
    // datasource
    Get.lazyPut(() => ChatsRemoteDataSourceImpl(fs: Get.find()));

    // repository
    Get.lazyPut(() => ChatsRepositoryImpl(chatFirebaseDataSource: Get.find()));

    // usecase
    Get.lazyPut(() => ChatsUsecase(chatsRepository: Get.find()));

    // controller
    Get.lazyPut(() => ChatController());
  }

  static void destroy() {
    Get.delete<ChatController>();
    Get.delete<ChatsUsecase>();
    Get.delete<ChatsRepositoryImpl>();
    Get.delete<ChatsRemoteDataSourceImpl>();
  }
}
