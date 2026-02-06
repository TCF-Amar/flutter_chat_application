import 'package:chat_kare/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_kare/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:get/get.dart';

class AuthBinding {
  static Future<void> init() async {
    // ---- Datasources ----
    Get.lazyPut<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());

    // ---- Repository ----
    Get.lazyPut<AuthRepositoryImpl>(() => AuthRepositoryImpl());

    // ---- Usecase ----
    Get.lazyPut<AuthUsecase>(() => AuthUsecase(repository: Get.find()));

    // ---- Controller ----
    Get.put(AuthController(), permanent: true);
  }
}
