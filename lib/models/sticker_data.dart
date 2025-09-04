import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum StickerType {
  // 경기 관련
  watch('watch', '관람', Icons.stadium, Colors.blue),
  victory('victory', '승리', Icons.emoji_events, Colors.amber),
  defeat('defeat', '패배', Icons.thumb_down, Colors.grey),
  draw('draw', '무승부', Icons.drag_handle, Colors.orange),
  
  // 활동 관련
  practice('practice', '연습', Icons.sports_baseball, Colors.green),
  training('training', '훈련', Icons.directions_run, Colors.teal),
  analysis('analysis', '분석', Icons.analytics, Colors.purple),
  
  // 특별한 순간
  homerun('homerun', '홈런', FontAwesomeIcons.baseballBatBall, Colors.red),
  strikeout('strikeout', '삼진', Icons.close, Colors.deepOrange),
  steal('steal', '도루', Icons.flash_on, Colors.cyan),
  
  // 기타
  rain('rain', '우천', Icons.cloud, Colors.blueGrey),
  postponed('postponed', '연기', Icons.schedule, Colors.brown),
  special('special', '특별', Icons.star, Colors.pink);

  const StickerType(this.value, this.displayName, this.icon, this.color);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  // 문자열로부터 StickerType 생성
  static StickerType fromString(String value) {
    return StickerType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StickerType.special,
    );
  }

  // JSON 직렬화
  String toJson() => value;

  // JSON 역직렬화
  static StickerType fromJson(String json) => fromString(json);

  // 모든 스티커 타입 목록 반환
  static List<StickerType> getAllTypes() {
    return StickerType.values;
  }

  // 카테고리별 스티커 타입 반환
  static List<StickerType> getGameRelatedTypes() {
    return [
      StickerType.watch, 
      StickerType.victory, 
      StickerType.defeat, 
      StickerType.draw,
      StickerType.homerun,
      StickerType.strikeout,
      StickerType.steal,
    ];
  }

  static List<StickerType> getActivityTypes() {
    return [StickerType.practice, StickerType.training, StickerType.analysis];
  }


  static List<StickerType> getSpecialMomentTypes() {
    return [StickerType.homerun, StickerType.strikeout, StickerType.steal];
  }

  @override
  String toString() => value;
}

class StickerData {
  final String id;
  final StickerType type;
  final DateTime date;
  final double positionX; // 캘린더 셀 내 위치 (0.0 ~ 1.0), 기본값 0.5 (중앙)
  final double positionY; // 캘린더 셀 내 위치 (0.0 ~ 1.0), 기본값 0.5 (중앙)
  final String? memo; // 간단한 메모
  final int? teamId; // 연관된 팀 ID (선택사항)

  const StickerData({
    required this.id,
    required this.type,
    required this.date,
    this.positionX = 0.5, // 기본값: 중앙
    this.positionY = 0.5, // 기본값: 중앙
    this.memo,
    this.teamId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'date': date.toIso8601String(),
      'positionX': positionX,
      'positionY': positionY,
      'memo': memo,
      'teamId': teamId,
    };
  }

  factory StickerData.fromJson(Map<String, dynamic> json) {
    return StickerData(
      id: json['id'] as String,
      type: StickerType.fromJson(json['type'] as String),
      date: DateTime.parse(json['date'] as String),
      positionX: (json['positionX'] as double?) ?? 0.5,
      positionY: (json['positionY'] as double?) ?? 0.5,
      memo: json['memo'] as String?,
      teamId: json['teamId'] as int?,
    );
  }

  StickerData copyWith({
    String? id,
    StickerType? type,
    DateTime? date,
    double? positionX,
    double? positionY,
    String? memo,
    int? teamId,
  }) {
    return StickerData(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      memo: memo ?? this.memo,
      teamId: teamId ?? this.teamId,
    );
  }

  // 같은 날짜인지 확인 (시간 제외)
  bool isSameDate(DateTime other) {
    return date.year == other.year &&
           date.month == other.month &&
           date.day == other.day;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StickerData && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StickerData{id: $id, type: $type, date: $date, positionX: $positionX, positionY: $positionY, memo: $memo, teamId: $teamId}';
  }
}

// StickerData 확장 유틸리티
extension StickerDataExtension on StickerData {
  // 스티커가 특정 팀과 연관되어 있는지 확인
  bool isRelatedToTeam(int teamId) {
    return this.teamId == teamId;
  }

  // 스티커가 게임 관련인지 확인
  bool get isGameRelated {
    return StickerType.getGameRelatedTypes().contains(type);
  }

  // 스티커가 활동 관련인지 확인
  bool get isActivity {
    return StickerType.getActivityTypes().contains(type);
  }


  // 스티커가 특별한 순간인지 확인
  bool get isSpecialMoment {
    return StickerType.getSpecialMomentTypes().contains(type);
  }
}