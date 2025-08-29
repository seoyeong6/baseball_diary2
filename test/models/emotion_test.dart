import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baseball_diary2/models/emotion.dart';

void main() {
  group('Emotion Enum Tests', () {
    test('should have correct number of emotions', () {
      expect(Emotion.values.length, 5);
    });

    test('should have all expected emotion types', () {
      expect(Emotion.values, contains(Emotion.excited));
      expect(Emotion.values, contains(Emotion.happy));
      expect(Emotion.values, contains(Emotion.neutral));
      expect(Emotion.values, contains(Emotion.sad));
      expect(Emotion.values, contains(Emotion.angry));
    });

    test('should create emotion from string correctly', () {
      expect(Emotion.fromString('excited'), Emotion.excited);
      expect(Emotion.fromString('happy'), Emotion.happy);
      expect(Emotion.fromString('neutral'), Emotion.neutral);
      expect(Emotion.fromString('sad'), Emotion.sad);
      expect(Emotion.fromString('angry'), Emotion.angry);
    });

    test('should return neutral for invalid string', () {
      expect(Emotion.fromString('invalid'), Emotion.neutral);
      expect(Emotion.fromString(''), Emotion.neutral);
    });

    test('should serialize to JSON correctly', () {
      expect(Emotion.excited.toJson(), 'excited');
      expect(Emotion.happy.toJson(), 'happy');
      expect(Emotion.neutral.toJson(), 'neutral');
      expect(Emotion.sad.toJson(), 'sad');
      expect(Emotion.angry.toJson(), 'angry');
    });

    test('should deserialize from JSON correctly', () {
      expect(Emotion.fromJson('excited'), Emotion.excited);
      expect(Emotion.fromJson('happy'), Emotion.happy);
      expect(Emotion.fromJson('neutral'), Emotion.neutral);
      expect(Emotion.fromJson('sad'), Emotion.sad);
      expect(Emotion.fromJson('angry'), Emotion.angry);
    });

    test('should handle JSON serialization round trip', () {
      for (final emotion in Emotion.values) {
        final json = emotion.toJson();
        final recreated = Emotion.fromJson(json);
        expect(recreated, emotion);
      }
    });

    test('should return all emotions list', () {
      final allEmotions = Emotion.getAllEmotions();
      expect(allEmotions.length, 5);
      expect(allEmotions, containsAll(Emotion.values));
    });

    test('should have proper toString representation', () {
      expect(Emotion.excited.toString(), 'excited');
      expect(Emotion.happy.toString(), 'happy');
      expect(Emotion.neutral.toString(), 'neutral');
      expect(Emotion.sad.toString(), 'sad');
      expect(Emotion.angry.toString(), 'angry');
    });

    test('should have valid properties for each emotion', () {
      for (final emotion in Emotion.values) {
        expect(emotion.value, isNotEmpty);
        expect(emotion.displayName, isNotEmpty);
        expect(emotion.imagePath, isNotEmpty);
        expect(emotion.imagePath, startsWith('assets/images/emotions/'));
        expect(emotion.imagePath, endsWith('.png'));
        expect(emotion.color, isA<Color>());
      }
    });

    test('should return correct colors', () {
      expect(Emotion.excited.getColor(), Colors.orange);
      expect(Emotion.happy.getColor(), Colors.amber);
      expect(Emotion.neutral.getColor(), Colors.grey);
      expect(Emotion.sad.getColor(), Colors.blue);
      expect(Emotion.angry.getColor(), Colors.red);
    });

    test('should return correct image paths', () {
      expect(Emotion.excited.getImagePath(), 'assets/images/emotions/excited.png');
      expect(Emotion.happy.getImagePath(), 'assets/images/emotions/happy.png');
      expect(Emotion.neutral.getImagePath(), 'assets/images/emotions/neutral.png');
      expect(Emotion.sad.getImagePath(), 'assets/images/emotions/sad.png');
      expect(Emotion.angry.getImagePath(), 'assets/images/emotions/angry.png');
    });

    test('should return correct display names', () {
      expect(Emotion.excited.getDisplayName(), '흥분');
      expect(Emotion.happy.getDisplayName(), '기쁨');
      expect(Emotion.neutral.getDisplayName(), '보통');
      expect(Emotion.sad.getDisplayName(), '슬픔');
      expect(Emotion.angry.getDisplayName(), '화남');
    });
  });

  group('EmotionExtension Tests', () {
    test('should return correct intensity values', () {
      expect(Emotion.excited.intensity, 5);
      expect(Emotion.happy.intensity, 4);
      expect(Emotion.neutral.intensity, 3);
      expect(Emotion.sad.intensity, 2);
      expect(Emotion.angry.intensity, 1);
    });

    test('should return valid fallback icons', () {
      for (final emotion in Emotion.values) {
        expect(emotion.fallbackIcon, isA<IconData>());
      }
    });

    test('should have specific fallback icons', () {
      expect(Emotion.happy.fallbackIcon, Icons.sentiment_very_satisfied);
      expect(Emotion.excited.fallbackIcon, Icons.celebration);
      expect(Emotion.neutral.fallbackIcon, Icons.sentiment_neutral);
      expect(Emotion.sad.fallbackIcon, Icons.sentiment_very_dissatisfied);
      expect(Emotion.angry.fallbackIcon, Icons.sentiment_very_dissatisfied);
    });
  });
}