import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../models/sticker_data.dart';

class LocalStorageService {
  static const String _diaryEntriesKey = 'diary_entries';
  static const String _stickerDataKey = 'sticker_data';

  // DiaryEntry CRUD Operations

  /// 모든 일기 항목을 가져옵니다
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_diaryEntriesKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => DiaryEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('일기 항목을 불러오는데 실패했습니다: $e');
    }
  }

  /// 특정 ID의 일기 항목을 가져옵니다
  Future<DiaryEntry?> getDiaryEntryById(String id) async {
    try {
      final entries = await getAllDiaryEntries();
      return entries.where((entry) => entry.id == id).firstOrNull;
    } catch (e) {
      throw Exception('일기 항목을 찾는데 실패했습니다: $e');
    }
  }

  /// 특정 날짜의 일기 항목들을 가져옵니다
  Future<List<DiaryEntry>> getDiaryEntriesByDate(DateTime date) async {
    try {
      final entries = await getAllDiaryEntries();
      return entries.where((entry) {
        return entry.date.year == date.year &&
               entry.date.month == date.month &&
               entry.date.day == date.day;
      }).toList();
    } catch (e) {
      throw Exception('해당 날짜의 일기 항목을 불러오는데 실패했습니다: $e');
    }
  }

  /// 일기 항목을 저장합니다 (생성 또는 업데이트)
  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    try {
      final entries = await getAllDiaryEntries();
      
      // 기존 항목이 있으면 업데이트, 없으면 추가
      final existingIndex = entries.indexWhere((e) => e.id == entry.id);
      
      if (existingIndex >= 0) {
        entries[existingIndex] = entry;
      } else {
        entries.add(entry);
      }

      await _saveDiaryEntries(entries);
    } catch (e) {
      throw Exception('일기 항목을 저장하는데 실패했습니다: $e');
    }
  }

  /// 일기 항목을 삭제합니다
  Future<void> deleteDiaryEntry(String id) async {
    try {
      final entries = await getAllDiaryEntries();
      entries.removeWhere((entry) => entry.id == id);
      await _saveDiaryEntries(entries);
    } catch (e) {
      throw Exception('일기 항목을 삭제하는데 실패했습니다: $e');
    }
  }

  /// 내부적으로 일기 항목 리스트를 저장합니다
  Future<void> _saveDiaryEntries(List<DiaryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_diaryEntriesKey, jsonString);
  }

  // StickerData CRUD Operations

  /// 모든 스티커 데이터를 가져옵니다
  Future<List<StickerData>> getAllStickerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_stickerDataKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => StickerData.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('스티커 데이터를 불러오는데 실패했습니다: $e');
    }
  }

  /// 특정 ID의 스티커 데이터를 가져옵니다
  Future<StickerData?> getStickerDataById(String id) async {
    try {
      final stickerList = await getAllStickerData();
      return stickerList.where((sticker) => sticker.id == id).firstOrNull;
    } catch (e) {
      throw Exception('스티커 데이터를 찾는데 실패했습니다: $e');
    }
  }

  /// 특정 날짜의 스티커 데이터들을 가져옵니다
  Future<List<StickerData>> getStickerDataByDate(DateTime date) async {
    try {
      final stickerList = await getAllStickerData();
      return stickerList.where((sticker) => sticker.isSameDate(date)).toList();
    } catch (e) {
      throw Exception('해당 날짜의 스티커 데이터를 불러오는데 실패했습니다: $e');
    }
  }

  /// 특정 날짜 범위의 스티커 데이터들을 가져옵니다
  Future<List<StickerData>> getStickerDataByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final stickerList = await getAllStickerData();
      return stickerList.where((sticker) {
        return sticker.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
               sticker.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      throw Exception('해당 기간의 스티커 데이터를 불러오는데 실패했습니다: $e');
    }
  }

  /// 스티커 데이터를 저장합니다 (생성 또는 업데이트)
  Future<void> saveStickerData(StickerData sticker) async {
    try {
      final stickerList = await getAllStickerData();
      
      // 기존 항목이 있으면 업데이트, 없으면 추가
      final existingIndex = stickerList.indexWhere((s) => s.id == sticker.id);
      
      if (existingIndex >= 0) {
        stickerList[existingIndex] = sticker;
      } else {
        stickerList.add(sticker);
      }

      await _saveStickerDataList(stickerList);
    } catch (e) {
      throw Exception('스티커 데이터를 저장하는데 실패했습니다: $e');
    }
  }

  /// 스티커 데이터를 삭제합니다
  Future<void> deleteStickerData(String id) async {
    try {
      final stickerList = await getAllStickerData();
      stickerList.removeWhere((sticker) => sticker.id == id);
      await _saveStickerDataList(stickerList);
    } catch (e) {
      throw Exception('스티커 데이터를 삭제하는데 실패했습니다: $e');
    }
  }

  /// 내부적으로 스티커 데이터 리스트를 저장합니다
  Future<void> _saveStickerDataList(List<StickerData> stickerList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(stickerList.map((s) => s.toJson()).toList());
    await prefs.setString(_stickerDataKey, jsonString);
  }

  // 유틸리티 메서드

  /// 모든 로컬 데이터를 삭제합니다 (초기화)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_diaryEntriesKey);
      await prefs.remove(_stickerDataKey);
    } catch (e) {
      throw Exception('데이터 초기화에 실패했습니다: $e');
    }
  }

  /// 저장된 일기 항목 개수를 반환합니다
  Future<int> getDiaryEntryCount() async {
    try {
      final entries = await getAllDiaryEntries();
      return entries.length;
    } catch (e) {
      return 0;
    }
  }

  /// 저장된 스티커 데이터 개수를 반환합니다
  Future<int> getStickerDataCount() async {
    try {
      final stickerList = await getAllStickerData();
      return stickerList.length;
    } catch (e) {
      return 0;
    }
  }

  /// 로컬 저장소 상태 정보를 반환합니다
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final diaryCount = await getDiaryEntryCount();
      final stickerCount = await getStickerDataCount();
      
      return {
        'diaryEntryCount': diaryCount,
        'stickerDataCount': stickerCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': '저장소 정보를 불러오는데 실패했습니다: $e',
        'diaryEntryCount': 0,
        'stickerDataCount': 0,
      };
    }
  }
}