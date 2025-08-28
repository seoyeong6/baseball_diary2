class Team {
  final int id;
  final String name;
  final String primaryColor;
  final String secondaryColor;
  final String logoPath;

  const Team({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.logoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'logoPath': logoPath,
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String,
      primaryColor: json['primaryColor'] as String,
      secondaryColor: json['secondaryColor'] as String,
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
    return 'Team{id: $id, name: $name, primaryColor: $primaryColor, secondaryColor: $secondaryColor, logoPath: $logoPath}';
  }
}

// KBO 10개 구단 데이터 (공식 브랜드 색상 기준)
class KBOTeams {
  static const List<Team> teams = [
    Team(
      id: 1,
      name: 'LG 트윈스',
      primaryColor: '#C30452', // LG 마젠타
      secondaryColor: '#000000', // 블랙
      logoPath: 'assets/images/teams/lg_twins.png',
    ),
    Team(
      id: 2,
      name: '키움 히어로즈',
      primaryColor: '#570514', // 버건디
      secondaryColor: '#D4AF37', // 골드
      logoPath: 'assets/images/teams/kiwoom_heroes.png',
    ),
    Team(
      id: 3,
      name: 'KT 위즈',
      primaryColor: '#000000', // 블랙
      secondaryColor: '#E60012', // KT 레드
      logoPath: 'assets/images/teams/kt_wiz.png',
    ),
    Team(
      id: 4,
      name: 'SSG 랜더스',
      primaryColor: '#002c5f', // 네이비
      secondaryColor: '#ce0e2d', // SSG 레드
      logoPath: 'assets/images/teams/ssg_landers.png',
    ),
    Team(
      id: 5,
      name: 'NC 다이노스',
      primaryColor: '#003478', // NC 네이비
      secondaryColor: '#FFD100', // 골드 옐로우
      logoPath: 'assets/images/teams/nc_dinos.png',
    ),
    Team(
      id: 6,
      name: '두산 베어스',
      primaryColor: '#131230', // 두산 네이비
      secondaryColor: '#E6007E', // 두산 핑크
      logoPath: 'assets/images/teams/doosan_bears.png',
    ),
    Team(
      id: 7,
      name: 'KIA 타이거즈',
      primaryColor: '#EA0029', // KIA 레드
      secondaryColor: '#000000', // 블랙
      logoPath: 'assets/images/teams/kia_tigers.png',
    ),
    Team(
      id: 8,
      name: '롯데 자이언츠',
      primaryColor: '#002244', // 롯데 네이비
      secondaryColor: '#BE0E2C', // 롯데 레드
      logoPath: 'assets/images/teams/lotte_giants.png',
    ),
    Team(
      id: 9,
      name: '삼성 라이온즈',
      primaryColor: '#074CA1', // 삼성 블루
      secondaryColor: '#FFFFFF', // 화이트
      logoPath: 'assets/images/teams/samsung_lions.png',
    ),
    Team(
      id: 10,
      name: '한화 이글스',
      primaryColor: '#FF6600', // 한화 오렌지
      secondaryColor: '#000000', // 블랙
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