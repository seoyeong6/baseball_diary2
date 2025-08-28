import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  static const String _userKey = 'current_user';
  static const String _usersKey = 'registered_users';

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingUsers = await _getRegisteredUsers();

      if (existingUsers.any((userRecord) => userRecord['user']['email'] == email)) {
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure('User with this email already exists');
      }

      final hashedPassword = _hashPassword(password);
      final userId = _generateUserId();
      
      final newUser = User(
        id: userId,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      existingUsers.add({
        'user': newUser.toJson(),
        'password': hashedPassword,
      });

      await prefs.setString(_usersKey, jsonEncode(existingUsers));
      await _setCurrentUser(newUser);

      _isLoading = false;
      notifyListeners();
      return AuthResult.success(newUser);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('Sign up failed: $e');
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final existingUsers = await _getRegisteredUsers();
      final hashedPassword = _hashPassword(password);

      final userRecord = existingUsers.firstWhere(
        (record) => record['user']['email'] == email && record['password'] == hashedPassword,
        orElse: () => {},
      );

      if (userRecord.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure('Invalid email or password');
      }

      final user = User.fromJson(userRecord['user']);
      await _setCurrentUser(user);

      _isLoading = false;
      notifyListeners();
      return AuthResult.success(user);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      _currentUser = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _currentUser = user;
  }

  Future<List<Map<String, dynamic>>> _getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    
    if (usersJson == null) {
      return [];
    }

    final usersData = jsonDecode(usersJson) as List;
    return usersData.cast<Map<String, dynamic>>();
  }

  String _hashPassword(String password) {
    const salt = 'baseball_diary_salt';
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateUserId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }
}

class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  const AuthResult._({
    required this.success,
    this.error,
    this.user,
  });

  factory AuthResult.success(User user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }
}