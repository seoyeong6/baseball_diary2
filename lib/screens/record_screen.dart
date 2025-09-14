import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../models/sticker_data.dart';
import '../services/diary_service.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/sticker_selection_modal.dart';
import '../services/image_service.dart';
import '../services/team_selection_helper.dart';
import '../widgets/team_info_widget.dart';
import 'diary_detail_screen.dart';

class RecordScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final DiaryEntry? existingEntry;

  const RecordScreen({super.key, this.selectedDate, this.existingEntry});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final DiaryService _diaryService = DiaryService();
  final ImagePicker _picker = ImagePicker();
  final ImageService _imageService = ImageService();

  Emotion _selectedEmotion = Emotion.neutral;
  List<StickerType> _selectedStickers = [];
  XFile? _selectedImage;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  bool _hasExistingEntryOnDate = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadExistingEntry();
  }

  Future<void> _initializeService() async {
    await _diaryService.initialize();
  }

  void _loadExistingEntry() {
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _titleController.text = entry.title;
      _contentController.text = entry.content;
      _selectedEmotion = entry.emotion;
      _selectedStickers = List.from(entry.stickers);
      _selectedDate = entry.date;
    } else {
      // 새 기록인 경우: 전달받은 날짜가 있으면 사용, 없으면 오늘 날짜
      _selectedDate = widget.selectedDate ?? DateTime.now();
      _checkExistingEntryOnDate();
    }
  }

  Future<void> _checkExistingEntryOnDate() async {
    try {
      final existingEntries = await _diaryService.getDiaryEntriesByDate(
        _selectedDate,
      );
      setState(() {
        _hasExistingEntryOnDate = existingEntries.isNotEmpty;
      });
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지 선택에 실패했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _showStickerSelectionModal() {
    final dateToUse = widget.selectedDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StickerSelectionModal(
        selectedDate: dateToUse,
        onStickersSelected: (stickerTypes) {
          setState(() {
            _selectedStickers.addAll(stickerTypes);
            // 중복 제거
            _selectedStickers = _selectedStickers.toSet().toList();
          });
        },
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 하루에 하나의 기록만 허용: 기존 기록이 아닌 경우 해당 날짜에 기록이 있는지 확인
      if (widget.existingEntry == null) {
        try {
          final existingEntries = await _diaryService.getDiaryEntriesByDate(
            _selectedDate,
          );
          if (existingEntries.isNotEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('이미 해당 날짜에 기록이 있습니다. 하루에 하나의 기록만 작성할 수 있습니다.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        } catch (e) {
          // 중복 확인 중 에러가 발생해도 저장은 계속 진행
          debugPrint('Duplicate check failed, but continuing with save: $e');
        }
      }

      final now = DateTime.now();
      final entryId = widget.existingEntry?.id ?? '${now.millisecondsSinceEpoch}';

      // Offline-first image upload
      String? firebaseImageUrl;
      String? localImagePath;
      bool imageUploadPending = false;

      if (_selectedImage != null) {
        final uploadResult = await _imageService.uploadImageOfflineFirst(
          _selectedImage!.path,
          entryId: entryId,
          quality: 85,
          maxWidth: 1080,
          maxHeight: 1080,
        );

        if (!uploadResult.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(uploadResult.error ?? '이미지 처리에 실패했습니다'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        firebaseImageUrl = uploadResult.remoteUrl;
        localImagePath = uploadResult.localPath;
        imageUploadPending = uploadResult.uploadPending;

        // Show appropriate message based on upload status
        if (mounted && imageUploadPending) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('오프라인 상태입니다. 이미지는 온라인 상태가 되면 자동으로 업로드됩니다.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // 선택된 팀 ID 가져오기 (없으면 기본값 1 사용)
      final selectedTeamId = await TeamSelectionHelper.getSelectedTeamId() ?? 1;

      final entry = DiaryEntry(
        id: entryId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        emotion: _selectedEmotion,
        date: _selectedDate,
        teamId: selectedTeamId,
        stickers: _selectedStickers,
        imagePath: firebaseImageUrl ?? widget.existingEntry?.imagePath,
        localImagePath: localImagePath ?? widget.existingEntry?.localImagePath,
        imageUploadPending: imageUploadPending || widget.existingEntry?.imageUploadPending == true,
      );

      // CalendarController를 통해 저장 및 캐시 업데이트
      final calendarController = Provider.of<CalendarController>(
        context,
        listen: false,
      );
      if (widget.existingEntry != null) {
        await calendarController.updateDiaryEntry(entry);
      } else {
        await calendarController.addNewDiaryEntry(entry);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingEntry != null ? '기록이 수정되었습니다' : '기록이 저장되었습니다',
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // 저장된 기록의 상세보기로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryDetailScreen(entry: entry),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save entry error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기록 저장에 실패했습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.existingEntry != null ? '기록 수정' : '새 기록 작성',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            top: 8.0,
            bottom: 8.0,
            right: 8.0,
          ),
          child: TeamInfoWidget(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _saveEntry, child: const Text('저장')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 선택
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '기록 날짜',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // 중복 기록 경고 메시지
              if (_hasExistingEntryOnDate && widget.existingEntry == null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일에 이미 기록이 있습니다.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 제목 입력
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '제목',
                  hintText: '기록의 제목을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 본문 입력
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: '내용',
                  hintText: '오늘의 야구 기록을 자유롭게 작성해보세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // 감정 선택
              Text(
                '오늘의 기분',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 70,
                child: Row(
                  children: Emotion.values.map((emotion) {
                    final isSelected = _selectedEmotion == emotion;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmotion = emotion;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? emotion.color.withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? emotion.color
                                  : theme.dividerColor,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                emotion.fallbackIcon,
                                size: 24,
                                color: isSelected
                                    ? emotion.color
                                    : theme.colorScheme.onSurface,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                emotion.displayName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isSelected
                                      ? emotion.color
                                      : theme.colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // 스티커 선택
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '활동 스티커',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showStickerSelectionModal,
                    icon: const Icon(Icons.emoji_emotions),
                    label: const Text('스티커 선택'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (_selectedStickers.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedStickers.map((stickerType) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: stickerType.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: stickerType.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            stickerType.icon,
                            size: 16,
                            color: stickerType.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stickerType.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: stickerType.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStickers.remove(stickerType);
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: stickerType.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),

              // 사진 첨부
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '사진',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _selectedImage == null ? _pickImage : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('사진 선택'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (_selectedImage != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? FutureBuilder<Uint8List>(
                              future: _selectedImage!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return const SizedBox(
                                  width: double.infinity,
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(_selectedImage!.path),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 16,
                        child: IconButton(
                          onPressed: _removeImage,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // 날짜 변경 시 해당 날짜에 기록이 있는지 다시 확인
      if (widget.existingEntry == null) {
        await _checkExistingEntryOnDate();
      }
    }
  }
}
