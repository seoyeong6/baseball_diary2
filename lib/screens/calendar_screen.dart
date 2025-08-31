import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// 월간 캘린더 뷰와 일별 기록 표시, 스티커 기능이 포함된 캘린더 화면
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    // TODO: 실제 이벤트 데이터 연동
    // 현재는 임시 데이터
    if (day.day % 3 == 0) {
      return ['임시 일기 ${day.day}일'];
    }
    return [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
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
          TableCalendar<dynamic>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: _getEventsForDay,
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
            },
          ),
          
          const SizedBox(height: 8),
          
          // 선택된 날짜의 이벤트 목록
          Expanded(
            child: ValueListenableBuilder<List<dynamic>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
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
                        onTap: () => debugPrint('${value[index]}'),
                        title: Text('${value[index]}'),
                        leading: Icon(
                          Icons.edit,
                          color: theme.primaryColor,
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