import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum Emotion {
  excited('excited', 'assets/images/emotions/excited.png', '흥분', Colors.orange),
  happy('happy', 'assets/images/emotions/happy.png', '기쁨', Colors.amber),
  neutral('neutral', 'assets/images/emotions/neutral.png', '보통', Colors.grey),
  sad('sad', 'assets/images/emotions/sad.png', '슬픔', Colors.blue),
  angry('angry', 'assets/images/emotions/angry.png', '화남', Colors.red);

  const Emotion(this.value, this.imagePath, this.displayName, this.color);

  final String value;
  final String imagePath;
  final String displayName;
  final Color color;

  // 문자열로부터 Emotion 생성
  static Emotion fromString(String value) {
    return Emotion.values.firstWhere(
      (emotion) => emotion.value == value,
      orElse: () => Emotion.neutral,
    );
  }

  // JSON 직렬화
  String toJson() => value;

  // JSON 역직렬화
  static Emotion fromJson(String json) => fromString(json);

  // 모든 감정 목록 반환
  static List<Emotion> getAllEmotions() {
    return Emotion.values;
  }

  // 감정에 해당하는 색상 반환
  Color getColor() => color;

  // 감정에 해당하는 이미지 경로 반환
  String getImagePath() => imagePath;

  // 감정 표시명 반환
  String getDisplayName() => displayName;

  @override
  String toString() => value;
}

// Emotion 확장 유틸리티
extension EmotionExtension on Emotion {
  // 감정 강도 (1-5)
  int get intensity {
    switch (this) {
      case Emotion.excited:
        return 5;
      case Emotion.happy:
        return 4;
      case Emotion.neutral:
        return 3;
      case Emotion.sad:
        return 2;
      case Emotion.angry:
        return 1;
    }
  }

  // 감정에 따른 아이콘 (PNG 파일을 사용할 수 없는 경우의 대체재)
  IconData get fallbackIcon {
    switch (this) {
      case Emotion.excited:
        return FontAwesomeIcons.faceGrinSquint;
      case Emotion.happy:
        return Icons.sentiment_very_satisfied;
      case Emotion.neutral:
        return Icons.sentiment_neutral;
      case Emotion.sad:
        return FontAwesomeIcons.faceSadTear;
      case Emotion.angry:
        return Icons.sentiment_very_dissatisfied;
    }
  }
}
