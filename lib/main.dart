import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:baseball_diary2/widgets/themes.dart';
import 'package:baseball_diary2/main_navigation_screen.dart';
import 'package:baseball_diary2/screens/team_selection_screen.dart';
import 'package:baseball_diary2/services/auth_service.dart';
import 'package:baseball_diary2/controllers/calendar_controller.dart';
import 'package:baseball_diary2/controllers/theme_controller.dart';
import 'package:baseball_diary2/services/team_selection_helper.dart';
import 'package:baseball_diary2/screens/auth/auth_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AuthService().initialize();
  runApp(const BaseballDiaryApp());
}

class BaseballDiaryApp extends StatefulWidget {
  const BaseballDiaryApp({super.key});

  @override
  State<BaseballDiaryApp> createState() => _BaseballDiaryAppState();
}

class _BaseballDiaryAppState extends State<BaseballDiaryApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => CalendarController()),
        ChangeNotifierProvider(create: (context) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Baseball Diary',
            home: const AppInitializer(),
            theme: Themes.lightTheme,
            darkTheme: Themes.darkTheme,
            themeMode: themeController.themeMode,
          );
        },
      ),
    );
  }
}

/// 앱 초기화 및 라우팅을 담당하는 위젯
class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('초기화 중...'),
                ],
              ),
            ),
          );
        }

        // 인증되지 않은 경우 AuthScreen으로 리다이렉트
        if (!authService.isAuthenticated) {
          return const AuthScreen();
        }

        return FutureBuilder<bool>(
          future: TeamSelectionHelper.hasSelectedTeam(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasSelectedTeam = snapshot.data ?? false;

            if (hasSelectedTeam) {
              return const MainNavigationScreen();
            } else {
              return TeamSelectionScreen(
                onTeamSelected: (team) {
                  // 팀 선택 시 저장만 하고 테마는 변경하지 않음
                },
              );
            }
          },
        );
      },
    );
  }
}
