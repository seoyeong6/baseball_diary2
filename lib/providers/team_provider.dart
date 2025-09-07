import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../services/team_selection_helper.dart';

class TeamProvider extends ChangeNotifier {
  static final TeamProvider _instance = TeamProvider._internal();
  factory TeamProvider() => _instance;
  TeamProvider._internal();

  Team? _selectedTeam;
  bool _isLoading = false;

  Team? get selectedTeam => _selectedTeam;
  int? get selectedTeamId => _selectedTeam?.id;
  bool get isLoading => _isLoading;
  bool get hasSelectedTeam => _selectedTeam != null;

  /// 선택된 팀 로드
  Future<void> loadSelectedTeam() async {
    _isLoading = true;
    notifyListeners();

    try {
      final team = await TeamSelectionHelper.getSelectedTeam();
      _selectedTeam = team;
      print('TeamProvider: Loaded team: ${team?.name}');
    } catch (e) {
      print('TeamProvider: Error loading team: $e');
      _selectedTeam = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 팀 선택 및 저장
  Future<void> selectTeam(Team team) async {
    _isLoading = true;
    notifyListeners();

    try {
      await TeamSelectionHelper.saveSelectedTeam(team);
      _selectedTeam = team;
      print('TeamProvider: Selected team: ${team.name}');
    } catch (e) {
      print('TeamProvider: Error selecting team: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 팀 선택 해제
  Future<void> clearSelectedTeam() async {
    _selectedTeam = null;
    notifyListeners();
    
    // SharedPreferences에서도 제거하려면 TeamSelectionHelper에 clear 메서드 추가 필요
  }

  /// 앱 시작 시 초기화
  Future<void> initialize() async {
    await loadSelectedTeam();
  }
}