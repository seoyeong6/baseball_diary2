import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/calendar_controller.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../models/sticker_data.dart';
import '../widgets/sticker_selection_modal.dart';
import 'diary_detail_screen.dart';
import 'record_screen.dart';

/// 월간 캘린더 뷰와 일별 기록 표시, 스티커 기능이 포함된 캘린더 화면
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  void _showStickerSelectionModal(BuildContext context, CalendarController controller) {
    final dateToUse = controller.selectedDay ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StickerSelectionModal(
        selectedDate: dateToUse,
        onStickersSelected: (stickerTypes) => _onStickersSelected(context, controller, stickerTypes, dateToUse),
      ),
    );
  }

  Future<void> _onStickersSelected(BuildContext context, CalendarController controller, List<StickerType> stickerTypes, DateTime selectedDate) async {
    try {
      final entries = controller.getCachedEventsForDay(selectedDate);
      DiaryEntry entryToUpdate;
      
      if (entries.isEmpty) {
        // 기록이 없으면 새 기록 생성
        entryToUpdate = DiaryEntry(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          title: '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
          content: '',
          emotion: Emotion.neutral,
          date: selectedDate,
          teamId: 1,
          stickers: stickerTypes,
        );
        await controller.addNewDiaryEntry(entryToUpdate);
      } else {
        // 기존 기록에 스티커 추가
        final existingEntry = entries.first;
        final updatedStickers = [...existingEntry.stickers, ...stickerTypes];
        entryToUpdate = existingEntry.copyWith(stickers: updatedStickers);
        await controller.updateDiaryEntry(entryToUpdate);
      }
      
      if (context.mounted) {
        final message = entries.isEmpty 
          ? '스티커와 함께 새 기록이 생성되었습니다'
          : '스티커가 추가되었습니다';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding sticker: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('스티커 추가에 실패했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
          size: size * 0.85,
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

  Widget _buildStickerIcon(StickerType stickerType, {required double size, Color? iconColor}) {
    final color = iconColor ?? stickerType.color;
    
    if (stickerType.icon == FontAwesomeIcons.baseballBatBall) {
      return FaIcon(
        stickerType.icon,
        size: size * 0.85,
        color: color,
      );
    }
    
    return Icon(
      stickerType.icon,
      size: size,
      color: color,
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, DateTime focusedDay, CalendarController controller) {
    final theme = Theme.of(context);
    final entries = controller.getCachedEventsForDay(day);
    
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: const BoxDecoration(
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
          if (entries.isNotEmpty && entries.first.content.isNotEmpty)
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

  Widget _buildSelectedDayCell(BuildContext context, DateTime day, DateTime focusedDay, CalendarController controller) {
    final theme = Theme.of(context);
    final entries = controller.getCachedEventsForDay(day);
    
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
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
          if (entries.isNotEmpty && entries.first.content.isNotEmpty)
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

  Widget _buildTodayCell(BuildContext context, DateTime day, DateTime focusedDay, CalendarController controller) {
    final theme = Theme.of(context);
    final entries = controller.getCachedEventsForDay(day);
    
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.6),
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
          if (entries.isNotEmpty && entries.first.content.isNotEmpty)
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
    return Consumer<CalendarController>(
        builder: (context, controller, child) {
          if (!controller.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

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
                  focusedDay: controller.focusedDay,
                  calendarFormat: controller.calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(controller.selectedDay, day);
                  },
                  eventLoader: controller.getCachedEventsForDay,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildDayCell(context, day, focusedDay, controller);
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildSelectedDayCell(context, day, focusedDay, controller);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildTodayCell(context, day, focusedDay, controller);
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
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
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
                  onDaySelected: controller.onDaySelected,
                  onFormatChanged: controller.onFormatChanged,
                  onPageChanged: controller.onPageChanged,
                ),
                
                const SizedBox(height: 8),
                
                // 선택된 날짜의 이벤트 목록
                Expanded(
                  child: controller.selectedEvents.isEmpty
                    ? Center(
                        child: Text(
                          '이 날짜에는 기록이 없습니다',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.selectedEvents.length,
                        itemBuilder: (context, index) {
                          final entry = controller.selectedEvents[index];
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DiaryDetailScreen(entry: entry),
                                  ),
                                );
                              },
                              title: Text(entry.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.content.isNotEmpty)
                                    Text(
                                      entry.content.length > 50 
                                        ? '${entry.content.substring(0, 50)}...' 
                                        : entry.content,
                                    ),
                                  if (entry.stickers.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      children: entry.stickers.map((stickerType) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: stickerType.color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: stickerType.color.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildStickerIcon(stickerType, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                stickerType.displayName,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: stickerType.color,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                              leading: entry.content.isNotEmpty 
                                ? Container(
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
                                  )
                                : null,
                              trailing: entry.content.isNotEmpty 
                                ? Text(
                                    entry.emotion.displayName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: entry.emotion.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : null,
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
            
            // 새 일기 추가 및 스티커 추가 플로팅 버튼
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "sticker_fab",
                  onPressed: () => _showStickerSelectionModal(context, controller),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.emoji_emotions),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: "diary_fab",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecordScreen(
                          selectedDate: controller.selectedDay ?? DateTime.now(),
                        ),
                      ),
                    );
                    
                    if (result == true) {
                      controller.refreshCalendar();
                    }
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          );
        },
    );
  }

}