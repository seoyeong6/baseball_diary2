import 'package:shared_preferences/shared_preferences.dart';
import '../models/team.dart';

/// 팀 선택 관련 헬퍼 클래스
class TeamSelectionHelper {
  static const String _selectedTeamKey = 'selected_team_id';
  static const String _hasSelectedTeamKey = 'has_selected_team';

  /// 저장된 팀 ID를 가져옵니다
  static Future<int?> getSelectedTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_selectedTeamKey);
  }

  /// 팀이 선택되었는지 확인합니다
  static Future<bool> hasSelectedTeam() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSelectedTeamKey) ?? false;
  }

  /// 선택된 팀 정보를 가져옵니다
  static Future<Team?> getSelectedTeam() async {
    final teamId = await getSelectedTeamId();
    if (teamId == null) return null;
    
    return KBOTeams.getTeamById(teamId);
  }

  /// 팀을 저장합니다
  static Future<void> saveSelectedTeam(Team team) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedTeamKey, team.id);
    await prefs.setBool(_hasSelectedTeamKey, true);
  }

  /// 선택된 팀 정보를 삭제합니다
  static Future<void> clearSelectedTeam() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedTeamKey);
    await prefs.remove(_hasSelectedTeamKey);
  }
}