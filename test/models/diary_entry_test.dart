import 'package:flutter_test/flutter_test.dart';
import 'package:baseball_diary2/models/diary_entry.dart';
import 'package:baseball_diary2/models/emotion.dart';

void main() {
  group('DiaryEntry Model Tests', () {
    final testDate = DateTime(2024, 1, 15, 14, 30);
    final testDiaryEntry = DiaryEntry(
      id: 'test-id-123',
      title: '테스트 일기',
      content: '오늘은 야구 경기를 봤다.',
      emotion: Emotion.happy,
      imagePath: '/path/to/image.jpg',
      date: testDate,
      teamId: 1,
    );

    test('should create DiaryEntry instance with required fields', () {
      expect(testDiaryEntry.id, 'test-id-123');
      expect(testDiaryEntry.title, '테스트 일기');
      expect(testDiaryEntry.content, '오늘은 야구 경기를 봤다.');
      expect(testDiaryEntry.emotion, Emotion.happy);
      expect(testDiaryEntry.imagePath, '/path/to/image.jpg');
      expect(testDiaryEntry.date, testDate);
      expect(testDiaryEntry.teamId, 1);
    });

    test('should create DiaryEntry instance without imagePath', () {
      final entryWithoutImage = DiaryEntry(
        id: 'test-id-456',
        title: '이미지 없는 일기',
        content: '이미지가 없는 일기입니다.',
        emotion: Emotion.neutral,
        date: testDate,
        teamId: 2,
      );

      expect(entryWithoutImage.imagePath, isNull);
    });

    test('should convert DiaryEntry to JSON correctly', () {
      final json = testDiaryEntry.toJson();
      
      expect(json, {
        'id': 'test-id-123',
        'title': '테스트 일기',
        'content': '오늘은 야구 경기를 봤다.',
        'emotion': 'happy',
        'imagePath': '/path/to/image.jpg',
        'date': testDate.toIso8601String(),
        'teamId': 1,
      });
    });

    test('should convert DiaryEntry to JSON correctly when imagePath is null', () {
      final entryWithoutImage = DiaryEntry(
        id: 'test-id-456',
        title: '이미지 없는 일기',
        content: '이미지가 없는 일기입니다.',
        emotion: Emotion.neutral,
        date: testDate,
        teamId: 2,
      );

      final json = entryWithoutImage.toJson();
      
      expect(json['imagePath'], isNull);
    });

    test('should create DiaryEntry from JSON correctly', () {
      final json = {
        'id': 'test-id-123',
        'title': '테스트 일기',
        'content': '오늘은 야구 경기를 봤다.',
        'emotion': 'happy',
        'imagePath': '/path/to/image.jpg',
        'date': testDate.toIso8601String(),
        'teamId': 1,
      };

      final entry = DiaryEntry.fromJson(json);

      expect(entry.id, 'test-id-123');
      expect(entry.title, '테스트 일기');
      expect(entry.content, '오늘은 야구 경기를 봤다.');
      expect(entry.emotion, Emotion.happy);
      expect(entry.imagePath, '/path/to/image.jpg');
      expect(entry.date, testDate);
      expect(entry.teamId, 1);
    });

    test('should create DiaryEntry from JSON with null imagePath', () {
      final json = {
        'id': 'test-id-456',
        'title': '이미지 없는 일기',
        'content': '이미지가 없는 일기입니다.',
        'emotion': 'neutral',
        'imagePath': null,
        'date': testDate.toIso8601String(),
        'teamId': 2,
      };

      final entry = DiaryEntry.fromJson(json);

      expect(entry.imagePath, isNull);
    });

    test('should handle JSON serialization round trip', () {
      final json = testDiaryEntry.toJson();
      final recreatedEntry = DiaryEntry.fromJson(json);

      expect(recreatedEntry.id, testDiaryEntry.id);
      expect(recreatedEntry.title, testDiaryEntry.title);
      expect(recreatedEntry.content, testDiaryEntry.content);
      expect(recreatedEntry.emotion, testDiaryEntry.emotion);
      expect(recreatedEntry.imagePath, testDiaryEntry.imagePath);
      expect(recreatedEntry.date, testDiaryEntry.date);
      expect(recreatedEntry.teamId, testDiaryEntry.teamId);
    });

    test('should implement copyWith correctly', () {
      final updatedEntry = testDiaryEntry.copyWith(
        title: '수정된 제목',
        content: '수정된 내용',
      );

      expect(updatedEntry.id, testDiaryEntry.id);
      expect(updatedEntry.title, '수정된 제목');
      expect(updatedEntry.content, '수정된 내용');
      expect(updatedEntry.emotion, testDiaryEntry.emotion);
      expect(updatedEntry.imagePath, testDiaryEntry.imagePath);
      expect(updatedEntry.date, testDiaryEntry.date);
      expect(updatedEntry.teamId, testDiaryEntry.teamId);
    });

    test('should implement copyWith with all null values', () {
      final copiedEntry = testDiaryEntry.copyWith();

      expect(copiedEntry.id, testDiaryEntry.id);
      expect(copiedEntry.title, testDiaryEntry.title);
      expect(copiedEntry.content, testDiaryEntry.content);
      expect(copiedEntry.emotion, testDiaryEntry.emotion);
      expect(copiedEntry.imagePath, testDiaryEntry.imagePath);
      expect(copiedEntry.date, testDiaryEntry.date);
      expect(copiedEntry.teamId, testDiaryEntry.teamId);
    });

    test('should implement equality correctly', () {
      final entry1 = DiaryEntry(
        id: 'same-id',
        title: 'Title 1',
        content: 'Content 1',
        emotion: Emotion.happy,
        date: testDate,
        teamId: 1,
      );

      final entry2 = DiaryEntry(
        id: 'same-id',
        title: 'Title 2',
        content: 'Content 2',
        emotion: Emotion.sad,
        date: testDate,
        teamId: 2,
      );

      final entry3 = DiaryEntry(
        id: 'different-id',
        title: 'Title 1',
        content: 'Content 1',
        emotion: Emotion.happy,
        date: testDate,
        teamId: 1,
      );

      expect(entry1 == entry2, true); // Same ID
      expect(entry1 == entry3, false); // Different ID
    });

    test('should implement hashCode correctly', () {
      final entry1 = DiaryEntry(
        id: 'same-id',
        title: 'Title 1',
        content: 'Content 1',
        emotion: Emotion.happy,
        date: testDate,
        teamId: 1,
      );

      final entry2 = DiaryEntry(
        id: 'same-id',
        title: 'Title 2',
        content: 'Content 2',
        emotion: Emotion.sad,
        date: testDate,
        teamId: 2,
      );

      expect(entry1.hashCode, entry2.hashCode); // Same ID, same hashCode
    });

    test('should have proper toString representation', () {
      final toString = testDiaryEntry.toString();
      
      expect(toString, contains('DiaryEntry{'));
      expect(toString, contains('id: test-id-123'));
      expect(toString, contains('title: 테스트 일기'));
      expect(toString, contains('content: 오늘은 야구 경기를 봤다.'));
      expect(toString, contains('emotion: Emotion.happy'));
      expect(toString, contains('imagePath: /path/to/image.jpg'));
      expect(toString, contains('teamId: 1'));
    });

    test('should handle various emotion types', () {
      for (final emotion in Emotion.values) {
        final entry = DiaryEntry(
          id: 'test-${emotion.value}',
          title: '테스트',
          content: '내용',
          emotion: emotion,
          date: testDate,
          teamId: 1,
        );

        final json = entry.toJson();
        final recreated = DiaryEntry.fromJson(json);

        expect(recreated.emotion, emotion);
      }
    });

    test('should handle date serialization correctly', () {
      final testDates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 12, 31, 23, 59, 59),
        DateTime.now(),
      ];

      for (final date in testDates) {
        final entry = DiaryEntry(
          id: 'test',
          title: '테스트',
          content: '내용',
          emotion: Emotion.neutral,
          date: date,
          teamId: 1,
        );

        final json = entry.toJson();
        final recreated = DiaryEntry.fromJson(json);

        expect(recreated.date, date);
      }
    });
  });
}