import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../models/sticker_data.dart';
import 'local_storage_service.dart';
import 'firestore_service.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';

/// 동기화 상태
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
  conflict
}

/// 충돌 해결 전략
enum ConflictResolutionStrategy {
  keepLocal,    // 로컬 데이터를 유지
  keepRemote,   // 클라우드 데이터를 유지
  keepNewer,    // 더 최신 데이터를 유지
  merge,        // 데이터 병합
  askUser       // 사용자에게 선택 요청
}

/// 동기화 메타데이터
class SyncMetadata {
  final String id;
  final DateTime lastLocalUpdate;
  final DateTime lastRemoteUpdate;
  final DateTime lastSyncTime;
  final String checksum;
  final SyncStatus status;

  SyncMetadata({
    required this.id,
    required this.lastLocalUpdate,
    required this.lastRemoteUpdate,
    required this.lastSyncTime,
    required this.checksum,
    this.status = SyncStatus.idle,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lastLocalUpdate': lastLocalUpdate.toIso8601String(),
    'lastRemoteUpdate': lastRemoteUpdate.toIso8601String(),
    'lastSyncTime': lastSyncTime.toIso8601String(),
    'checksum': checksum,
    'status': status.toString(),
  };

  factory SyncMetadata.fromJson(Map<String, dynamic> json) => SyncMetadata(
    id: json['id'] as String,
    lastLocalUpdate: DateTime.parse(json['lastLocalUpdate'] as String),
    lastRemoteUpdate: DateTime.parse(json['lastRemoteUpdate'] as String),
    lastSyncTime: DateTime.parse(json['lastSyncTime'] as String),
    checksum: json['checksum'] as String,
    status: SyncStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => SyncStatus.idle,
    ),
  );
}

/// 충돌 정보
class ConflictInfo {
  final String id;
  final String type; // 'diary' or 'sticker'
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localUpdateTime;
  final DateTime remoteUpdateTime;
  final String description;

  ConflictInfo({
    required this.id,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.localUpdateTime,
    required this.remoteUpdateTime,
    required this.description,
  });

  bool get isLocalNewer => localUpdateTime.isAfter(remoteUpdateTime);
  bool get isRemoteNewer => remoteUpdateTime.isAfter(localUpdateTime);
}

/// 데이터 동기화 및 충돌 해결 서비스
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalStorageService _localStorageService = LocalStorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final AuthService _authService = AuthService();

  SyncStatus _syncStatus = SyncStatus.idle;
  final List<ConflictInfo> _conflicts = [];
  ConflictResolutionStrategy _defaultStrategy = ConflictResolutionStrategy.keepNewer;
  DateTime? _lastSyncTime;
  String? _lastError;

  // 동기화 메타데이터 저장소
  final Map<String, SyncMetadata> _syncMetadata = {};

  // Getters
  SyncStatus get syncStatus => _syncStatus;
  List<ConflictInfo> get conflicts => List.unmodifiable(_conflicts);
  bool get hasConflicts => _conflicts.isNotEmpty;
  ConflictResolutionStrategy get defaultStrategy => _defaultStrategy;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  bool get isSyncing => _syncStatus == SyncStatus.syncing;

  /// 기본 충돌 해결 전략 설정
  void setDefaultStrategy(ConflictResolutionStrategy strategy) {
    _defaultStrategy = strategy;
    notifyListeners();
  }

  /// 전체 데이터 동기화 수행
  Future<void> syncAll() async {
    if (!_authService.isAuthenticated) {
      debugPrint('Sync skipped: User not authenticated');
      return;
    }

    if (!_connectivityService.isConnected) {
      debugPrint('Sync skipped: No network connection');
      _lastError = '네트워크 연결이 없습니다';
      return;
    }

    _syncStatus = SyncStatus.syncing;
    _lastError = null;
    _conflicts.clear();
    notifyListeners();

    try {
      // 다이어리 엔트리 동기화
      await _syncDiaryEntries();

      // 스티커 데이터 동기화
      await _syncStickerData();

      // 충돌이 있는 경우 처리
      if (_conflicts.isNotEmpty) {
        _syncStatus = SyncStatus.conflict;
        await _resolveConflicts();
      }

      _lastSyncTime = DateTime.now();
      _syncStatus = SyncStatus.completed;

      // 동기화 메타데이터 저장
      await _saveSyncMetadata();

      debugPrint('Sync completed successfully at $_lastSyncTime');
    } catch (e) {
      _syncStatus = SyncStatus.failed;
      _lastError = '동기화 실패: $e';
      debugPrint('Sync failed: $e');
    } finally {
      notifyListeners();
    }
  }

  /// 다이어리 엔트리 동기화
  Future<void> _syncDiaryEntries() async {
    try {
      // 로컬 및 클라우드 데이터 가져오기
      final localEntries = await _localStorageService.getAllDiaryEntries();
      final remoteEntries = await _firestoreService.getAllDiaryEntries();

      // ID를 기준으로 맵 생성
      final localMap = {for (var e in localEntries) e.id: e};
      final remoteMap = {for (var e in remoteEntries) e.id: e};

      // 모든 고유 ID 수집
      final allIds = {...localMap.keys, ...remoteMap.keys};

      for (final id in allIds) {
        final localEntry = localMap[id];
        final remoteEntry = remoteMap[id];

        if (localEntry != null && remoteEntry == null) {
          // 로컬에만 존재: 클라우드에 업로드
          await _firestoreService.saveDiaryEntry(localEntry);
          debugPrint('Uploaded diary entry to cloud: $id');
        } else if (localEntry == null && remoteEntry != null) {
          // 클라우드에만 존재: 로컬에 다운로드
          await _localStorageService.saveDiaryEntry(remoteEntry);
          debugPrint('Downloaded diary entry from cloud: $id');
        } else if (localEntry != null && remoteEntry != null) {
          // 양쪽에 존재: 충돌 확인
          if (_hasConflict(localEntry, remoteEntry)) {
            _conflicts.add(ConflictInfo(
              id: id,
              type: 'diary',
              localData: localEntry.toJson(),
              remoteData: remoteEntry.toJson(),
              localUpdateTime: localEntry.date,
              remoteUpdateTime: remoteEntry.date,
              description: '일기 "${localEntry.title}"에 충돌이 발생했습니다',
            ));
            debugPrint('Conflict detected for diary entry: $id');
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing diary entries: $e');
      rethrow;
    }
  }

  /// 스티커 데이터 동기화
  Future<void> _syncStickerData() async {
    try {
      // 로컬 및 클라우드 데이터 가져오기
      final localStickers = await _localStorageService.getAllStickerData();
      final remoteStickers = await _firestoreService.getAllStickerData();

      // ID를 기준으로 맵 생성
      final localMap = {for (var s in localStickers) s.id: s};
      final remoteMap = {for (var s in remoteStickers) s.id: s};

      // 모든 고유 ID 수집
      final allIds = {...localMap.keys, ...remoteMap.keys};

      for (final id in allIds) {
        final localSticker = localMap[id];
        final remoteSticker = remoteMap[id];

        if (localSticker != null && remoteSticker == null) {
          // 로컬에만 존재: 클라우드에 업로드
          await _firestoreService.saveStickerData(localSticker);
          debugPrint('Uploaded sticker to cloud: $id');
        } else if (localSticker == null && remoteSticker != null) {
          // 클라우드에만 존재: 로컬에 다운로드
          await _localStorageService.saveStickerData(remoteSticker);
          debugPrint('Downloaded sticker from cloud: $id');
        } else if (localSticker != null && remoteSticker != null) {
          // 양쪽에 존재: 충돌 확인
          if (_hasStickerConflict(localSticker, remoteSticker)) {
            _conflicts.add(ConflictInfo(
              id: id,
              type: 'sticker',
              localData: localSticker.toJson(),
              remoteData: remoteSticker.toJson(),
              localUpdateTime: localSticker.date,
              remoteUpdateTime: remoteSticker.date,
              description: '${localSticker.date.toString().substring(0, 10)}의 스티커에 충돌이 발생했습니다',
            ));
            debugPrint('Conflict detected for sticker: $id');
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing sticker data: $e');
      rethrow;
    }
  }

  /// 다이어리 엔트리 충돌 확인
  bool _hasConflict(DiaryEntry local, DiaryEntry remote) {
    // 체크섬 비교 (간단한 구현: 내용 비교)
    final localChecksum = _calculateDiaryChecksum(local);
    final remoteChecksum = _calculateDiaryChecksum(remote);

    return localChecksum != remoteChecksum;
  }

  /// 스티커 충돌 확인
  bool _hasStickerConflict(StickerData local, StickerData remote) {
    // 체크섬 비교
    final localChecksum = _calculateStickerChecksum(local);
    final remoteChecksum = _calculateStickerChecksum(remote);

    return localChecksum != remoteChecksum;
  }

  /// 다이어리 체크섬 계산
  String _calculateDiaryChecksum(DiaryEntry entry) {
    // 간단한 체크섬: 주요 필드 결합
    return '${entry.title}_${entry.content}_${entry.emotion}_${entry.imagePath ?? ''}_${entry.teamId}';
  }

  /// 스티커 체크섬 계산
  String _calculateStickerChecksum(StickerData sticker) {
    // 간단한 체크섬: 주요 필드 결합
    return '${sticker.type}_${sticker.date.toIso8601String()}_${sticker.memo ?? ''}';
  }

  /// 충돌 해결
  Future<void> _resolveConflicts() async {
    for (final conflict in _conflicts) {
      await _resolveConflict(conflict, _defaultStrategy);
    }
    _conflicts.clear();
  }

  /// 개별 충돌 해결
  Future<void> _resolveConflict(ConflictInfo conflict, ConflictResolutionStrategy strategy) async {
    try {
      switch (strategy) {
        case ConflictResolutionStrategy.keepLocal:
          await _applyLocalData(conflict);
          break;
        case ConflictResolutionStrategy.keepRemote:
          await _applyRemoteData(conflict);
          break;
        case ConflictResolutionStrategy.keepNewer:
          if (conflict.isLocalNewer) {
            await _applyLocalData(conflict);
          } else {
            await _applyRemoteData(conflict);
          }
          break;
        case ConflictResolutionStrategy.merge:
          await _mergeData(conflict);
          break;
        case ConflictResolutionStrategy.askUser:
          // 사용자 선택 대기 (UI에서 처리)
          break;
      }
      debugPrint('Resolved conflict for ${conflict.type} ${conflict.id} using $strategy');
    } catch (e) {
      debugPrint('Error resolving conflict: $e');
      rethrow;
    }
  }

  /// 로컬 데이터 적용
  Future<void> _applyLocalData(ConflictInfo conflict) async {
    if (conflict.type == 'diary') {
      final entry = DiaryEntry.fromJson(conflict.localData);
      await _firestoreService.saveDiaryEntry(entry);
    } else if (conflict.type == 'sticker') {
      final sticker = StickerData.fromJson(conflict.localData);
      await _firestoreService.saveStickerData(sticker);
    }
  }

  /// 원격 데이터 적용
  Future<void> _applyRemoteData(ConflictInfo conflict) async {
    if (conflict.type == 'diary') {
      final entry = DiaryEntry.fromJson(conflict.remoteData);
      await _localStorageService.saveDiaryEntry(entry);
    } else if (conflict.type == 'sticker') {
      final sticker = StickerData.fromJson(conflict.remoteData);
      await _localStorageService.saveStickerData(sticker);
    }
  }

  /// 데이터 병합
  Future<void> _mergeData(ConflictInfo conflict) async {
    if (conflict.type == 'diary') {
      // 다이어리 병합 로직
      final localEntry = DiaryEntry.fromJson(conflict.localData);
      final remoteEntry = DiaryEntry.fromJson(conflict.remoteData);

      // 병합 규칙: 더 긴 내용 유지, 최신 이미지 사용
      final mergedEntry = DiaryEntry(
        id: localEntry.id,
        title: localEntry.title.length > remoteEntry.title.length
            ? localEntry.title
            : remoteEntry.title,
        content: localEntry.content.length > remoteEntry.content.length
            ? localEntry.content
            : remoteEntry.content,
        emotion: conflict.isLocalNewer ? localEntry.emotion : remoteEntry.emotion,
        imagePath: conflict.isLocalNewer
            ? localEntry.imagePath
            : remoteEntry.imagePath,
        date: conflict.isLocalNewer ? localEntry.date : remoteEntry.date,
        teamId: localEntry.teamId,
      );

      await _localStorageService.saveDiaryEntry(mergedEntry);
      await _firestoreService.saveDiaryEntry(mergedEntry);
    } else if (conflict.type == 'sticker') {
      // 스티커는 병합이 간단함 (최신 데이터 사용)
      if (conflict.isLocalNewer) {
        await _applyLocalData(conflict);
      } else {
        await _applyRemoteData(conflict);
      }
    }
  }

  /// 사용자가 선택한 충돌 해결 적용
  Future<void> resolveConflictWithUserChoice(String conflictId, ConflictResolutionStrategy strategy) async {
    final conflict = _conflicts.firstWhere((c) => c.id == conflictId);
    await _resolveConflict(conflict, strategy);
    _conflicts.removeWhere((c) => c.id == conflictId);

    if (_conflicts.isEmpty) {
      _syncStatus = SyncStatus.completed;
    }

    notifyListeners();
  }

  /// 동기화 메타데이터 저장
  Future<void> _saveSyncMetadata() async {
    try {
      final metadata = _syncMetadata.map((key, value) => MapEntry(key, value.toJson()));
      await _localStorageService.saveData('sync_metadata', metadata);
    } catch (e) {
      debugPrint('Error saving sync metadata: $e');
    }
  }

  /// 동기화 메타데이터 로드
  Future<void> _loadSyncMetadata() async {
    try {
      final data = await _localStorageService.getData('sync_metadata');
      if (data != null) {
        final Map<String, dynamic> metadata = data as Map<String, dynamic>;
        metadata.forEach((key, value) {
          _syncMetadata[key] = SyncMetadata.fromJson(value as Map<String, dynamic>);
        });
      }
    } catch (e) {
      debugPrint('Error loading sync metadata: $e');
    }
  }

  /// 수동 충돌 해결 UI를 위한 충돌 정보 가져오기
  ConflictInfo? getConflictById(String id) {
    try {
      return _conflicts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 모든 충돌 무시하고 로컬 데이터 유지
  Future<void> keepAllLocal() async {
    for (final conflict in _conflicts) {
      await _applyLocalData(conflict);
    }
    _conflicts.clear();
    _syncStatus = SyncStatus.completed;
    notifyListeners();
  }

  /// 모든 충돌 무시하고 클라우드 데이터 유지
  Future<void> keepAllRemote() async {
    for (final conflict in _conflicts) {
      await _applyRemoteData(conflict);
    }
    _conflicts.clear();
    _syncStatus = SyncStatus.completed;
    notifyListeners();
  }

  /// 동기화 상태 초기화
  void reset() {
    _syncStatus = SyncStatus.idle;
    _conflicts.clear();
    _lastError = null;
    notifyListeners();
  }

  /// 백그라운드 동기화 시작
  Future<void> startBackgroundSync({Duration interval = const Duration(minutes: 15)}) async {
    // 주기적으로 동기화 수행
    Future.doWhile(() async {
      await Future.delayed(interval);

      if (_authService.isAuthenticated && _connectivityService.isConnected) {
        await syncAll();
      }

      return true; // 계속 실행
    });
  }
}