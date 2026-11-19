import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthStorageDataSource {
  static const String _usersKey = 'registered_users_v1';
  static const String _activeSessionKey = 'active_user_session_v1';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_activeSessionKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = email.trim().toLowerCase();

    // Check existing users
    final usersJsonStr = prefs.getString(_usersKey) ?? '{}';
    final Map<String, dynamic> usersMap =
        jsonDecode(usersJsonStr) as Map<String, dynamic>;

    if (usersMap.containsKey(normalizedEmail)) {
      throw Exception('EMAIL_IN_USE');
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: normalizedEmail,
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    final userData = {
      'user': newUser.toJson(),
      'passwordHash': _hashPassword(password),
    };

    usersMap[normalizedEmail] = userData;
    await prefs.setString(_usersKey, jsonEncode(usersMap));

    // Auto login session
    await prefs.setString(_activeSessionKey, jsonEncode(newUser.toJson()));
    return newUser;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = email.trim().toLowerCase();

    final usersJsonStr = prefs.getString(_usersKey) ?? '{}';
    final Map<String, dynamic> usersMap =
        jsonDecode(usersJsonStr) as Map<String, dynamic>;

    if (!usersMap.containsKey(normalizedEmail)) {
      throw Exception('USER_NOT_FOUND');
    }

    final userData = usersMap[normalizedEmail] as Map<String, dynamic>;
    final storedHash = userData['passwordHash'] as String;

    if (storedHash != _hashPassword(password)) {
      throw Exception('WRONG_PASSWORD');
    }

    final userMap = userData['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userMap);

    // Save active session
    await prefs.setString(_activeSessionKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionKey);
  }
}
