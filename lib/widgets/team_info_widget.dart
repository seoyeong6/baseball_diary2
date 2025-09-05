import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/team_selection_helper.dart';

class TeamInfoWidget extends StatefulWidget {
  const TeamInfoWidget({super.key});

  @override
  State<TeamInfoWidget> createState() => _TeamInfoWidgetState();
}

class _TeamInfoWidgetState extends State<TeamInfoWidget> {
  Team? _selectedTeam;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedTeam();
  }

  Future<void> _loadSelectedTeam() async {
    try {
      debugPrint('Loading selected team...');
      final team = await TeamSelectionHelper.getSelectedTeam();
      debugPrint('Loaded team: $team');
      if (mounted) {
        setState(() {
          _selectedTeam = team;
          _isLoading = false;
        });
        debugPrint('Team set in state: $_selectedTeam');
      }
    } catch (e) {
      debugPrint('Error loading team: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTeamDisplayName(String teamName) {
    // 한글 팀명의 첫 번째 단어를 추출
    // 예: "키움 히어로즈" -> "키움", "LG 트윈스" -> "LG"
    debugPrint('Original team name: $teamName');
    final words = teamName.split(' ');
    debugPrint('Split words: $words');
    if (words.isNotEmpty) {
      final result = words.first;
      debugPrint('Display name: $result');
      return result;
    }
    debugPrint('Using original name: $teamName');
    return teamName;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 6),
            Text(
              '로딩...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedTeam == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_baseball, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              '팀 미선택',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      _getTeamDisplayName(_selectedTeam!.name),
      style: TextStyle(
        fontSize: 14,
        color: _selectedTeam!.primaryColor,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
