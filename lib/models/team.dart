class Team {
  final int id;
  final String name;
  final String logoPath;

  const Team({
    required this.id,
    required this.name,
    required this.logoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoPath': logoPath,
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String,
      logoPath: json['logoPath'] as String,
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
      logoPath: 'assets/images/teams/lg_twins.png',
    ),
    Team(
      id: 2,
      name: '키움 히어로즈',
      logoPath: 'assets/images/teams/kiwoom_heroes.png',
    ),
    Team(
      id: 3,
      name: 'KT 위즈',
      logoPath: 'assets/images/teams/kt_wiz.png',
    ),
    Team(
      id: 4,
      name: 'SSG 랜더스',
      logoPath: 'assets/images/teams/ssg_landers.png',
    ),
    Team(
      id: 5,
      name: 'NC 다이노스',
      logoPath: 'assets/images/teams/nc_dinos.png',
    ),
    Team(
      id: 6,
      name: '두산 베어스',
      logoPath: 'assets/images/teams/doosan_bears.png',
    ),
    Team(
      id: 7,
      name: 'KIA 타이거즈',
      logoPath: 'assets/images/teams/kia_tigers.png',
    ),
    Team(
      id: 8,
      name: '롯데 자이언츠',
      logoPath: 'assets/images/teams/lotte_giants.png',
    ),
    Team(
      id: 9,
      name: '삼성 라이온즈',
      logoPath: 'assets/images/teams/samsung_lions.png',
    ),
    Team(
      id: 10,
      name: '한화 이글스',
      logoPath: 'assets/images/teams/hanwha_eagles.png',
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