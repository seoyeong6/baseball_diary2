import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../models/sticker_data.dart';
import 'auth_service.dart';
import 'local_storage_service.dart';
import 'firebase_service.dart';

/// 야구 다이어리 데이터를 관리하는 통합 서비스
/// 로그인 상태에 따라 로컬 저장소 또는 Firebase를 사용
class DiaryService extends ChangeNotifier {
  static final DiaryService _instance = DiaryService._internal();
  factory DiaryService() => _instance;
  DiaryService._internal();

  final AuthService _authService = AuthService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final FirebaseService _firebaseService = FirebaseServiceStub();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _lastError;
  bool _dataCleared = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isUsingCloudStorage => _authService.isAuthenticated;
  bool get dataCleared => _dataCleared;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // AuthService 초기화 확인
      if (!_authService.isAuthenticated && _authService.currentUser == null) {
        await _authService.initialize();
      }

      // 로그인된 사용자가 있다면 클라우드 데이터와 동기화 시도
      if (_authService.isAuthenticated) {
        await _attemptCloudSync();
      }

      _isInitialized = true;
    } catch (e) {
      _lastError = '서비스 초기화 실패: $e';
      debugPrint('DiaryService initialization error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 클라우드 동기화 시도
  Future<void> _attemptCloudSync() async {
    try {
      // Firebase 연결 상태 확인
      final isConnected = await _firebaseService.isConnected();
      if (!isConnected) {
        debugPrint('Firebase not connected, using local storage only');
        return;
      }

      // 로컬 데이터 가져오기
      final localDiaryEntries = await _localStorageService.getAllDiaryEntries();
      final localStickerData = await _localStorageService.getAllStickerData();

      // Firebase와 동기화
      await _firebaseService.syncWithLocal(localDiaryEntries, localStickerData);
    } catch (e) {
      debugPrint('Cloud sync failed: $e');
      // 동기화 실패는 치명적 오류가 아니므로 계속 진행
    }
  }

  // DiaryEntry CRUD Operations

  /// 모든 일기 항목을 가져옵니다
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    await _ensureInitialized();
    
    try {
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          return await _firebaseService.getAllDiaryEntries();
        }
      }
      return await _localStorageService.getAllDiaryEntries();
    } catch (e) {
      _lastError = '일기 항목을 불러오는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 특정 ID의 일기 항목을 가져옵니다
  Future<DiaryEntry?> getDiaryEntryById(String id) async {
    await _ensureInitialized();
    
    try {
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          return await _firebaseService.getDiaryEntryById(id);
        }
      }
      return await _localStorageService.getDiaryEntryById(id);
    } catch (e) {
      _lastError = '일기 항목을 찾는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 특정 날짜의 일기 항목들을 가져옵니다
  Future<List<DiaryEntry>> getDiaryEntriesByDate(DateTime date) async {
    await _ensureInitialized();
    
    try {
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          return await _firebaseService.getDiaryEntriesByDate(date);
        }
      }
      return await _localStorageService.getDiaryEntriesByDate(date);
    } catch (e) {
      _lastError = '해당 날짜의 일기 항목을 불러오는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 일기 항목을 저장합니다 (생성 또는 업데이트)
  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    await _ensureInitialized();
    
    _isLoading = true;
    notifyListeners();

    try {
      // 로컬에 먼저 저장 (오프라인 지원)
      await _localStorageService.saveDiaryEntry(entry);

      // 클라우드 저장소 사용 시 동기화 시도
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          await _firebaseService.saveDiaryEntry(entry);
        }
      }
    } catch (e) {
      _lastError = '일기 항목을 저장하는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 일기 항목을 삭제합니다
  Future<void> deleteDiaryEntry(String id) async {
    await _ensureInitialized();
    
    _isLoading = true;
    notifyListeners();

    try {
      // 로컬에서 먼저 삭제
      await _localStorageService.deleteDiaryEntry(id);

      // 클라우드 저장소 사용 시 동기화 시도
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          await _firebaseService.deleteDiaryEntry(id);
        }
      }
    } catch (e) {
      _lastError = '일기 항목을 삭제하는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // StickerData CRUD Operations

  /// 모든 스티커 데이터를 가져옵니다
  Future<List<StickerData>> getAllStickerData() async {
    await _ensureInitialized();
    
    try {
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          return await _firebaseService.getAllStickerData();
        }
      }
      return await _localStorageService.getAllStickerData();
    } catch (e) {
      _lastError = '스티커 데이터를 불러오는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 특정 ID의 스티커 데이터를 가져옵니다
  Future<StickerData?> getStickerDataById(String id) async {
    await _ensureInitialized();
    
    try {
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          return await _firebaseService.getStickerDataById(id);
        }
      }
      return await _localStorageService.getStickerDataById(id);
    } catch (e) {
      _lastError = '스티커 데이터를 찾는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 특정 날짜의 스티커 데이터들을 가져옵니다
  Future<List<StickerData>> getStickerDataByDate(DateTime date) async {
    await _ensureInitialized();
    
    try {
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          return await _firebaseService.getStickerDataByDate(date);
        }
      }
      return await _localStorageService.getStickerDataByDate(date);
    } catch (e) {
      _lastError = '해당 날짜의 스티커 데이터를 불러오는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 특정 날짜 범위의 스티커 데이터들을 가져옵니다
  Future<List<StickerData>> getStickerDataByDateRange(DateTime startDate, DateTime endDate) async {
    await _ensureInitialized();
    
    try {
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          return await _firebaseService.getStickerDataByDateRange(startDate, endDate);
        }
      }
      return await _localStorageService.getStickerDataByDateRange(startDate, endDate);
    } catch (e) {
      _lastError = '해당 기간의 스티커 데이터를 불러오는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 스티커 데이터를 저장합니다 (생성 또는 업데이트)
  Future<void> saveStickerData(StickerData sticker) async {
    await _ensureInitialized();
    
    _isLoading = true;
    notifyListeners();

    try {
      // 로컬에 먼저 저장
      await _localStorageService.saveStickerData(sticker);

      // 클라우드 저장소 사용 시 동기화 시도
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          await _firebaseService.saveStickerData(sticker);
        }
      }
    } catch (e) {
      _lastError = '스티커 데이터를 저장하는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 스티커 데이터를 삭제합니다
  Future<void> deleteStickerData(String id) async {
    await _ensureInitialized();
    
    _isLoading = true;
    notifyListeners();

    try {
      // 로컬에서 먼저 삭제
      await _localStorageService.deleteStickerData(id);

      // 클라우드 저장소 사용 시 동기화 시도
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          await _firebaseService.deleteStickerData(id);
        }
      }
    } catch (e) {
      _lastError = '스티커 데이터를 삭제하는데 실패했습니다: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Authentication Integration

  /// 사용자 로그인 시 호출되어야 하는 메서드
  /// 로컬 데이터를 클라우드로 동기화
  Future<void> onUserSignedIn() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 클라우드 동기화 시도
      await _attemptCloudSync();
    } catch (e) {
      _lastError = '로그인 후 동기화에 실패했습니다: $e';
      debugPrint('Sign-in sync error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자 로그아웃 시 호출되어야 하는 메서드
  /// 클라우드 데이터를 로컬에 백업 후 로컬 모드로 전환
  Future<void> onUserSignedOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 현재 클라우드 데이터가 있다면 로컬에 백업
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          final cloudDiaryEntries = await _firebaseService.getAllDiaryEntries();
          final cloudStickerData = await _firebaseService.getAllStickerData();

          // 로컬에 저장
          for (final entry in cloudDiaryEntries) {
            await _localStorageService.saveDiaryEntry(entry);
          }
          for (final sticker in cloudStickerData) {
            await _localStorageService.saveStickerData(sticker);
          }
        }
      }
    } catch (e) {
      _lastError = '로그아웃 시 데이터 백업에 실패했습니다: $e';
      debugPrint('Sign-out backup error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Utility Methods

  /// 수동으로 클라우드와 동기화
  Future<void> syncWithCloud() async {
    if (!isUsingCloudStorage) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _attemptCloudSync();
    } catch (e) {
      _lastError = '클라우드 동기화에 실패했습니다: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 모든 데이터를 삭제합니다 (로컬 및 클라우드)
  Future<void> clearAllData() async {
    await _ensureInitialized();
    
    _isLoading = true;
    notifyListeners();

    try {
      // 로컬 데이터 삭제
      await _localStorageService.clearAllData();

      // 클라우드 데이터 삭제 (로그인된 경우)
      if (isUsingCloudStorage) {
        final isConnected = await _firebaseService.isConnected();
        if (isConnected) {
          await _firebaseService.clearAllUserData();
        }
      }
      
      // 데이터 삭제 완료 플래그 설정
      _dataCleared = true;
    } catch (e) {
      _lastError = '데이터 삭제에 실패했습니다: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 저장소 상태 정보를 반환합니다
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final localInfo = await _localStorageService.getStorageInfo();
      
      Map<String, dynamic> cloudInfo = {};
      if (isUsingCloudStorage) {
        try {
          cloudInfo = await _firebaseService.getStorageInfo();
        } catch (e) {
          cloudInfo = {'error': 'Cloud storage info unavailable: $e'};
        }
      }

      return {
        'initialized': _isInitialized,
        'usingCloudStorage': isUsingCloudStorage,
        'currentUser': _authService.currentUser?.toJson(),
        'local': localInfo,
        'cloud': cloudInfo.isEmpty ? null : cloudInfo,
        'lastError': _lastError,
      };
    } catch (e) {
      return {
        'error': '저장소 정보를 불러오는데 실패했습니다: $e',
        'initialized': _isInitialized,
        'usingCloudStorage': isUsingCloudStorage,
      };
    }
  }

  /// 데이터 백업을 생성합니다
  Future<Map<String, dynamic>> createDataBackup() async {
    await _ensureInitialized();

    try {
      final diaryEntries = await getAllDiaryEntries();
      final stickerData = await getAllStickerData();

      return {
        'version': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'userInfo': _authService.currentUser?.toJson(),
        'diaryEntries': diaryEntries.map((e) => e.toJson()).toList(),
        'stickerData': stickerData.map((s) => s.toJson()).toList(),
      };
    } catch (e) {
      throw Exception('데이터 백업 생성에 실패했습니다: $e');
    }
  }

  /// 백업 데이터를 복원합니다
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    await _ensureInitialized();

    _isLoading = true;
    notifyListeners();

    try {
      // 기존 데이터 삭제
      await clearAllData();

      // 백업 데이터 복원
      if (backupData['diaryEntries'] != null) {
        final diaryEntriesData = backupData['diaryEntries'] as List;
        for (final entryData in diaryEntriesData) {
          final entry = DiaryEntry.fromJson(entryData as Map<String, dynamic>);
          await saveDiaryEntry(entry);
        }
      }

      if (backupData['stickerData'] != null) {
        final stickerDataList = backupData['stickerData'] as List;
        for (final stickerData in stickerDataList) {
          final sticker = StickerData.fromJson(stickerData as Map<String, dynamic>);
          await saveStickerData(sticker);
        }
      }
    } catch (e) {
      _lastError = '백업 복원에 실패했습니다: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 초기화 확인
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 데이터 삭제 플래그 리셋
  void resetDataClearedFlag() {
    _dataCleared = false;
  }
}