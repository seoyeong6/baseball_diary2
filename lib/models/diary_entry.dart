import 'emotion.dart';
import 'sticker_data.dart';

class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final Emotion emotion;
  final String? imagePath;  // Remote URL (Firebase Storage)
  final String? localImagePath;  // Local file path for offline storage
  final bool? imageUploadPending;  // True if image needs to be uploaded
  final DateTime date;
  final int teamId;
  final List<StickerType> stickers;

  const DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.emotion,
    this.imagePath,
    this.localImagePath,
    this.imageUploadPending,
    required this.date,
    required this.teamId,
    this.stickers = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'emotion': emotion.toJson(),
      'imagePath': imagePath,
      'localImagePath': localImagePath,
      'imageUploadPending': imageUploadPending,
      'date': date.toIso8601String(),
      'teamId': teamId,
      'stickers': stickers.map((s) => s.toJson()).toList(),
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      emotion: Emotion.fromJson(json['emotion'] as String),
      imagePath: json['imagePath'] as String?,
      localImagePath: json['localImagePath'] as String?,
      imageUploadPending: json['imageUploadPending'] as bool?,
      date: DateTime.parse(json['date'] as String),
      teamId: json['teamId'] as int,
      stickers: (json['stickers'] as List<dynamic>?)
          ?.map((s) => StickerType.fromJson(s as String))
          .toList() ?? [],
    );
  }

  DiaryEntry copyWith({
    String? id,
    String? title,
    String? content,
    Emotion? emotion,
    String? imagePath,
    String? localImagePath,
    bool? imageUploadPending,
    DateTime? date,
    int? teamId,
    List<StickerType>? stickers,
    bool clearLocalImage = false,
    bool clearRemoteImage = false,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      emotion: emotion ?? this.emotion,
      imagePath: clearRemoteImage ? null : (imagePath ?? this.imagePath),
      localImagePath: clearLocalImage ? null : (localImagePath ?? this.localImagePath),
      imageUploadPending: imageUploadPending ?? this.imageUploadPending,
      date: date ?? this.date,
      teamId: teamId ?? this.teamId,
      stickers: stickers ?? this.stickers,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Get the best available image path (prefer remote if available)
  String? get displayImagePath => imagePath ?? localImagePath;

  /// Check if the entry has any image
  bool get hasImage => imagePath != null || localImagePath != null;

  @override
  String toString() {
    return 'DiaryEntry{id: $id, title: $title, content: $content, emotion: $emotion, imagePath: $imagePath, localImagePath: $localImagePath, imageUploadPending: $imageUploadPending, date: $date, teamId: $teamId, stickers: $stickers}';
  }
}