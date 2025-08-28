import 'package:flutter/material.dart';
import 'package:baseball_diary2/widgets/themes.dart';
import 'package:baseball_diary2/main_navigation_screen.dart';
import 'package:baseball_diary2/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initialize();
  runApp(const BaseballDiaryApp());
}

class BaseballDiaryApp extends StatelessWidget {
  const BaseballDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baseball Diary',
      home: const MainNavigationScreen(),
      theme: Themes().lightTheme,
      darkTheme: Themes().darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
