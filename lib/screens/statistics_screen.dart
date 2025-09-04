import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../models/sticker_data.dart';

/// 감정 데이터 기반 시각화와 팀별 기록 통계를 보여주는 통계 화면
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = '1개월';
  final List<String> _periods = ['1개월', '3개월', '1년', '사용자 지정'];
  final DiaryService _diaryService = DiaryService();
  
  List<DiaryEntry> _cachedEntries = [];
  DateTime? _lastCacheUpdate;
  
  // 사용자 지정 날짜 범위
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _diaryService.initialize();
      final entries = await _getEntriesForPeriod(_selectedPeriod);
      
      if (mounted) {
        setState(() {
          _cachedEntries = entries;
          _lastCacheUpdate = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics data: $e');
    }
  }

  Future<List<DiaryEntry>> _getEntriesForPeriod(String period) async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now.add(const Duration(days: 1));
    
    switch (period) {
      case '1개월':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3개월':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '1년':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case '사용자 지정':
        if (_customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate!;
          endDate = _customEndDate!.add(const Duration(days: 1));
        } else {
          startDate = DateTime(now.year, now.month - 1, now.day);
        }
        break;
      default:
        startDate = DateTime(now.year, now.month - 1, now.day);
    }
    
    // DiaryService에서 모든 기록을 가져와서 기간별로 필터링
    final allEntries = await _diaryService.getAllDiaryEntries();
    return allEntries.where((entry) {
      // 날짜만 비교하기 위해 시간 정보 제거
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final filterStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final filterEndDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      return entryDate.compareTo(filterStartDate) >= 0 && 
             entryDate.compareTo(filterEndDate) < 0 &&
             entry.content.isNotEmpty;
    }).toList();
  }

  // 스티커 통계 관련 함수들
  Map<StickerType, int> _getStickerCounts() {
    final stickerCounts = <StickerType, int>{};
    
    for (final entry in _cachedEntries) {
      for (final sticker in entry.stickers) {
        stickerCounts[sticker] = (stickerCounts[sticker] ?? 0) + 1;
      }
    }
    
    return stickerCounts;
  }

  Map<String, int> _getGameStats() {
    int victories = 0;
    int defeats = 0;
    int draws = 0;
    
    for (final entry in _cachedEntries) {
      for (final sticker in entry.stickers) {
        switch (sticker) {
          case StickerType.victory:
            victories++;
            break;
          case StickerType.defeat:
            defeats++;
            break;
          case StickerType.draw:
            draws++;
            break;
          default:
            // 다른 스티커 타입들은 게임 결과가 아니므로 무시
            break;
        }
      }
    }
    
    return {
      'victories': victories,
      'defeats': defeats,
      'draws': draws,
    };
  }


  Widget _buildSummaryStats() {
    final theme = Theme.of(context);
    final totalEntries = _cachedEntries.length;
    final thisMonthEntries = _cachedEntries.where((entry) {
      final now = DateTime.now();
      return entry.date.year == now.year && entry.date.month == now.month;
    }).length;

    // 스티커 통계
    final stickerCounts = _getStickerCounts();
    final totalStickers = stickerCounts.values.fold(0, (sum, count) => sum + count);
    final avgDailyActivity = _cachedEntries.isNotEmpty 
        ? (totalStickers / _cachedEntries.length).toStringAsFixed(1)
        : '0.0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '활동 빈도 요약',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                // 첫 번째 줄
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: '총 기록 수',
                        value: '$totalEntries',
                        icon: Icons.edit_note,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: '총 스티커 수',
                        value: '$totalStickers',
                        icon: Icons.star,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 두 번째 줄
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: '평균 일일 활동',
                        value: '$avgDailyActivity개',
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: '이번 달',
                        value: '$thisMonthEntries',
                        icon: Icons.calendar_month,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatsCard() {
    final theme = Theme.of(context);
    final gameStats = _getGameStats();
    final victories = gameStats['victories'] ?? 0;
    final defeats = gameStats['defeats'] ?? 0;
    final draws = gameStats['draws'] ?? 0;
    final totalGames = victories + defeats + draws;
    
    if (totalGames == 0) {
      return Card(
        child: SizedBox(
          width: double.infinity,
          height: 200,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_baseball,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  '경기 데이터가 없습니다',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '승리/패배/무승부 스티커가 있는 기록을 작성하면 성과 통계를 볼 수 있습니다',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final winRate = ((victories / totalGames) * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '성과 통계',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '총 경기 수',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalGames경기',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '승률',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$winRate%',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: victories > defeats ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _GameStatItem(
                  label: '승리',
                  count: victories,
                  percentage: totalGames > 0 ? ((victories / totalGames) * 100).round() : 0,
                  color: Colors.green,
                ),
                _GameStatItem(
                  label: '패배',
                  count: defeats,
                  percentage: totalGames > 0 ? ((defeats / totalGames) * 100).round() : 0,
                  color: Colors.red,
                ),
                _GameStatItem(
                  label: '무승부',
                  count: draws,
                  percentage: totalGames > 0 ? ((draws / totalGames) * 100).round() : 0,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodLineChart() {
    final theme = Theme.of(context);
    
    if (_cachedEntries.isEmpty) {
      return Card(
        child: SizedBox(
          width: double.infinity,
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  '기분 변화 데이터가 없습니다',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '기록을 작성하면 기분 변화를 볼 수 있습니다',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 날짜별로 감정을 그룹화하고 평균 점수 계산
    final Map<DateTime, List<Emotion>> dailyEmotions = {};
    for (final entry in _cachedEntries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      dailyEmotions.putIfAbsent(date, () => []).add(entry.emotion);
    }

    // 감정을 점수로 변환 (매우 좋음: 5, 좋음: 4, 보통: 3, 나쁨: 2, 매우 나쁨: 1)
    double emotionToScore(Emotion emotion) {
      switch (emotion) {
        case Emotion.excited:
          return 5.0;
        case Emotion.happy:
          return 4.0;
        case Emotion.neutral:
          return 3.0;
        case Emotion.sad:
          return 2.0;
        case Emotion.angry:
          return 1.0;
      }
    }

    // 라인 차트 데이터 생성
    final sortedDates = dailyEmotions.keys.toList()..sort();
    final spots = <FlSpot>[];
    
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final emotions = dailyEmotions[date]!;
      final avgScore = emotions.map(emotionToScore).reduce((a, b) => a + b) / emotions.length;
      spots.add(FlSpot(i.toDouble(), avgScore));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기간별 기분 변화',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor,
                        strokeWidth: 0.5,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 1:
                              return Text('매우\n나쁨', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10), textAlign: TextAlign.center);
                            case 2:
                              return Text('나쁨', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10), textAlign: TextAlign.center);
                            case 3:
                              return Text('보통', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10), textAlign: TextAlign.center);
                            case 4:
                              return Text('좋음', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10), textAlign: TextAlign.center);
                            case 5:
                              return Text('매우\n좋음', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10), textAlign: TextAlign.center);
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (sortedDates.length / 5).ceil().toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedDates.length) {
                            final date = sortedDates[index];
                            return Text(
                              '${date.month}/${date.day}',
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (sortedDates.length - 1).toDouble(),
                  minY: 0.5,
                  maxY: 5.0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: theme.colorScheme.primary,
                            strokeWidth: 3,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerDetailView() {
    final theme = Theme.of(context);
    final stickerCounts = _getStickerCounts();
    
    if (stickerCounts.isEmpty) {
      return Card(
        child: SizedBox(
          width: double.infinity,
          height: 200,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_outline,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  '스티커 데이터가 없습니다',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '기록 작성 시 스티커를 추가하면 상세 통계를 볼 수 있습니다',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 스티커별 사용 날짜 목록 생성
    final stickerDates = <StickerType, List<DateTime>>{};
    final stickerEmotions = <StickerType, Map<Emotion, int>>{};
    
    for (final entry in _cachedEntries) {
      for (final sticker in entry.stickers) {
        stickerDates.putIfAbsent(sticker, () => []).add(entry.date);
        stickerEmotions.putIfAbsent(sticker, () => {});
        stickerEmotions[sticker]![entry.emotion] = 
            (stickerEmotions[sticker]![entry.emotion] ?? 0) + 1;
      }
    }

    // 사용 횟수별로 정렬
    final sortedStickers = stickerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '스티커별 상세 정보',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 스티커 목록
            ...sortedStickers.map((entry) {
              final sticker = entry.key;
              final count = entry.value;
              final dates = stickerDates[sticker] ?? [];
              final emotions = stickerEmotions[sticker] ?? {};
              
              // 가장 많이 연관된 감정
              final mostCommonEmotion = emotions.entries.isEmpty 
                  ? null 
                  : emotions.entries.reduce((a, b) => a.value > b.value ? a : b);
              
              return _StickerDetailCard(
                stickerType: sticker,
                count: count,
                dates: dates,
                emotionCounts: emotions,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionPieChart() {
    final theme = Theme.of(context);
    
    if (_cachedEntries.isEmpty) {
      return Card(
        child: SizedBox(
          width: double.infinity,
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  '감정 데이터가 없습니다',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '기록을 작성하면 감정별 통계를 볼 수 있습니다',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 감정별 개수 계산
    final emotionCounts = <Emotion, int>{};
    for (final entry in _cachedEntries) {
      emotionCounts[entry.emotion] = (emotionCounts[entry.emotion] ?? 0) + 1;
    }

    final pieChartData = emotionCounts.entries.map((entry) {
      final percentage = (entry.value / _cachedEntries.length) * 100;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: entry.key.color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '감정별 비율',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: pieChartData,
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: emotionCounts.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: entry.key.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key.displayName,
                                  style: theme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      helpText: '통계 기간 선택',
      cancelText: '취소',
      confirmText: '확인',
      saveText: '적용',
    );
    
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedPeriod = '사용자 지정'; // 자동으로 사용자 지정 선택
      });
      _loadData();
    }
  }

  Widget _buildPeriodFilter() {
    return Column(
      children: [
        // 기본 필터 칩들
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _periods.map((period) {
            final isSelected = _selectedPeriod == period;
            
            // 사용자 지정의 경우 특별한 처리
            if (period == '사용자 지정') {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: _showDateRangePicker,
                  child: FilterChip(
                    label: Text(period),
                    selected: isSelected,
                    onSelected: null, // onSelected를 비활성화하고 GestureDetector 사용
                  ),
                ),
              );
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    _loadData();
                  }
                },
              ),
            );
          }).toList(),
        ),
        
        // 사용자 지정 날짜 표시
        if (_selectedPeriod == '사용자 지정' && _customStartDate != null && _customEndDate != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_customStartDate!.year}.${_customStartDate!.month}.${_customStartDate!.day} - ${_customEndDate!.year}.${_customEndDate!.month}.${_customEndDate!.day}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _showDateRangePicker,
                  child: Icon(
                    Icons.edit,
                    size: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '통계',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기간 필터
              _buildPeriodFilter(),
              const SizedBox(height: 16),
              
              // 요약 통계
              _buildSummaryStats(),
              const SizedBox(height: 16),
              
              // 기간별 기분 변화 라인 차트
              _buildMoodLineChart(),
              const SizedBox(height: 16),
              
              // 감정별 파이 차트
              _buildEmotionPieChart(),
              const SizedBox(height: 16),
              
              // 성과 통계 (승률)
              _buildGameStatsCard(),
              const SizedBox(height: 16),
              
              // 스티커별 상세 정보
              _buildStickerDetailView(),
            ],
          ),
        ),
      ),
    );
  }
}

// 게임 통계 아이템 위젯
class _GameStatItem extends StatelessWidget {
  final String label;
  final int count;
  final int percentage;
  final Color color;

  const _GameStatItem({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count회',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '($percentage%)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// 스티커 상세 정보 카드 위젯
class _StickerDetailCard extends StatefulWidget {
  final StickerType stickerType;
  final int count;
  final List<DateTime> dates;
  final Map<Emotion, int> emotionCounts;

  const _StickerDetailCard({
    required this.stickerType,
    required this.count,
    required this.dates,
    required this.emotionCounts,
  });

  @override
  State<_StickerDetailCard> createState() => _StickerDetailCardState();
}

class _StickerDetailCardState extends State<_StickerDetailCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 최근 사용 날짜들 (최대 3개) - 오래된 것부터 최신순으로
    final sortedDates = widget.dates.toList()
      ..sort((a, b) => a.compareTo(b));
    final recentDates = sortedDates.take(3).toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.stickerType.color.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 메인 정보
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 스티커 아이콘
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.stickerType.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.stickerType.icon,
                      color: widget.stickerType.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 스티커 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stickerType.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.stickerType.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.count}회 사용',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 확장 아이콘
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          
          // 확장된 상세 정보
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: widget.stickerType.color.withValues(alpha: 0.2),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 감정 비율 섹션
                  if (widget.emotionCounts.isNotEmpty) ...[
                    Text(
                      '함께 나타난 감정:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.emotionCounts.entries
                          .map((emotionEntry) {
                        final emotion = emotionEntry.key;
                        final count = emotionEntry.value;
                        final percentage = ((count / widget.count) * 100).round();
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: emotion.color.withValues(alpha: 0.1),
                            border: Border.all(
                              color: emotion.color.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                emotion.fallbackIcon,
                                size: 12,
                                color: emotion.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${emotion.displayName} $percentage%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: emotion.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 최근 사용 날짜 섹션
                  Text(
                    '최근 사용된 날짜(최대 3회):',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recentDates.isEmpty)
                    Text(
                      '사용 기록이 없습니다',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: recentDates.map((date) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${date.month}/${date.day}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  if (sortedDates.length > 3) ...[
                    const SizedBox(height: 4),
                    Text(
                      '그 외 ${sortedDates.length - 3}개 더...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}