import 'package:flutter/material.dart';
import '../models/emotion.dart';

class EmotionPreviewScreen extends StatelessWidget {
  const EmotionPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 상태 미리보기'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5개 감정 상태',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: Emotion.getAllEmotions().length,
                itemBuilder: (context, index) {
                  final emotion = Emotion.getAllEmotions()[index];
                  return EmotionCard(emotion: emotion);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmotionCard extends StatelessWidget {
  final Emotion emotion;

  const EmotionCard({
    super.key,
    required this.emotion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 감정 아이콘 (PNG 파일이 없을 경우 대체 아이콘)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: emotion.getColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: emotion.getColor(),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  emotion.fallbackIcon,
                  size: 32,
                  color: emotion.getColor(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // 감정 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emotion.getDisplayName(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: emotion.getColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Value: ${emotion.value}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG: ${emotion.getImagePath()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            // 감정 속성
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '강도: ${emotion.intensity}/5',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: emotion.getColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 홈 스크린에서 접근할 수 있도록 버튼 추가용 위젯
class EmotionPreviewButton extends StatelessWidget {
  const EmotionPreviewButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EmotionPreviewScreen(),
          ),
        );
      },
      icon: const Icon(Icons.emoji_emotions),
      label: const Text('감정 상태 미리보기'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
    );
  }
}