import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/calendar_controller.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';

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

  Widget _buildSummaryStats() {
    final theme = Theme.of(context);
    final totalEntries = _cachedEntries.length;
    final thisMonthEntries = _cachedEntries.where((entry) {
      final now = DateTime.now();
      return entry.date.year == now.year && entry.date.month == now.month;
    }).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '요약 통계',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(
                  title: '총 기록 수',
                  value: '$totalEntries',
                  icon: Icons.edit_note,
                ),
                _StatCard(
                  title: '이번 달',
                  value: '$thisMonthEntries',
                  icon: Icons.calendar_month,
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
            ],
          ),
        ),
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