import 'package:flutter/material.dart';
import 'package:baseball_diary2/widgets/themes.dart';
import 'package:baseball_diary2/main_navigation_screen.dart';
import 'package:baseball_diary2/screens/team_selection_screen.dart';
import 'package:baseball_diary2/services/auth_service.dart';
import 'package:baseball_diary2/services/team_selection_helper.dart';

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
      home: const AppInitializer(),
      theme: Themes().lightTheme,
      darkTheme: Themes().darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}

/// 앱 초기화 및 라우팅을 담당하는 위젯
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: TeamSelectionHelper.hasSelectedTeam(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final hasSelectedTeam = snapshot.data ?? false;
        
        if (hasSelectedTeam) {
          return const MainNavigationScreen();
        } else {
          return const TeamSelectionScreen();
        }
      },
    );
  }
}
