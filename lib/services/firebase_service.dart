import '../models/diary_entry.dart';
import '../models/sticker_data.dart';

/// Firebase Firestore와의 연동을 위한 추상 서비스 클래스
/// 향후 Firestore 구현 시 이 인터페이스를 구현하여 사용
abstract class FirebaseService {
  
  // DiaryEntry CRUD Operations
  
  /// 모든 일기 항목을 가져옵니다
  Future<List<DiaryEntry>> getAllDiaryEntries();

  /// 특정 ID의 일기 항목을 가져옵니다
  Future<DiaryEntry?> getDiaryEntryById(String id);

  /// 특정 날짜의 일기 항목들을 가져옵니다
  Future<List<DiaryEntry>> getDiaryEntriesByDate(DateTime date);

  /// 특정 사용자의 일기 항목들을 가져옵니다
  Future<List<DiaryEntry>> getDiaryEntriesByUserId(String userId);

  /// 날짜 범위에 해당하는 일기 항목들을 가져옵니다
  Future<List<DiaryEntry>> getDiaryEntriesByDateRange(DateTime startDate, DateTime endDate);

  /// 일기 항목을 저장합니다 (생성 또는 업데이트)
  Future<void> saveDiaryEntry(DiaryEntry entry);

  /// 일기 항목을 삭제합니다
  Future<void> deleteDiaryEntry(String id);

  /// 여러 일기 항목을 일괄 저장합니다
  Future<void> saveDiaryEntries(List<DiaryEntry> entries);

  // StickerData CRUD Operations

  /// 모든 스티커 데이터를 가져옵니다
  Future<List<StickerData>> getAllStickerData();

  /// 특정 ID의 스티커 데이터를 가져옵니다
  Future<StickerData?> getStickerDataById(String id);

  /// 특정 날짜의 스티커 데이터들을 가져옵니다
  Future<List<StickerData>> getStickerDataByDate(DateTime date);

  /// 특정 날짜 범위의 스티커 데이터들을 가져옵니다
  Future<List<StickerData>> getStickerDataByDateRange(DateTime startDate, DateTime endDate);

  /// 특정 사용자의 스티커 데이터들을 가져옵니다
  Future<List<StickerData>> getStickerDataByUserId(String userId);

  /// 스티커 데이터를 저장합니다 (생성 또는 업데이트)
  Future<void> saveStickerData(StickerData sticker);

  /// 스티커 데이터를 삭제합니다
  Future<void> deleteStickerData(String id);

  /// 여러 스티커 데이터를 일괄 저장합니다
  Future<void> saveStickerDataList(List<StickerData> stickerList);

  // Authentication & User Management

  /// 현재 사용자 ID를 가져옵니다
  Future<String?> getCurrentUserId();

  /// 사용자가 로그인되어 있는지 확인합니다
  Future<bool> isUserLoggedIn();

  /// 사용자를 로그아웃합니다
  Future<void> signOut();

  // Data Synchronization

  /// 로컬 데이터를 Firestore와 동기화합니다
  Future<void> syncWithLocal(List<DiaryEntry> localDiaryEntries, List<StickerData> localStickerData);

  /// Firestore에서 로컬로 데이터를 가져옵니다
  Future<Map<String, dynamic>> downloadDataFromFirestore();

  /// 로컬 데이터를 Firestore에 업로드합니다
  Future<void> uploadDataToFirestore(List<DiaryEntry> diaryEntries, List<StickerData> stickerData);

  // Utility Methods

  /// 모든 사용자 데이터를 삭제합니다
  Future<void> clearAllUserData();

  /// Firestore 연결 상태를 확인합니다
  Future<bool> isConnected();

  /// 저장소 상태 정보를 반환합니다
  Future<Map<String, dynamic>> getStorageInfo();

  /// 데이터 백업을 생성합니다
  Future<Map<String, dynamic>> createDataBackup();

  /// 백업 데이터를 복원합니다
  Future<void> restoreFromBackup(Map<String, dynamic> backupData);
}

/// FirebaseService의 기본 구현 (Stub)
/// 실제 Firestore 연결이 필요하기 전까지 사용하는 기본 구현
class FirebaseServiceStub implements FirebaseService {
  
  @override
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    // TODO: Firestore 구현 시 실제 로직으로 대체
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<DiaryEntry?> getDiaryEntryById(String id) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<List<DiaryEntry>> getDiaryEntriesByDate(DateTime date) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<List<DiaryEntry>> getDiaryEntriesByUserId(String userId) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<List<DiaryEntry>> getDiaryEntriesByDateRange(DateTime startDate, DateTime endDate) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<void> deleteDiaryEntry(String id) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<void> saveDiaryEntries(List<DiaryEntry> entries) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<List<StickerData>> getAllStickerData() async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<StickerData?> getStickerDataById(String id) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<List<StickerData>> getStickerDataByDate(DateTime date) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<List<StickerData>> getStickerDataByDateRange(DateTime startDate, DateTime endDate) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<List<StickerData>> getStickerDataByUserId(String userId) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<void> saveStickerData(StickerData sticker) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<void> deleteStickerData(String id) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<void> saveStickerDataList(List<StickerData> stickerList) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<String?> getCurrentUserId() async {
    throw UnimplementedError('Firebase Auth 연동이 필요합니다.');
  }

  @override
  Future<bool> isUserLoggedIn() async {
    throw UnimplementedError('Firebase Auth 연동이 필요합니다.');
  }

  @override
  Future<void> signOut() async {
    throw UnimplementedError('Firebase Auth 연동이 필요합니다.');
  }

  @override
  Future<void> syncWithLocal(List<DiaryEntry> localDiaryEntries, List<StickerData> localStickerData) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<Map<String, dynamic>> downloadDataFromFirestore() async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<void> uploadDataToFirestore(List<DiaryEntry> diaryEntries, List<StickerData> stickerData) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<void> clearAllUserData() async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<bool> isConnected() async {
    // Firebase가 연동되지 않았으므로 항상 false 반환
    return false;
  }

  @override
  Future<Map<String, dynamic>> getStorageInfo() async {
    return {
      'connected': false,
      'provider': 'firebase_stub',
      'message': 'Firebase Firestore 연동이 필요합니다.',
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> createDataBackup() async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }

  @override
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    throw UnimplementedError('Firebase Firestore 연동이 필요합니다.');
  }
}