import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_user;

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  app_user.User? _currentUser;
  bool _isLoading = false;

  app_user.User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Firebase Auth 상태 변경 감지
      _auth.authStateChanges().listen(_onAuthStateChanged);
      
      // 현재 로그인된 사용자 확인
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        _currentUser = _firebaseUserToAppUser(firebaseUser);
      }
    } catch (e) {
      // Firebase 초기화 오류 처리
    }

    _isLoading = false;
    notifyListeners();
  }

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser != null) {
      _currentUser = _firebaseUserToAppUser(firebaseUser);
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  app_user.User _firebaseUserToAppUser(User firebaseUser) {
    return app_user.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Firebase로 계정 생성
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 사용자 프로필 업데이트 (displayName 설정)
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      // 현재 사용자 정보 업데이트
      final updatedUser = _auth.currentUser;
      if (updatedUser != null) {
        _currentUser = _firebaseUserToAppUser(updatedUser);
      }

      _isLoading = false;
      notifyListeners();
      return AuthResult.success(_currentUser!);
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('회원가입에 실패했습니다: $e');
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 현재 사용자 정보 업데이트 (authStateChanges에서 자동으로 처리됨)
      _isLoading = false;
      notifyListeners();
      return AuthResult.success(_currentUser!);
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('로그인에 실패했습니다: $e');
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      // Firebase 로그아웃 오류 처리
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('비밀번호 재설정에 실패했습니다: $e');
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 주소입니다.';
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '잘못된 비밀번호입니다.';
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'too-many-requests':
        return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return e.message ?? '알 수 없는 오류가 발생했습니다.';
    }
  }
}

class AuthResult {
  final bool success;
  final String? error;
  final app_user.User? user;

  const AuthResult._({
    required this.success,
    this.error,
    this.user,
  });

  factory AuthResult.success(app_user.User? user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }
}