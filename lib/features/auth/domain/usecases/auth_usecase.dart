import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';

class AuthUsecase {
  final AuthRepositoryImpl repository;

  AuthUsecase({required this.repository});
  Future<Result<void>> signIn(String email, String password) async {
    return await repository.signIn(email, password);
  }

  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
  }) async {
    return await repository.signUp(email: email, password: password);
  }

  Future<Result<UserEntity>> getUser(String uid) async {
    return await repository.getUser(uid);
  }

  Future<Result<void>> signOut() async {
    return await repository.signOut();
  }

  Future<Result<bool>> userExistsByPhone(String phone) async {
    return await repository.userExistsByPhone(phone);
  }

  Future<Result<UserEntity>> updateUser(UserEntity user) async {
    return await repository.updateUser(user);
  }
}
