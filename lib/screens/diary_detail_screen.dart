import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/cached_image_widget.dart';
import '../widgets/image_upload_indicator.dart';
import '../routing/app_routes.dart';
import 'record_screen.dart';

class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  final String? sourceTab; // 'calendar' or 'diary'

  const DiaryDetailScreen({
    super.key,
    required this.entry,
    this.sourceTab,
  });

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  late DiaryEntry _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }


  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 기록을 삭제하시겠습니까? 삭제된 기록은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEntry();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry() async {
    try {
      final calendarController = Provider.of<CalendarController>(context, listen: false);
      await calendarController.deleteDiaryEntry(widget.entry.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 삭제되었습니다')),
        );
        // 삭제 후에도 소스 탭으로 돌아가기
        if (widget.sourceTab == 'calendar') {
          context.go(AppRoutes.calendar);
        } else {
          context.go(AppRoutes.diary);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  void _navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordScreen(
          existingEntry: _currentEntry,
        ),
      ),
    ).then((result) {
      if (result is DiaryEntry) {
        setState(() {
          _currentEntry = result;
        });
      }
    });
  }

  void _showImageZoom(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageZoomScreen(imagePath: imagePath),
      ),
    );
  }

  Widget _buildEmotionSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 기분',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _currentEntry.emotion.fallbackIcon,
                size: 24,
                color: _currentEntry.emotion.color,
              ),
              const SizedBox(width: 8),
              Text(
                _currentEntry.emotion.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _currentEntry.emotion.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickersSection(BuildContext context) {
    if (_currentEntry.stickers.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '활동 스티커',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentEntry.stickers.map((stickerType) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stickerType.icon,
                    size: 20,
                    color: stickerType.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    stickerType.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: stickerType.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
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
        title: Text(
          _currentEntry.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _navigateToEditScreen,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _showDeleteConfirmDialog,
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 정보
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '작성일',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentEntry.date.year}년 ${_currentEntry.date.month}월 ${_currentEntry.date.day}일',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(color: theme.dividerColor),
            
            // 감정 섹션
            _buildEmotionSection(context),
            
            if (_currentEntry.content.isNotEmpty) ...[
              Divider(color: theme.dividerColor),
              
              // 내용
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '일기 내용',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentEntry.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // 사진 섹션
            if (_currentEntry.hasImage) ...[
              Divider(color: theme.dividerColor),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '사진',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show upload status if pending
                    if (_currentEntry.imageUploadPending == true) ...[
                      ImageUploadIndicator(
                        entry: _currentEntry,
                        onUploadComplete: () {
                          // Refresh the entry when upload completes
                          setState(() {
                            // You might want to reload the entry from the database here
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    Center(
                      child: GestureDetector(
                        onTap: () => _showImageZoom(_currentEntry.displayImagePath!),
                        child: Hero(
                          tag: 'image_${_currentEntry.id}',
                          child: CachedImageWidget(
                            imagePath: _currentEntry.imagePath,
                            height: 200,
                            borderRadius: BorderRadius.circular(8),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // 스티커 섹션
            if (_currentEntry.stickers.isNotEmpty) ...[
              Divider(color: theme.dividerColor),
              _buildStickersSection(context),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              // 소스 탭에 따라 적절한 화면으로 돌아가기
              if (widget.sourceTab == 'calendar') {
                context.go(AppRoutes.calendar);
              } else {
                context.go(AppRoutes.diary);
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('확인'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageZoomScreen extends StatelessWidget {
  final String imagePath;

  const _ImageZoomScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: 'image_zoom',
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedImageWidget(
              imagePath: imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}