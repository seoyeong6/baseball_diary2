import 'package:flutter/material.dart';

class Themes {
  Themes();

  // colorSeed를 고정값(검정색)으로 지정
  final Color colorSeed = Colors.black;

  ThemeData get _baseLightTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: colorSeed,
    brightness: Brightness.light,
  );

  ThemeData get _baseDarkTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: colorSeed,
    brightness: Brightness.dark,
  );

  ThemeData get lightTheme => _baseLightTheme.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: _baseLightTheme.colorScheme.inversePrimary,
    ),
  );

  ThemeData get darkTheme => _baseDarkTheme.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: _baseDarkTheme.colorScheme.inversePrimary,
    ),
  );
}
