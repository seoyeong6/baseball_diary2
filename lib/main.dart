import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:baseball_diary2/widgets/themes.dart';
import 'package:baseball_diary2/services/auth_service.dart';
import 'package:baseball_diary2/controllers/calendar_controller.dart';
import 'package:baseball_diary2/controllers/theme_controller.dart';
import 'package:baseball_diary2/routing/router_config.dart';
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
          return MaterialApp.router(
            title: 'Baseball Diary',
            routerConfig: appRouter,
            theme: Themes.lightTheme,
            darkTheme: Themes.darkTheme,
            themeMode: themeController.themeMode,
          );
        },
      ),
    );
  }
}

