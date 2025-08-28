import 'package:flutter/material.dart';
import '../models/team.dart';

class TeamColorPreviewScreen extends StatelessWidget {
  const TeamColorPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KBO 구단 색상 미리보기'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: KBOTeams.teams.length,
          itemBuilder: (context, index) {
            final team = KBOTeams.teams[index];
            return TeamColorCard(team: team);
          },
        ),
      ),
    );
  }
}

class TeamColorCard extends StatelessWidget {
  final Team team;

  const TeamColorCard({
    super.key,
    required this.team,
  });

  Color _parseColor(String colorString) {
    return Color(int.parse(colorString.substring(1, 7), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _parseColor(team.primaryColor);
    final secondaryColor = _parseColor(team.secondaryColor);
    
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              secondaryColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            // 색상 정보 표시
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      team.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 하단에 색상 코드 표시
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            team.primaryColor,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            team.secondaryColor,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 홈 스크린에서 접근할 수 있도록 버튼 추가용 위젯
class TeamColorPreviewButton extends StatelessWidget {
  const TeamColorPreviewButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const TeamColorPreviewScreen(),
          ),
        );
      },
      icon: const Icon(Icons.palette),
      label: const Text('구단 색상 미리보기'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}