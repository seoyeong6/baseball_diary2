import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  bool _isInitialized = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 현재 연결 상태 확인
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResults);
      
      // 연결 상태 변경 감지
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          debugPrint('ConnectivityService: Error listening to connectivity changes: $error');
        },
      );
      
      _isInitialized = true;
      debugPrint('ConnectivityService initialized. Current status: ${_isOnline ? "Online" : "Offline"}');
      
    } catch (e) {
      debugPrint('ConnectivityService: Failed to initialize: $e');
      // 초기화 실패 시 기본값으로 온라인 상태로 설정
      _isOnline = true;
      _isInitialized = true;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> connectivityResults) {
    final bool wasOnline = _isOnline;
    
    // 연결 결과가 없거나 none만 있으면 오프라인
    _isOnline = connectivityResults.isNotEmpty && 
                !connectivityResults.every((result) => result == ConnectivityResult.none);
    
    if (wasOnline != _isOnline) {
      debugPrint('ConnectivityService: Connection status changed to ${_isOnline ? "Online" : "Offline"}');
      notifyListeners();
    }
  }

  /// 현재 연결 상태를 강제로 확인
  Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResults);
      return _isOnline;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connection: $e');
      return _isOnline; // 에러 시 현재 상태 유지
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// 연결 상태 변경을 감지하는 mixin
mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  ConnectivityService? _connectivityService;
  
  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityService!.addListener(_onConnectivityChanged);
  }
  
  @override
  void dispose() {
    _connectivityService?.removeListener(_onConnectivityChanged);
    super.dispose();
  }
  
  void _onConnectivityChanged() {
    onConnectivityChanged(_connectivityService!.isOnline);
  }
  
  /// 연결 상태 변경 시 호출되는 메서드 (구현 필요)
  void onConnectivityChanged(bool isOnline);
  
  /// 현재 연결 상태 확인
  bool get isOnline => _connectivityService?.isOnline ?? true;
  bool get isOffline => !isOnline;
}