import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';

class CalendarController extends ChangeNotifier {
  final DiaryService _diaryService = DiaryService();
  
  // Calendar state
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Event cache
  final Map<DateTime, List<DiaryEntry>> _eventCache = {};
  List<DiaryEntry> _selectedEvents = [];
  
  // Loading states
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  CalendarFormat get calendarFormat => _calendarFormat;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  List<DiaryEntry> get selectedEvents => _selectedEvents;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  CalendarController() {
    _selectedDay = _focusedDay;
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _diaryService.initialize();
      await _loadCalendarData();
      await _loadEventsForSelectedDay();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing calendar controller: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCalendarData() async {
    try {
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      _eventCache.clear();
      
      for (int day = 1; day <= lastDay.day; day++) {
        final date = DateTime(_focusedDay.year, _focusedDay.month, day);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final entries = await _getEventsForDay(date);
        _eventCache[normalizedDate] = entries;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
    }
  }

  Future<List<DiaryEntry>> _getEventsForDay(DateTime day) async {
    try {
      return await _diaryService.getDiaryEntriesByDate(day);
    } catch (e) {
      debugPrint('Error loading diary entries for $day: $e');
      return [];
    }
  }

  List<DiaryEntry> getCachedEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _eventCache[normalizedDate] ?? [];
  }

  Future<void> _loadEventsForSelectedDay() async {
    if (_selectedDay != null) {
      final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      if (_eventCache.containsKey(normalizedDate)) {
        _selectedEvents = _eventCache[normalizedDate]!;
      } else {
        final events = await _getEventsForDay(_selectedDay!);
        _eventCache[normalizedDate] = events;
        _selectedEvents = events;
      }
      notifyListeners();
    }
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      notifyListeners();
      _loadEventsForSelectedDay();
    }
  }

  void onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      _calendarFormat = format;
      notifyListeners();
    }
  }

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadCalendarData();
  }

  Future<void> updateDiaryEntry(DiaryEntry updatedEntry) async {
    try {
      await _diaryService.saveDiaryEntry(updatedEntry);
      
      // Update cache
      final normalizedDate = DateTime(updatedEntry.date.year, updatedEntry.date.month, updatedEntry.date.day);
      final currentEntries = _eventCache[normalizedDate] ?? [];
      final entryIndex = currentEntries.indexWhere((e) => e.id == updatedEntry.id);
      
      if (entryIndex != -1) {
        currentEntries[entryIndex] = updatedEntry;
      } else {
        currentEntries.add(updatedEntry);
      }
      
      _eventCache[normalizedDate] = currentEntries;
      
      // Update selected events if needed
      if (isSameDay(_selectedDay, updatedEntry.date)) {
        await _loadEventsForSelectedDay();
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating diary entry: $e');
      rethrow;
    }
  }

  Future<void> addNewDiaryEntry(DiaryEntry newEntry) async {
    try {
      await _diaryService.saveDiaryEntry(newEntry);
      
      // Update cache
      final normalizedDate = DateTime(newEntry.date.year, newEntry.date.month, newEntry.date.day);
      final currentEntries = List<DiaryEntry>.from(_eventCache[normalizedDate] ?? []);
      
      // 중복 확인 후 추가
      if (!currentEntries.any((e) => e.id == newEntry.id)) {
        currentEntries.add(newEntry);
      }
      _eventCache[normalizedDate] = currentEntries;
      
      // Update selected events if the new entry is for the selected day
      if (isSameDay(_selectedDay, newEntry.date)) {
        _selectedEvents = List<DiaryEntry>.from(currentEntries);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding new diary entry: $e');
      rethrow;
    }
  }

  Future<void> deleteDiaryEntry(String entryId) async {
    try {
      await _diaryService.deleteDiaryEntry(entryId);
      
      // Remove from cache
      for (final entries in _eventCache.values) {
        entries.removeWhere((e) => e.id == entryId);
      }
      
      // Remove from selected events
      _selectedEvents.removeWhere((e) => e.id == entryId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting diary entry: $e');
      rethrow;
    }
  }

  Future<void> refreshCalendar() async {
    await _loadCalendarData();
    await _loadEventsForSelectedDay();
  }
}