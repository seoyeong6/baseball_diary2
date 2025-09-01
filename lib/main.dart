import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baseball_diary2/widgets/themes.dart';
import 'package:baseball_diary2/main_navigation_screen.dart';
import 'package:baseball_diary2/screens/team_selection_screen.dart';
import 'package:baseball_diary2/services/auth_service.dart';
import 'package:baseball_diary2/services/team_selection_helper.dart';
import 'package:baseball_diary2/controllers/calendar_controller.dart';
import 'package:baseball_diary2/controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initialize();
  runApp(const BaseballDiaryApp());
}

class BaseballDiaryApp extends StatefulWidget {
  const BaseballDiaryApp({super.key});

  @override
  State<BaseballDiaryApp> createState() => _BaseballDiaryAppState();
}

class _BaseballDiaryAppState extends State<BaseballDiaryApp> {
  Color _currentColorSeed = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadTeamColor();
  }

  Future<void> _loadTeamColor() async {
    try {
      final selectedTeam = await TeamSelectionHelper.getSelectedTeam();
      if (selectedTeam != null && mounted) {
        setState(() {
          _currentColorSeed = selectedTeam.primaryColor;
        });
      }
    } catch (e) {
      // 팀 정보를 불러올 수 없으면 기본 색상 유지
    }
  }

  void updateTeamColor(Color newColor) {
    if (mounted) {
      setState(() {
        _currentColorSeed = newColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = Themes(colorSeed: _currentColorSeed);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CalendarController()),
        ChangeNotifierProvider(create: (context) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Baseball Diary',
            home: AppInitializer(onTeamChanged: updateTeamColor),
            theme: themes.lightTheme,
            darkTheme: themes.darkTheme,
            themeMode: themeController.themeMode,
          );
        },
      ),
    );
  }
}

/// 앱 초기화 및 라우팅을 담당하는 위젯
class AppInitializer extends StatefulWidget {
  final Function(Color) onTeamChanged;
  
  const AppInitializer({super.key, required this.onTeamChanged});

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
          return TeamSelectionScreen(
            onTeamSelected: (team) {
              widget.onTeamChanged(team.primaryColor);
            },
          );
        }
      },
    );
  }
}
