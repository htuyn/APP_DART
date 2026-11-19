import '../../data/models/user_model.dart';

abstract class IAuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  });
  Future<UserModel> login({
    required String email,
    required String password,
  });
  Future<void> logout();
}
