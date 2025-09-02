import 'package:flutter/material.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  final DiaryService _diaryService = DiaryService();
  List<DiaryEntry> _diaryEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _diaryService.initialize();
      final entries = await _diaryService.getAllDiaryEntries();

      setState(() {
        _diaryEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading diary entries: $e');
      setState(() {
        _isLoading = false;
      });
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diaryEntries.isEmpty
              ? const Center(
                  child: Text(
                    '아직 작성된 기록이 없습니다.\n기록 탭에서 첫 번째 기록을 작성해보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _diaryEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _diaryEntries[index];
                    final isOnlyStickers = entry.content.isEmpty && entry.stickers.isNotEmpty;
                    
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(
                          isOnlyStickers ? '스티커 기록' : entry.title,
                          style: isOnlyStickers 
                              ? TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)
                              : null,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.date.year}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.day.toString().padLeft(2, '0')}',
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
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: stickerType.color.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      stickerType.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: stickerType.color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                        leading: entry.emotion != null
                            ? Icon(
                                entry.emotion.fallbackIcon,
                                color: entry.emotion.color,
                                size: 24,
                              )
                            : const Icon(Icons.note),
                        onTap: () {
                          // TODO: Navigate to detail screen
                        },
                      ),
                    );
                  },
                ),
    );
  }
}