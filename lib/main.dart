import 'package:flutter/material.dart';
import 'package:baseball_diary2/main_navigation_screen.dart';

void main() {
  runApp(const BaseballDiaryApp());
}

class BaseballDiaryApp extends StatelessWidget {
  const BaseballDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baseball Diary',
      theme: ThemeData(primarySwatch: Colors.grey),
      home: MainNavigationScreen(),
    );
  }
}
