import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/emotion_preview.dart';
import '../screens/sticker_preview.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListenableBuilder(
              listenable: AuthService(),
              builder: (context, child) {
                final user = AuthService().currentUser;
                return Column(
                  children: [
                    const Icon(
                      Icons.sports_baseball,
                      size: 80,
                      color: Colors.brown,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome, ${user?.name ?? 'User'}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to track your baseball journey?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            const EmotionPreviewButton(),
            const SizedBox(height: 16),
            const StickerPreviewButton(),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await AuthService().signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class StickerPreviewButton extends StatelessWidget {
  const StickerPreviewButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StickerPreviewScreen()),
        );
      },
      icon: const Icon(Icons.star),
      label: const Text('스티커 미리보기'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
