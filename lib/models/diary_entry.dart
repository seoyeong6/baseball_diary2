import 'emotion.dart';

class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final Emotion emotion;
  final String? imagePath;
  final DateTime date;
  final int teamId;

  const DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.emotion,
    this.imagePath,
    required this.date,
    required this.teamId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'emotion': emotion.toJson(),
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'teamId': teamId,
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      emotion: Emotion.fromJson(json['emotion'] as String),
      imagePath: json['imagePath'] as String?,
      date: DateTime.parse(json['date'] as String),
      teamId: json['teamId'] as int,
    );
  }

  DiaryEntry copyWith({
    String? id,
    String? title,
    String? content,
    Emotion? emotion,
    String? imagePath,
    DateTime? date,
    int? teamId,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      emotion: emotion ?? this.emotion,
      imagePath: imagePath ?? this.imagePath,
      date: date ?? this.date,
      teamId: teamId ?? this.teamId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DiaryEntry{id: $id, title: $title, content: $content, emotion: $emotion, imagePath: $imagePath, date: $date, teamId: $teamId}';
  }
}