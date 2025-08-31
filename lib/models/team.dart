import 'package:flutter/material.dart';

class Team {
  final int id;
  final String name;
  final String logoPath;
  final Color primaryColor;

  const Team({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.primaryColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoPath': logoPath,
      'primaryColor': primaryColor.value,
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String,
      logoPath: json['logoPath'] as String,
      primaryColor: Color(json['primaryColor'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Team{id: $id, name: $name, logoPath: $logoPath}';
  }
}

// KBO 10개 구단 데이터
class KBOTeams {
  static const List<Team> teams = [
    Team(
      id: 1,
      name: 'LG 트윈스',
      logoPath: 'lib/assets/images/teams/lg_twins.png',
      primaryColor: Color(0xFFC30452), // LG 트윈스 핑크
    ),
    Team(
      id: 2,
      name: '키움 히어로즈',
      logoPath: 'lib/assets/images/teams/kiwoom_heroes.png',
      primaryColor: Color(0xFF570514), // 키움 히어로즈 보라
    ),
    Team(
      id: 3,
      name: 'KT 위즈',
      logoPath: 'lib/assets/images/teams/kt_wiz.png',
      primaryColor: Color(0xFF000000), // KT 위즈 검정
    ),
    Team(
      id: 4,
      name: 'SSG 랜더스',
      logoPath: 'lib/assets/images/teams/ssg_landers.png',
      primaryColor: Color(0xFFce0e2d), // SSG 랜더스 파랑
    ),
    Team(
      id: 5,
      name: 'NC 다이노스',
      logoPath: 'lib/assets/images/teams/nc_dinos.png',
      primaryColor: Color(0xff315288), // NC 다이노스 네이비
    ),
    Team(
      id: 6,
      name: '두산 베어스',
      logoPath: 'lib/assets/images/teams/doosan_bears.png',
      primaryColor: Color(0xFF1A1748), // 두산 베어스 파랑
    ),
    Team(
      id: 7,
      name: 'KIA 타이거즈',
      logoPath: 'lib/assets/images/teams/kia_tigers.png',
      primaryColor: Color(0xFFEA0029), // KIA 타이거즈 빨강
    ),
    Team(
      id: 8,
      name: '롯데 자이언츠',
      logoPath: 'lib/assets/images/teams/lotte_giants.png',
      primaryColor: Color(0xFF041E42), // 롯데 자이언츠 네이비
    ),
    Team(
      id: 9,
      name: '삼성 라이온즈',
      logoPath: 'lib/assets/images/teams/samsung_lions.png',
      primaryColor: Color(0xFF074CA1), // 삼성 라이온즈 파랑
    ),
    Team(
      id: 10,
      name: '한화 이글스',
      logoPath: 'lib/assets/images/teams/hanhwa-eagles.png',
      primaryColor: Color(0xFFFC4E00), // 한화 이글스 주황
    ),
  ];

  // ID로 팀 찾기
  static Team? getTeamById(int id) {
    try {
      return teams.firstWhere((team) => team.id == id);
    } catch (e) {
      return null;
    }
  }

  // 팀 이름으로 찾기
  static Team? getTeamByName(String name) {
    try {
      return teams.firstWhere((team) => team.name == name);
    } catch (e) {
      return null;
    }
  }

  // 모든 팀 목록 반환
  static List<Team> getAllTeams() {
    return List.unmodifiable(teams);
  }
}
