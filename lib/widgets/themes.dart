import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class Themes {
  static ThemeData get lightTheme =>
      FlexThemeData.light(scheme: FlexScheme.sanJuanBlue, useMaterial3: false);

  static ThemeData get darkTheme =>
      FlexThemeData.dark(scheme: FlexScheme.sanJuanBlue, useMaterial3: false);
}
