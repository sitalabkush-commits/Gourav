import 'package:flutter/material.dart';

/// Dark only. Black / white / grey. No colour accents.
ThemeData buildTheme() {
  const black = Color(0xFF000000);
  const surface = Color(0xFF111111);
  const line = Color(0xFF2E2E2E);
  const muted = Color(0xFF9A9A9A);

  const scheme = ColorScheme.dark(
    primary: Colors.white,
    onPrimary: black,
    secondary: Color(0xFFBDBDBD),
    onSecondary: black,
    surface: surface,
    onSurface: Colors.white,
    error: Colors.white,
    onError: black,
    outline: line,
  );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: line),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: black,
    fontFamily: 'NotoSansBengali',
    dividerColor: line,
    appBarTheme: const AppBarTheme(
      backgroundColor: black,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: const TextStyle(color: muted),
      hintStyle: const TextStyle(color: muted),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: Colors.white)),
      errorBorder: border.copyWith(borderSide: const BorderSide(color: Color(0xFFBDBDBD))),
      focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: Colors.white)),
      errorStyle: const TextStyle(color: Color(0xFFBDBDBD)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: black,
        disabledBackgroundColor: const Color(0xFF3A3A3A),
        disabledForegroundColor: muted,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: line),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: line),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: surface),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: surface),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(color: black),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: black,
      indicatorColor: const Color(0xFF2A2A2A),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? const Color(0xFF6A6A6A) : const Color(0xFF222222)),
      trackOutlineColor: WidgetStateProperty.all(line),
    ),
  );
}
