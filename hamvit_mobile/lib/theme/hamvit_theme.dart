import 'package:flutter/material.dart';

import 'hamvit_colors.dart';

class HamvitTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: HamvitColors.accentBlue,
        secondary: HamvitColors.accentCyan,
        surface: HamvitColors.darkCard,
        error: HamvitColors.danger,
      ),
      scaffoldBackgroundColor: HamvitColors.primaryDark,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: HamvitColors.darkText,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: HamvitColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(color: HamvitColors.darkText, fontWeight: FontWeight.w800),
        titleLarge: const TextStyle(color: HamvitColors.darkText, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(color: HamvitColors.darkText, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: HamvitColors.darkText),
        bodyMedium: const TextStyle(color: HamvitColors.darkTextMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HamvitColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: HamvitColors.accentBlue, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HamvitColors.accentBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: HamvitColors.primaryNavy,
        indicatorColor: HamvitColors.accentCyan.withValues(alpha: 0.16),
      ),
    );
  }
}
