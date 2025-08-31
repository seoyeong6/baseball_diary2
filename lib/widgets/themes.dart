import 'package:flutter/material.dart';

class Themes {
  final Color colorSeed;
  
  Themes({this.colorSeed = Colors.black});

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
