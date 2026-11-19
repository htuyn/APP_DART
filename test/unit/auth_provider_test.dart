import 'package:flutter_quiz_bilingual/data/models/user_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/auth_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepo implements IAuthRepository {
  UserModel? user;
  final Map<String, String> passwords = {};
  final Map<String, UserModel> users = {};

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (users.containsKey(normalized)) {
      throw Exception('EMAIL_IN_USE');
    }
    final newUser = UserModel(
      id: '1',
      email: normalized,
      name: name,
      createdAt: DateTime.now(),
    );
    users[normalized] = newUser;
    passwords[normalized] = password;
    user = newUser;
    return newUser;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!users.containsKey(normalized)) {
      throw Exception('USER_NOT_FOUND');
    }
    if (passwords[normalized] != password) {
      throw Exception('WRONG_PASSWORD');
    }
    user = users[normalized];
    return user!;
  }

  @override
  Future<void> logout() async {
    user = null;
  }
}

void main() {
  group('AuthProvider Unit Tests', () {
    late _FakeAuthRepo repo;
    late AuthProvider authProvider;

    setUp(() {
      repo = _FakeAuthRepo();
      authProvider = AuthProvider(repository: repo);
    });

    test('initial state has no user and not authenticated', () async {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, null);
      await authProvider.initialize();
      expect(authProvider.isAuthenticated, false);
    });

    test('register success creates user session', () async {
      final success = await authProvider.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Nguyen Van A',
      );

      expect(success, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.currentUser?.email, 'test@example.com');
      expect(authProvider.currentUser?.name, 'Nguyen Van A');
      expect(authProvider.errorMessage, null);
    });

    test('register with duplicate email fails with EMAIL_IN_USE', () async {
      await authProvider.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Nguyen Van A',
      );

      final secondTry = await authProvider.register(
        email: 'test@example.com',
        password: 'password456',
        name: 'Nguyen Van B',
      );

      expect(secondTry, false);
      expect(authProvider.errorMessage, 'EMAIL_IN_USE');
    });

    test('login with correct credentials succeeds', () async {
      await authProvider.register(
        email: 'user@domain.com',
        password: 'myPassword123',
        name: 'John Doe',
      );
      await authProvider.logout();
      expect(authProvider.isAuthenticated, false);

      final success = await authProvider.login(
        email: 'user@domain.com',
        password: 'myPassword123',
      );

      expect(success, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.currentUser?.name, 'John Doe');
    });

    test('login with wrong password fails', () async {
      await authProvider.register(
        email: 'user@domain.com',
        password: 'correctPassword',
        name: 'John Doe',
      );
      await authProvider.logout();

      final success = await authProvider.login(
        email: 'user@domain.com',
        password: 'wrongPassword',
      );

      expect(success, false);
      expect(authProvider.errorMessage, 'WRONG_PASSWORD');
    });

    test('logout clears user session', () async {
      await authProvider.register(
        email: 'user@domain.com',
        password: 'password123',
        name: 'User',
      );
      expect(authProvider.isAuthenticated, true);

      await authProvider.logout();
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, null);
    });
  });
}
