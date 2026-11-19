import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_storage_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthStorageDataSource storageDataSource;

  AuthRepositoryImpl({required this.storageDataSource});

  @override
  Future<UserModel?> getCurrentUser() {
    return storageDataSource.getCurrentUser();
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) {
    return storageDataSource.register(
      email: email,
      password: password,
      name: name,
    );
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) {
    return storageDataSource.login(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> logout() {
    return storageDataSource.logout();
  }
}
