import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baseball_diary2/models/sticker_data.dart';

void main() {
  group('StickerType Enum Tests', () {
    test('should have correct number of sticker types', () {
      expect(StickerType.values.length, 13);
    });

    test('should have all expected sticker types', () {
      // 경기 관련
      expect(StickerType.values, contains(StickerType.watch));
      expect(StickerType.values, contains(StickerType.victory));
      expect(StickerType.values, contains(StickerType.defeat));
      expect(StickerType.values, contains(StickerType.draw));

      // 활동 관련
      expect(StickerType.values, contains(StickerType.practice));
      expect(StickerType.values, contains(StickerType.training));
      expect(StickerType.values, contains(StickerType.analysis));

      // 특별한 순간
      expect(StickerType.values, contains(StickerType.homerun));
      expect(StickerType.values, contains(StickerType.strikeout));
      expect(StickerType.values, contains(StickerType.steal));

      // 기타
      expect(StickerType.values, contains(StickerType.rain));
      expect(StickerType.values, contains(StickerType.postponed));
      expect(StickerType.values, contains(StickerType.special));
    });

    test('should create sticker type from string correctly', () {
      expect(StickerType.fromString('watch'), StickerType.watch);
      expect(StickerType.fromString('victory'), StickerType.victory);
      expect(StickerType.fromString('homerun'), StickerType.homerun);
    });

    test('should return special for invalid string', () {
      expect(StickerType.fromString('invalid'), StickerType.special);
      expect(StickerType.fromString(''), StickerType.special);
    });

    test('should serialize to JSON correctly', () {
      expect(StickerType.watch.toJson(), 'watch');
      expect(StickerType.victory.toJson(), 'victory');
      expect(StickerType.homerun.toJson(), 'homerun');
    });

    test('should deserialize from JSON correctly', () {
      expect(StickerType.fromJson('watch'), StickerType.watch);
      expect(StickerType.fromJson('victory'), StickerType.victory);
      expect(StickerType.fromJson('homerun'), StickerType.homerun);
    });

    test('should handle JSON serialization round trip', () {
      for (final stickerType in StickerType.values) {
        final json = stickerType.toJson();
        final recreated = StickerType.fromJson(json);
        expect(recreated, stickerType);
      }
    });

    test('should return all types list', () {
      final allTypes = StickerType.getAllTypes();
      expect(allTypes.length, 13);
      expect(allTypes, containsAll(StickerType.values));
    });

    test('should return correct game related types', () {
      final gameTypes = StickerType.getGameRelatedTypes();
      expect(gameTypes, [
        StickerType.watch,
        StickerType.victory,
        StickerType.defeat,
        StickerType.draw
      ]);
    });

    test('should return correct activity types', () {
      final activityTypes = StickerType.getActivityTypes();
      expect(activityTypes, [
        StickerType.practice,
        StickerType.training,
        StickerType.analysis
      ]);
    });

    test('should return correct special moment types', () {
      final specialTypes = StickerType.getSpecialMomentTypes();
      expect(specialTypes, [
        StickerType.homerun,
        StickerType.strikeout,
        StickerType.steal
      ]);
    });

    test('should have valid properties for each sticker type', () {
      for (final stickerType in StickerType.values) {
        expect(stickerType.value, isNotEmpty);
        expect(stickerType.displayName, isNotEmpty);
        expect(stickerType.icon, isA<IconData>());
        expect(stickerType.color, isA<Color>());
      }
    });

    test('should have proper toString representation', () {
      expect(StickerType.watch.toString(), 'watch');
      expect(StickerType.victory.toString(), 'victory');
      expect(StickerType.homerun.toString(), 'homerun');
    });
  });

  group('StickerData Model Tests', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testStickerData = StickerData(
      id: 'sticker-123',
      type: StickerType.victory,
      date: testDate,
      positionX: 0.3,
      positionY: 0.7,
      memo: '승리 기념!',
      teamId: 1,
    );

    test('should create StickerData instance with required fields', () {
      expect(testStickerData.id, 'sticker-123');
      expect(testStickerData.type, StickerType.victory);
      expect(testStickerData.date, testDate);
      expect(testStickerData.positionX, 0.3);
      expect(testStickerData.positionY, 0.7);
      expect(testStickerData.memo, '승리 기념!');
      expect(testStickerData.teamId, 1);
    });

    test('should create StickerData with default position values', () {
      final stickerWithDefaults = StickerData(
        id: 'sticker-456',
        type: StickerType.watch,
        date: testDate,
      );

      expect(stickerWithDefaults.positionX, 0.5);
      expect(stickerWithDefaults.positionY, 0.5);
      expect(stickerWithDefaults.memo, isNull);
      expect(stickerWithDefaults.teamId, isNull);
    });

    test('should convert StickerData to JSON correctly', () {
      final json = testStickerData.toJson();
      
      expect(json, {
        'id': 'sticker-123',
        'type': 'victory',
        'date': testDate.toIso8601String(),
        'positionX': 0.3,
        'positionY': 0.7,
        'memo': '승리 기념!',
        'teamId': 1,
      });
    });

    test('should convert StickerData to JSON with null values', () {
      final stickerWithNulls = StickerData(
        id: 'sticker-789',
        type: StickerType.rain,
        date: testDate,
      );

      final json = stickerWithNulls.toJson();
      
      expect(json['memo'], isNull);
      expect(json['teamId'], isNull);
      expect(json['positionX'], 0.5);
      expect(json['positionY'], 0.5);
    });

    test('should create StickerData from JSON correctly', () {
      final json = {
        'id': 'sticker-123',
        'type': 'victory',
        'date': testDate.toIso8601String(),
        'positionX': 0.3,
        'positionY': 0.7,
        'memo': '승리 기념!',
        'teamId': 1,
      };

      final sticker = StickerData.fromJson(json);

      expect(sticker.id, 'sticker-123');
      expect(sticker.type, StickerType.victory);
      expect(sticker.date, testDate);
      expect(sticker.positionX, 0.3);
      expect(sticker.positionY, 0.7);
      expect(sticker.memo, '승리 기념!');
      expect(sticker.teamId, 1);
    });

    test('should handle JSON serialization round trip', () {
      final json = testStickerData.toJson();
      final recreatedSticker = StickerData.fromJson(json);

      expect(recreatedSticker.id, testStickerData.id);
      expect(recreatedSticker.type, testStickerData.type);
      expect(recreatedSticker.date, testStickerData.date);
      expect(recreatedSticker.positionX, testStickerData.positionX);
      expect(recreatedSticker.positionY, testStickerData.positionY);
      expect(recreatedSticker.memo, testStickerData.memo);
      expect(recreatedSticker.teamId, testStickerData.teamId);
    });

    test('should implement copyWith correctly', () {
      final updatedSticker = testStickerData.copyWith(
        type: StickerType.defeat,
        memo: '수정된 메모',
      );

      expect(updatedSticker.id, testStickerData.id);
      expect(updatedSticker.type, StickerType.defeat);
      expect(updatedSticker.date, testStickerData.date);
      expect(updatedSticker.positionX, testStickerData.positionX);
      expect(updatedSticker.positionY, testStickerData.positionY);
      expect(updatedSticker.memo, '수정된 메모');
      expect(updatedSticker.teamId, testStickerData.teamId);
    });

    test('should implement isSameDate correctly', () {
      final sameDate = DateTime(2024, 1, 15, 15, 45); // Same day, different time
      final differentDate = DateTime(2024, 1, 16, 10, 30);

      expect(testStickerData.isSameDate(sameDate), true);
      expect(testStickerData.isSameDate(differentDate), false);
    });

    test('should implement equality correctly', () {
      final sticker1 = StickerData(
        id: 'same-id',
        type: StickerType.victory,
        date: testDate,
      );

      final sticker2 = StickerData(
        id: 'same-id',
        type: StickerType.defeat,
        date: testDate,
      );

      final sticker3 = StickerData(
        id: 'different-id',
        type: StickerType.victory,
        date: testDate,
      );

      expect(sticker1 == sticker2, true); // Same ID
      expect(sticker1 == sticker3, false); // Different ID
    });

    test('should implement hashCode correctly', () {
      final sticker1 = StickerData(
        id: 'same-id',
        type: StickerType.victory,
        date: testDate,
      );

      final sticker2 = StickerData(
        id: 'same-id',
        type: StickerType.defeat,
        date: testDate,
      );

      expect(sticker1.hashCode, sticker2.hashCode); // Same ID, same hashCode
    });

    test('should have proper toString representation', () {
      final toString = testStickerData.toString();
      
      expect(toString, contains('StickerData{'));
      expect(toString, contains('id: sticker-123'));
      expect(toString, contains('type: StickerType.victory'));
      expect(toString, contains('positionX: 0.3'));
      expect(toString, contains('positionY: 0.7'));
      expect(toString, contains('memo: 승리 기념!'));
      expect(toString, contains('teamId: 1'));
    });
  });

  group('StickerDataExtension Tests', () {
    final testDate = DateTime(2024, 1, 15);

    test('should check if related to team correctly', () {
      final stickerWithTeam = StickerData(
        id: 'test',
        type: StickerType.victory,
        date: testDate,
        teamId: 1,
      );

      final stickerWithoutTeam = StickerData(
        id: 'test2',
        type: StickerType.rain,
        date: testDate,
      );

      expect(stickerWithTeam.isRelatedToTeam(1), true);
      expect(stickerWithTeam.isRelatedToTeam(2), false);
      expect(stickerWithoutTeam.isRelatedToTeam(1), false);
    });

    test('should identify game related stickers', () {
      final gameSticker = StickerData(
        id: 'test',
        type: StickerType.victory,
        date: testDate,
      );

      final nonGameSticker = StickerData(
        id: 'test2',
        type: StickerType.practice,
        date: testDate,
      );

      expect(gameSticker.isGameRelated, true);
      expect(nonGameSticker.isGameRelated, false);
    });

    test('should identify activity stickers', () {
      final activitySticker = StickerData(
        id: 'test',
        type: StickerType.practice,
        date: testDate,
      );

      final nonActivitySticker = StickerData(
        id: 'test2',
        type: StickerType.victory,
        date: testDate,
      );

      expect(activitySticker.isActivity, true);
      expect(nonActivitySticker.isActivity, false);
    });

    test('should identify special moment stickers', () {
      final specialSticker = StickerData(
        id: 'test',
        type: StickerType.homerun,
        date: testDate,
      );

      final nonSpecialSticker = StickerData(
        id: 'test2',
        type: StickerType.rain,
        date: testDate,
      );

      expect(specialSticker.isSpecialMoment, true);
      expect(nonSpecialSticker.isSpecialMoment, false);
    });

    test('should handle all sticker categories', () {
      // Test all game related types
      for (final type in StickerType.getGameRelatedTypes()) {
        final sticker = StickerData(id: 'test', type: type, date: testDate);
        expect(sticker.isGameRelated, true);
        expect(sticker.isActivity, false);
        expect(sticker.isSpecialMoment, false);
      }

      // Test all activity types
      for (final type in StickerType.getActivityTypes()) {
        final sticker = StickerData(id: 'test', type: type, date: testDate);
        expect(sticker.isGameRelated, false);
        expect(sticker.isActivity, true);
        expect(sticker.isSpecialMoment, false);
      }

      // Test all special moment types
      for (final type in StickerType.getSpecialMomentTypes()) {
        final sticker = StickerData(id: 'test', type: type, date: testDate);
        expect(sticker.isGameRelated, false);
        expect(sticker.isActivity, false);
        expect(sticker.isSpecialMoment, true);
      }
    });
  });
}