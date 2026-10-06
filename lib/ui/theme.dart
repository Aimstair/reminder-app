/// Apple-style theme on Material 3 (design-direction.md §2–3): grouped backgrounds, flat surfaces,
/// one accent color, iOS-like type scale.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? AppColors.light : AppColors.dark;
  final scheme = ColorScheme.fromSeed(seedColor: c.accent, brightness: brightness).copyWith(
    primary: c.accent,
    surface: c.surface,
    error: c.danger,
    onSurface: c.textPrimary,
    outlineVariant: c.separator,
  );
  final base = ThemeData(colorScheme: scheme, brightness: brightness, useMaterial3: true);
  final text = base.textTheme.copyWith(
    displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: c.textPrimary, letterSpacing: 0.4),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary),
    bodyLarge: TextStyle(fontSize: 17, color: c.textPrimary),
    bodyMedium: TextStyle(fontSize: 15, color: c.textSecondary),
    bodySmall: TextStyle(fontSize: 13, color: c.textSecondary),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.textSecondary),
  );
  return base.copyWith(
    scaffoldBackgroundColor: c.bgGrouped,
    textTheme: text,
    extensions: [c],
    dividerTheme: DividerThemeData(color: c.separator, thickness: 0.5, space: 0.5),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bgGrouped,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceElevated,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    ),
  );
}
