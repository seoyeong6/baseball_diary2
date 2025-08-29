import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/sticker_data.dart';

class StickerPreviewScreen extends StatelessWidget {
  const StickerPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스티커 미리보기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '사용 가능한 스티커들',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: StickerType.values.length,
                itemBuilder: (context, index) {
                  final stickerType = StickerType.values[index];
                  return _buildStickerCard(stickerType);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerCard(StickerType stickerType) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            stickerType.icon.runtimeType == IconData 
              ? Icon(
                  stickerType.icon,
                  size: 32,
                  color: stickerType.color,
                )
              : FaIcon(
                  stickerType.icon as IconData,
                  size: 28,
                  color: stickerType.color,
                ),
            const SizedBox(height: 8),
            Text(
              stickerType.displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}