import 'package:flutter/material.dart';

/// App theme tuned to match the "1DM"-style UI you shared (purple accent).
///
/// This only changes UI colors/feel.
class GopeedTheme {
  // 1DM-like purple
  static const _purplePrimaryValue = 0xFF6A1B9A; // deep purple
  static const _purple = MaterialColor(_purplePrimaryValue, <int, Color>{
    50: Color(0xFFF3E5F5),
    100: Color(0xFFE1BEE7),
    200: Color(0xFFCE93D8),
    300: Color(0xFFBA68C8),
    400: Color(0xFFAB47BC),
    500: Color(_purplePrimaryValue),
    600: Color(0xFF5E1789),
    700: Color(0xFF52137A),
    800: Color(0xFF460F6B),
    900: Color(0xFF3A0B5C),
  });

  static const _purpleAccentValue = 0xFFE1BEE7;
  static const _purpleAccent = MaterialColor(_purpleAccentValue, <int, Color>{
    100: Color(0xFFF3E5F5),
    200: Color(_purpleAccentValue),
    400: Color(0xFFCE93D8),
    700: Color(0xFFBA68C8),
  });

  static final _light = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    primarySwatch: _purple,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(_purplePrimaryValue),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(_purplePrimaryValue),
      foregroundColor: Colors.white,
    ),
  );

  static final light = _light.copyWith(
    colorScheme: _light.colorScheme.copyWith(secondary: _purpleAccent),
  );

  static final _dark = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    primarySwatch: _purple,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(_purplePrimaryValue),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(_purplePrimaryValue),
      foregroundColor: Colors.white,
    ),
  );

  static final dark = _dark.copyWith(
    colorScheme: _dark.colorScheme.copyWith(secondary: _purpleAccent),
  );
}
