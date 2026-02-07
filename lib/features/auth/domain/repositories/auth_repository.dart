import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  });
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
  });
  Future<Result<UserEntity>> getUser(String uid);
  Future<Result<void>> signOut();
  Future<Result<void>> updateUser(UserEntity user);
  String? get currentUid;
}
