import 'package:flutter/material.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import 'diary_detail_screen.dart';

enum SortOption {
  latest('최신순'),
  oldest('오래된순');

  const SortOption(this.displayName);
  final String displayName;
}

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  final DiaryService _diaryService = DiaryService();
  List<DiaryEntry> _allEntries = [];
  List<DiaryEntry> _filteredEntries = [];
  bool _isLoading = true;
  SortOption _currentSort = SortOption.latest;
  Emotion? _selectedEmotionFilter;

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    debugPrint('_loadDiaryEntries 시작');
    try {
      setState(() {
        _isLoading = true;
      });

      await _diaryService.initialize();
      final entries = await _diaryService.getAllDiaryEntries();
      debugPrint('불러온 기록 수: ${entries.length}');

      setState(() {
        _allEntries = entries;
        _applyFiltersAndSort();
        _isLoading = false;
      });
      debugPrint('UI 업데이트 완료');
    } catch (e) {
      debugPrint('Error loading diary entries: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<DiaryEntry> filtered;
    
    // 감정 필터 적용
    if (_selectedEmotionFilter == null) {
      // 전체 선택: 모든 기록 표시
      filtered = List<DiaryEntry>.from(_allEntries);
    } else {
      // 특정 감정 선택: 해당 감정만 필터링
      filtered = _allEntries.where((entry) => entry.emotion == _selectedEmotionFilter).toList();
    }
    
    debugPrint('Filtering: ${_allEntries.length} entries -> ${filtered.length} entries (filter: $_selectedEmotionFilter)');

    // 정렬 적용
    switch (_currentSort) {
      case SortOption.latest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
    }

    _filteredEntries = filtered;
  }

  void _changeSortOption(SortOption newSort) {
    setState(() {
      _currentSort = newSort;
      _applyFiltersAndSort();
    });
  }

  void _changeEmotionFilter(Emotion? emotion) {
    debugPrint('Changing emotion filter to: $emotion');
    setState(() {
      _selectedEmotionFilter = emotion;
      _applyFiltersAndSort();
    });
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    try {
      await _diaryService.deleteDiaryEntry(entry.id);
      
      // 로컬 리스트에서도 제거
      setState(() {
        _allEntries.removeWhere((e) => e.id == entry.id);
        _applyFiltersAndSort();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록이 삭제되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기록 삭제에 실패했습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Diary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 새로고침 버튼 (테스트용)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('새로고침 버튼 클릭됨');
              _loadDiaryEntries();
            },
            tooltip: '새로고침',
          ),
          // 정렬 옵션
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: _changeSortOption,
            itemBuilder: (context) => SortOption.values
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (_currentSort == option)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(option.displayName),
                        ],
                      ),
                    ))
                .toList(),
          ),
          // 감정 필터
          PopupMenuButton<Emotion?>(
            icon: Icon(
              Icons.filter_alt,
              color: _selectedEmotionFilter != null 
                  ? Theme.of(context).colorScheme.primary 
                  : null,
            ),
            onSelected: (Emotion? value) {
              debugPrint('PopupMenu selected: $value');
              _changeEmotionFilter(value);
            },
            itemBuilder: (context) => [
              PopupMenuItem<Emotion?>(
                value: null,
                onTap: () {
                  debugPrint('전체 직접 클릭됨');
                  Future.delayed(Duration.zero, () {
                    _changeEmotionFilter(null);
                  });
                },
                child: Row(
                  children: [
                    if (_selectedEmotionFilter == null)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    const Text('전체'),
                  ],
                ),
              ),
              ...Emotion.values.map((emotion) => PopupMenuItem<Emotion?>(
                    value: emotion,
                    child: Row(
                      children: [
                        if (_selectedEmotionFilter == emotion)
                          Icon(
                            Icons.check,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Icon(
                          emotion.fallbackIcon,
                          size: 16,
                          color: emotion.color,
                        ),
                        const SizedBox(width: 8),
                        Text(emotion.displayName),
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDiaryEntries,
              child: _filteredEntries.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Text(
                            _allEntries.isEmpty 
                                ? '아직 작성된 기록이 없습니다.\n기록 탭에서 첫 번째 기록을 작성해보세요!'
                                : _selectedEmotionFilter != null
                                    ? '${_selectedEmotionFilter!.displayName} 감정의 기록이 없습니다.\n다른 감정을 선택해보세요.'
                                    : '조건에 맞는 기록이 없습니다.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredEntries[index];
                    final isOnlyStickers = entry.content.isEmpty && entry.stickers.isNotEmpty;
                    final theme = Theme.of(context);
                    
                    return Dismissible(
                      key: Key(entry.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '삭제',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('기록 삭제'),
                            content: Text('\'${entry.title}\' 기록을 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text(
                                  '삭제',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteEntry(entry);
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DiaryDetailScreen(entry: entry),
                              ),
                            );
                          },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 헤더: 날짜와 감정
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${entry.date.year}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.day.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  if (entry.emotion != null)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: entry.emotion.color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        entry.emotion.fallbackIcon,
                                        color: entry.emotion.color,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // 제목
                              Text(
                                isOnlyStickers ? '스티커 기록' : entry.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isOnlyStickers 
                                      ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                      : null,
                                  fontStyle: isOnlyStickers ? FontStyle.italic : null,
                                ),
                              ),
                              
                              // 내용 미리보기 (스티커 전용이 아닌 경우)
                              if (!isOnlyStickers && entry.content.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  entry.content.length > 50 
                                      ? '${entry.content.substring(0, 50)}...'
                                      : entry.content,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              
                              // 스티커 표시
                              if (entry.stickers.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: entry.stickers.map((stickerType) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: stickerType.color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: stickerType.color.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            stickerType.icon,
                                            size: 12,
                                            color: stickerType.color,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            stickerType.displayName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: stickerType.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              
                              // 이미지가 있는 경우 표시
                              if (entry.imagePath != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 16,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '사진 첨부됨',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        ),
                      ),
                    );
                      },
                    ),
                ),
    );
  }
}