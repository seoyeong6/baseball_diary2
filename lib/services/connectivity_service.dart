import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// 네트워크 연결 상태를 관리하는 서비스
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _initialize();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  /// 현재 연결 상태
  bool get isConnected => _isConnected;

  /// 현재 연결 타입
  ConnectivityResult get connectionStatus => _connectionStatus;

  /// WiFi 연결 여부
  bool get isWifi => _connectionStatus == ConnectivityResult.wifi;

  /// 모바일 데이터 연결 여부
  bool get isMobile => _connectionStatus == ConnectivityResult.mobile;

  /// 이더넷 연결 여부
  bool get isEthernet => _connectionStatus == ConnectivityResult.ethernet;

  /// 초기화
  void _initialize() {
    // 초기 연결 상태 확인
    _checkConnectivity();

    // 연결 상태 변경 감지
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen(_updateConnectionStatus);
  }

  /// 연결 상태 확인
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Failed to check connectivity: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  /// 연결 상태 업데이트
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (result.isEmpty) {
      _connectionStatus = ConnectivityResult.none;
      _isConnected = false;
    } else {
      _connectionStatus = result.first;
      _isConnected = _connectionStatus != ConnectivityResult.none;
    }

    debugPrint('Network status changed: $_connectionStatus (connected: $_isConnected)');
    notifyListeners();
  }

  /// 수동으로 연결 상태 확인
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isConnected;
    } catch (e) {
      debugPrint('Failed to check connection: $e');
      return false;
    }
  }

  /// 연결 상태 문자열 반환
  String getConnectionStatusString() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return '모바일 데이터';
      case ConnectivityResult.ethernet:
        return '이더넷';
      case ConnectivityResult.none:
        return '연결 없음';
      case ConnectivityResult.bluetooth:
        return '블루투스';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return '기타';
    }
  }

  /// 리소스 정리
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}