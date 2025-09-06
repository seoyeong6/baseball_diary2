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
      final team = await TeamSelectionHelper.getSelectedTeam();
      if (mounted) {
        setState(() {
          _selectedTeam = team;
          _isLoading = false;
        });
      }
    } catch (e) {
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
    final words = teamName.split(' ');
    if (words.isNotEmpty) {
      return words.first;
    }
    return teamName;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '로딩...',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedTeam == null) {
      return IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 100),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_baseball, size: 12, color: Colors.grey),
              SizedBox(width: 3),
              Expanded(
                child: Text(
                  '팀 미선택',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Text(
        _getTeamDisplayName(_selectedTeam!.name),
        style: TextStyle(
          fontSize: 13,
          color: _selectedTeam!.primaryColor,
          fontWeight: FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
