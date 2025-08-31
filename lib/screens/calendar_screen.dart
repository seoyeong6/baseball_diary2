import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';

/// 월간 캘린더 뷰와 일별 기록 표시, 스티커 기능이 포함된 캘린더 화면
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<DiaryEntry>> _selectedEvents;
  final DiaryService _diaryService = DiaryService();
  final Map<DateTime, List<DiaryEntry>> _eventCache = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(<DiaryEntry>[]);
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _diaryService.initialize();
    await _loadCalendarData();
    await _loadEventsForSelectedDay();
  }

  Future<void> _loadCalendarData() async {
    try {
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      _eventCache.clear();
      
      // 실제 데이터 로드
      for (int day = 1; day <= lastDay.day; day++) {
        final date = DateTime(_focusedDay.year, _focusedDay.month, day);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final entries = await _getEventsForDay(date);
        _eventCache[normalizedDate] = entries;
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<List<DiaryEntry>> _getEventsForDay(DateTime day) async {
    try {
      return await _diaryService.getDiaryEntriesByDate(day);
    } catch (e) {
      debugPrint('Error loading diary entries for $day: $e');
      return [];
    }
  }

  List<DiaryEntry> _getCachedEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _eventCache[normalizedDate] ?? [];
  }

  Future<void> _loadEventsForSelectedDay() async {
    if (_selectedDay != null) {
      final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      if (_eventCache.containsKey(normalizedDate)) {
        _selectedEvents.value = _eventCache[normalizedDate]!;
      } else {
        final events = await _getEventsForDay(_selectedDay!);
        _eventCache[normalizedDate] = events;
        _selectedEvents.value = events;
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _loadEventsForSelectedDay();
    }
  }

  Widget _buildEmotionIcon(Emotion emotion, {required double size, required Color color}) {
    final iconData = emotion.fallbackIcon;
    
    // FontAwesome 아이콘인지 확인
    if (iconData == FontAwesomeIcons.faceGrinSquint || iconData == FontAwesomeIcons.faceSadTear) {
      return Container(
        width: size + 4,
        height: size + 4,
        alignment: Alignment.center,
        child: FaIcon(
          iconData,
          size: size * 0.85, // FaIcon을 85%로 축소해서 Material Icon과 시각적 크기 맞춤
          color: color,
        ),
      );
    }
    
    // Material 아이콘인 경우
    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, DateTime focusedDay) {
    final theme = Theme.of(context);
    final entries = _getCachedEventsForDay(day);
    
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (entries.isNotEmpty)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: entries.first.emotion.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.surface, width: 1),
                ),
                child: _buildEmotionIcon(
                  entries.first.emotion,
                  size: 15,
                  color: theme.colorScheme.surface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayCell(BuildContext context, DateTime day, DateTime focusedDay) {
    final theme = Theme.of(context);
    final entries = _getCachedEventsForDay(day);
    
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (entries.isNotEmpty)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: entries.first.emotion.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.surface, width: 1),
                ),
                child: _buildEmotionIcon(
                  entries.first.emotion,
                  size: 15,
                  color: theme.colorScheme.surface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodayCell(BuildContext context, DateTime day, DateTime focusedDay) {
    final theme = Theme.of(context);
    final entries = _getCachedEventsForDay(day);
    
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (entries.isNotEmpty)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: entries.first.emotion.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.surface, width: 1),
                ),
                child: _buildEmotionIcon(
                  entries.first.emotion,
                  size: 15,
                  color: theme.colorScheme.surface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '캘린더',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 캘린더 위젯
          TableCalendar<DiaryEntry>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: _getCachedEventsForDay,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(context, day, focusedDay);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildSelectedDayCell(context, day, focusedDay);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildTodayCell(context, day, focusedDay);
              },
            ),
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.twoWeeks: '2 weeks',
              CalendarFormat.week: 'Week',
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: theme.colorScheme.error),
              holidayTextStyle: TextStyle(color: theme.colorScheme.error),
              selectedDecoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              formatButtonTextStyle: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadCalendarData(); // Reload data for new month
            },
          ),
          
          const SizedBox(height: 8),
          
          // 선택된 날짜의 이벤트 목록
          Expanded(
            child: ValueListenableBuilder<List<DiaryEntry>>(
              valueListenable: _selectedEvents,
              builder: (context, entries, _) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      '이 날짜에는 기록이 없습니다',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () => debugPrint('Tapped diary entry: ${entry.title}'),
                        title: Text(entry.title),
                        subtitle: entry.content.length > 50 
                          ? Text('${entry.content.substring(0, 50)}...') 
                          : Text(entry.content),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: entry.emotion.color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: _buildEmotionIcon(
                            entry.emotion,
                            size: 20,
                            color: entry.emotion.color,
                          ),
                        ),
                        trailing: Text(
                          entry.emotion.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: entry.emotion.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // 새 일기 추가 플로팅 버튼
      floatingActionButton: FloatingActionButton(
        heroTag: "calendar_fab",
        onPressed: () {
          // TODO: 일기 작성 화면으로 이동
          debugPrint('Add new diary entry for ${_selectedDay?.toString()}');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}