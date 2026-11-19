import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quiz_bilingual/data/models/user_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/auth_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/auth_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/language_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/screens/login_screen.dart';
import 'package:flutter_quiz_bilingual/presentation/screens/register_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeAuthRepo implements IAuthRepository {
  UserModel? user;

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    user = UserModel(
      id: '1',
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );
    return user!;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    user = UserModel(
      id: '1',
      email: email,
      name: 'User',
      createdAt: DateTime.now(),
    );
    return user!;
  }

  @override
  Future<void> logout() async {
    user = null;
  }
}

void main() {
  testWidgets('LoginScreen renders email and password fields', (tester) async {
    final repo = _FakeAuthRepo();
    final authProvider = AuthProvider(repository: repo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          supportedLocales: [Locale('vi'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Đăng nhập tài khoản'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('RegisterScreen renders full name, email, password and confirm fields', (tester) async {
    final repo = _FakeAuthRepo();
    final authProvider = AuthProvider(repository: repo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          supportedLocales: [Locale('vi'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: RegisterScreen(),
        ),
      ),
    );

    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });
}
