import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../models/sticker_data.dart';
import 'firebase_service.dart';

/// Firebase Firestore를 사용한 FirebaseService 실제 구현
class FirestoreService implements FirebaseService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection 이름 상수
  static const String _diariesCollection = 'diaries';
  static const String _stickersCollection = 'stickers';
  static const String _usersCollection = 'users';

  // Helper method to get user-specific collection reference
  CollectionReference<Map<String, dynamic>>? _getUserDiariesRef() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection(_usersCollection).doc(userId).collection(_diariesCollection);
  }

  CollectionReference<Map<String, dynamic>>? _getUserStickersRef() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection(_usersCollection).doc(userId).collection(_stickersCollection);
  }

  // DiaryEntry CRUD Operations

  @override
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    try {
      final diariesRef = _getUserDiariesRef();
      if (diariesRef == null) {
        debugPrint('Warning: User not authenticated, returning empty list');
        return [];
      }

      final querySnapshot = await diariesRef.get();
      return querySnapshot.docs
          .map((doc) => DiaryEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting all diary entries: $e');
      return [];
    }
  }

  @override
  Future<DiaryEntry?> getDiaryEntryById(String id) async {
    try {
      final diariesRef = _getUserDiariesRef();
      if (diariesRef == null) {
        debugPrint('Warning: User not authenticated for getDiaryEntryById');
        return null;
      }

      final docSnapshot = await diariesRef.doc(id).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return DiaryEntry.fromJson({...docSnapshot.data()!, 'id': docSnapshot.id});
      }
      debugPrint('Diary entry not found with ID: $id');
      return null;
    } catch (e) {
      debugPrint('Error getting diary entry by ID $id: $e');
      return null;
    }
  }

  @override
  Future<List<DiaryEntry>> getDiaryEntriesByDate(DateTime date) async {
    try {
      final diariesRef = _getUserDiariesRef();
      if (diariesRef == null) {
        debugPrint('Warning: User not authenticated for getDiaryEntriesByDate');
        return [];
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      final querySnapshot = await diariesRef
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      return querySnapshot.docs
          .map((doc) => DiaryEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting diary entries by date ${date.toIso8601String()}: $e');
      return [];
    }
  }

  @override
  Future<List<DiaryEntry>> getDiaryEntriesByUserId(String userId) async {
    // 이미 사용자별로 분리된 컬렉션을 사용하므로 getAllDiaryEntries와 동일
    return getAllDiaryEntries();
  }

  @override
  Future<List<DiaryEntry>> getDiaryEntriesByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final diariesRef = _getUserDiariesRef();
      if (diariesRef == null) {
        debugPrint('Warning: User not authenticated for getDiaryEntriesByDateRange');
        return [];
      }

      final querySnapshot = await diariesRef
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      return querySnapshot.docs
          .map((doc) => DiaryEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting diary entries by date range ${startDate.toIso8601String()} - ${endDate.toIso8601String()}: $e');
      return [];
    }
  }

  @override
  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    try {
      final diariesRef = _getUserDiariesRef();
      if (diariesRef == null) {
        throw Exception('User not authenticated');
      }

      final data = entry.toJson();
      data.remove('id'); // Firestore에서는 ID를 데이터에 포함하지 않음

      await diariesRef.doc(entry.id).set(data);
      debugPrint('Diary entry saved: ${entry.id}');
    } catch (e) {
      debugPrint('Error saving diary entry: $e');
      rethrow;
    }
  }

  /// 다이어리 엔트리의 특정 필드만 업데이트
  Future<void> updateDiaryEntry(String id, Map<String, dynamic> updates) async {
    try {
      final diariesRef = _getUserDiariesRef();
      if (diariesRef == null) {
        throw Exception('User not authenticated');
      }

      // ID 필드가 포함되어 있으면 제거
      final updateData = Map<String, dynamic>.from(updates);
      updateData.remove('id');

      await diariesRef.doc(id).update(updateData);
      debugPrint('Diary entry updated: $id');
    } catch (e) {
      debugPrint('Error updating diary entry: $e');
      rethrow;
    }
  }

  /// 새로운 다이어리 엔트리 생성 (자동 ID 생성)
  Future<String> createDiaryEntry(DiaryEntry entry) async {
    try {
      final diariesRef = _getUserDiariesRef();
      if (diariesRef == null) {
        throw Exception('User not authenticated');
      }

      final data = entry.toJson();
      data.remove('id');

      final docRef = await diariesRef.add(data);
      debugPrint('Diary entry created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating diary entry: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteDiaryEntry(String id) async {
    try {
      final diariesRef = _getUserDiariesRef();
      if (diariesRef == null) {
        throw Exception('User not authenticated');
      }

      await diariesRef.doc(id).delete();
      debugPrint('Diary entry deleted: $id');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveDiaryEntries(List<DiaryEntry> entries) async {
    try {
      final diariesRef = _getUserDiariesRef();
      if (diariesRef == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      for (final entry in entries) {
        final data = entry.toJson();
        data.remove('id');
        batch.set(diariesRef.doc(entry.id), data);
      }
      await batch.commit();
      debugPrint('${entries.length} diary entries saved in batch');
    } catch (e) {
      rethrow;
    }
  }

  // StickerData CRUD Operations

  @override
  Future<List<StickerData>> getAllStickerData() async {
    try {
      final stickersRef = _getUserStickersRef();
      if (stickersRef == null) {
        debugPrint('Warning: User not authenticated, returning empty sticker list');
        return [];
      }

      final querySnapshot = await stickersRef.get();
      return querySnapshot.docs
          .map((doc) => StickerData.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting all sticker data: $e');
      return [];
    }
  }

  @override
  Future<StickerData?> getStickerDataById(String id) async {
    try {
      final stickersRef = _getUserStickersRef();
      if (stickersRef == null) {
        debugPrint('Warning: User not authenticated for getStickerDataById');
        return null;
      }

      final docSnapshot = await stickersRef.doc(id).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return StickerData.fromJson({...docSnapshot.data()!, 'id': docSnapshot.id});
      }
      debugPrint('Sticker data not found with ID: $id');
      return null;
    } catch (e) {
      debugPrint('Error getting sticker data by ID $id: $e');
      return null;
    }
  }

  @override
  Future<List<StickerData>> getStickerDataByDate(DateTime date) async {
    try {
      final stickersRef = _getUserStickersRef();
      if (stickersRef == null) {
        debugPrint('Warning: User not authenticated for getStickerDataByDate');
        return [];
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      final querySnapshot = await stickersRef
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      return querySnapshot.docs
          .map((doc) => StickerData.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting sticker data by date ${date.toIso8601String()}: $e');
      return [];
    }
  }

  @override
  Future<List<StickerData>> getStickerDataByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final stickersRef = _getUserStickersRef();
      if (stickersRef == null) {
        debugPrint('Warning: User not authenticated for getStickerDataByDateRange');
        return [];
      }

      final querySnapshot = await stickersRef
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      return querySnapshot.docs
          .map((doc) => StickerData.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting sticker data by date range ${startDate.toIso8601String()} - ${endDate.toIso8601String()}: $e');
      return [];
    }
  }

  @override
  Future<List<StickerData>> getStickerDataByUserId(String userId) async {
    // 이미 사용자별로 분리된 컬렉션을 사용하므로 getAllStickerData와 동일
    return getAllStickerData();
  }

  @override
  Future<void> saveStickerData(StickerData sticker) async {
    try {
      final stickersRef = _getUserStickersRef();
      if (stickersRef == null) {
        throw Exception('User not authenticated');
      }

      final data = sticker.toJson();
      data.remove('id');

      await stickersRef.doc(sticker.id).set(data);
      debugPrint('Sticker data saved: ${sticker.id}');
    } catch (e) {
      debugPrint('Error saving sticker data: $e');
      rethrow;
    }
  }

  /// 스티커 데이터의 특정 필드만 업데이트
  Future<void> updateStickerData(String id, Map<String, dynamic> updates) async {
    try {
      final stickersRef = _getUserStickersRef();
      if (stickersRef == null) {
        throw Exception('User not authenticated');
      }

      // ID 필드가 포함되어 있으면 제거
      final updateData = Map<String, dynamic>.from(updates);
      updateData.remove('id');

      await stickersRef.doc(id).update(updateData);
      debugPrint('Sticker data updated: $id');
    } catch (e) {
      debugPrint('Error updating sticker data: $e');
      rethrow;
    }
  }

  /// 새로운 스티커 데이터 생성 (자동 ID 생성)
  Future<String> createStickerData(StickerData sticker) async {
    try {
      final stickersRef = _getUserStickersRef();
      if (stickersRef == null) {
        throw Exception('User not authenticated');
      }

      final data = sticker.toJson();
      data.remove('id');

      final docRef = await stickersRef.add(data);
      debugPrint('Sticker data created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating sticker data: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteStickerData(String id) async {
    try {
      final stickersRef = _getUserStickersRef();
      if (stickersRef == null) {
        throw Exception('User not authenticated');
      }

      await stickersRef.doc(id).delete();
      debugPrint('Sticker data deleted: $id');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveStickerDataList(List<StickerData> stickerList) async {
    try {
      final stickersRef = _getUserStickersRef();
      if (stickersRef == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      for (final sticker in stickerList) {
        final data = sticker.toJson();
        data.remove('id');
        batch.set(stickersRef.doc(sticker.id), data);
      }
      await batch.commit();
      debugPrint('${stickerList.length} sticker data saved in batch');
    } catch (e) {
      rethrow;
    }
  }

  // Authentication & User Management

  @override
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  @override
  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('User signed out successfully');
    } catch (e) {
      rethrow;
    }
  }

  // Data Synchronization

  @override
  Future<void> syncWithLocal(List<DiaryEntry> localDiaryEntries, List<StickerData> localStickerData) async {
    try {
      if (!await isUserLoggedIn()) {
        throw Exception('User not authenticated');
      }

      // Upload local data to Firestore
      await uploadDataToFirestore(localDiaryEntries, localStickerData);
      
      debugPrint('Local data synced with Firestore');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> downloadDataFromFirestore() async {
    try {
      if (!await isUserLoggedIn()) {
        throw Exception('User not authenticated');
      }

      final diaryEntries = await getAllDiaryEntries();
      final stickerData = await getAllStickerData();

      return {
        'diaryEntries': diaryEntries.map((e) => e.toJson()).toList(),
        'stickerData': stickerData.map((s) => s.toJson()).toList(),
        'downloadedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> uploadDataToFirestore(List<DiaryEntry> diaryEntries, List<StickerData> stickerData) async {
    try {
      if (!await isUserLoggedIn()) {
        throw Exception('User not authenticated');
      }

      // Upload diary entries
      if (diaryEntries.isNotEmpty) {
        await saveDiaryEntries(diaryEntries);
      }

      // Upload sticker data
      if (stickerData.isNotEmpty) {
        await saveStickerDataList(stickerData);
      }

      debugPrint('Data uploaded to Firestore: ${diaryEntries.length} diaries, ${stickerData.length} stickers');
    } catch (e) {
      rethrow;
    }
  }

  // Utility Methods

  @override
  Future<void> clearAllUserData() async {
    try {
      if (!await isUserLoggedIn()) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      
      // Clear diary entries
      final diariesRef = _getUserDiariesRef();
      if (diariesRef != null) {
        final diaryDocs = await diariesRef.get();
        for (final doc in diaryDocs.docs) {
          batch.delete(doc.reference);
        }
      }

      // Clear sticker data
      final stickersRef = _getUserStickersRef();
      if (stickersRef != null) {
        final stickerDocs = await stickersRef.get();
        for (final doc in stickerDocs.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
      debugPrint('All user data cleared from Firestore');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      // Firestore 연결을 테스트하기 위해 간단한 쿼리 실행
      await _firestore.collection('_connection_test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final connected = await isConnected();
      final userLoggedIn = await isUserLoggedIn();
      final userId = await getCurrentUserId();

      int diaryCount = 0;
      int stickerCount = 0;

      if (userLoggedIn) {
        final diaries = await getAllDiaryEntries();
        final stickers = await getAllStickerData();
        diaryCount = diaries.length;
        stickerCount = stickers.length;
      }

      return {
        'connected': connected,
        'provider': 'firebase_firestore',
        'userLoggedIn': userLoggedIn,
        'userId': userId,
        'diaryCount': diaryCount,
        'stickerCount': stickerCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'connected': false,
        'provider': 'firebase_firestore',
        'error': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> createDataBackup() async {
    try {
      if (!await isUserLoggedIn()) {
        throw Exception('User not authenticated');
      }

      final data = await downloadDataFromFirestore();
      data['backupCreatedAt'] = DateTime.now().toIso8601String();
      data['version'] = '1.0';
      
      return data;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    try {
      if (!await isUserLoggedIn()) {
        throw Exception('User not authenticated');
      }

      // Clear existing data first
      await clearAllUserData();

      // Restore diary entries
      final diaryEntriesData = backupData['diaryEntries'] as List<dynamic>?;
      if (diaryEntriesData != null) {
        final diaryEntries = diaryEntriesData
            .map((data) => DiaryEntry.fromJson(data as Map<String, dynamic>))
            .toList();
        await saveDiaryEntries(diaryEntries);
      }

      // Restore sticker data
      final stickerDataList = backupData['stickerData'] as List<dynamic>?;
      if (stickerDataList != null) {
        final stickerData = stickerDataList
            .map((data) => StickerData.fromJson(data as Map<String, dynamic>))
            .toList();
        await saveStickerDataList(stickerData);
      }

      debugPrint('Data restored from backup successfully');
    } catch (e) {
      rethrow;
    }
  }
}