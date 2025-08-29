import 'package:flutter/material.dart';
import '../models/team.dart';

/// 최초 실행 시 사용자가 좋아하는 KBO 구단을 선택하는 화면
class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  Team? _selectedTeam;

  void _selectTeam(Team team) {
    setState(() {
      _selectedTeam = team;
    });
  }

  void _confirmSelection() {
    if (_selectedTeam != null) {
      // TODO: 선택된 팀 저장 로직 추가 (Task 2.5에서 구현)
      // TODO: 메인 화면으로 이동 (Task 2.6에서 구현)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedTeam!.name}를 선택했습니다!'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '좋아하는 구단을 선택하세요',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 안내 메시지
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '앞으로 야구 다이어리에서 응원할 구단을 선택해주세요.\n언제든지 설정에서 변경할 수 있습니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
          ),
          
          // 구단 선택 그리드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: KBOTeams.getAllTeams().length,
                itemBuilder: (context, index) {
                  final team = KBOTeams.getAllTeams()[index];
                  final isSelected = _selectedTeam?.id == team.id;
                  
                  return _TeamCard(
                    team: team,
                    isSelected: isSelected,
                    onTap: () => _selectTeam(team),
                  );
                },
              ),
            ),
          ),
          
          // 확인 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedTeam != null ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor: theme.disabledColor,
                  elevation: _selectedTeam != null ? 4 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _selectedTeam != null 
                      ? '${_selectedTeam!.name} 선택하기'
                      : '구단을 선택해주세요',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // 하단 여백
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// 개별 구단 선택 카드 위젯
class _TeamCard extends StatefulWidget {
  final Team team;
  final bool isSelected;
  final VoidCallback onTap;

  const _TeamCard({
    required this.team,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TeamCard> createState() => __TeamCardState();
}

class __TeamCardState extends State<_TeamCard> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.isSelected 
              ? theme.primaryColor.withValues(alpha: 0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected 
                ? theme.primaryColor 
                : theme.dividerColor,
            width: widget.isSelected ? 4 : 1, // 선택 시 더 굵은 테두리
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 팀 로고
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  widget.team.logoPath,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지 로드 실패 시 플레이스홀더 표시
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_baseball,
                        size: 100,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 팀 이름 오버레이
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.team.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isSelected 
                        ? FontWeight.bold 
                        : FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            // 선택 표시
            if (widget.isSelected) 
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}