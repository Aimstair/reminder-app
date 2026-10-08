/// Apple-style theme on Material 3 (design-direction.md §2–3, DS14): grouped backgrounds, flat
/// surfaces, one accent color, the iOS type scale (sizes, weights, line heights) set in Inter with
/// SF-like tracking, iOS page transitions, bouncing scroll, no ripples.
library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'icons.dart';
import 'tokens.dart';

/// Inter's size-dependent tracking (rsms.me/inter/dynmetrics), which brings it close to SF Pro's
/// optical sizes: tighter for large titles, neutral for captions.
double tracking(double size) => size * (-0.0223 + 0.185 * math.exp(-0.1745 * size));

TextStyle _ios(double size, double lineHeight, FontWeight weight, Color color) => TextStyle(
  fontFamily: 'Inter',
  fontSize: size,
  height: lineHeight / size,
  fontWeight: weight,
  letterSpacing: tracking(size),
  color: color,
  leadingDistribution: TextLeadingDistribution.even,
);

/// iOS text styles (HIG, Large/default Dynamic Type size) mapped onto Material's slots:
/// Large Title 34 · Title 1 28 · Title 2 22 · Title 3 20 · Headline 17 semibold · Body 17 ·
/// Callout 16 · Subheadline 15 · Footnote 13 · Caption 12 · Caption 2 11.
TextTheme _textTheme(AppColors c) => TextTheme(
  displayLarge: _ios(34, 41, FontWeight.w700, c.textPrimary), // Large Title
  displayMedium: _ios(34, 41, FontWeight.w700, c.textPrimary),
  displaySmall: _ios(34, 41, FontWeight.w700, c.textPrimary),
  headlineLarge: _ios(28, 34, FontWeight.w700, c.textPrimary), // Title 1
  headlineMedium: _ios(22, 28, FontWeight.w700, c.textPrimary), // Title 2
  headlineSmall: _ios(20, 25, FontWeight.w600, c.textPrimary), // Title 3
  titleLarge: _ios(22, 28, FontWeight.w700, c.textPrimary), // Title 2
  titleMedium: _ios(17, 22, FontWeight.w600, c.textPrimary), // Headline
  titleSmall: _ios(15, 20, FontWeight.w600, c.textPrimary), // Subheadline, semibold
  bodyLarge: _ios(17, 22, FontWeight.w400, c.textPrimary), // Body
  bodyMedium: _ios(15, 20, FontWeight.w400, c.textSecondary), // Subheadline
  bodySmall: _ios(13, 18, FontWeight.w400, c.textSecondary), // Footnote
  labelLarge: _ios(15, 20, FontWeight.w600, c.textPrimary), // small buttons, chips
  labelMedium: _ios(12, 16, FontWeight.w500, c.textSecondary), // Caption 1
  labelSmall: _ios(12, 16, FontWeight.w500, c.textSecondary),
);

/// Bouncing, glow-free scrolling everywhere (iOS feel).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? AppColors.light : AppColors.dark;
  final scheme = ColorScheme.fromSeed(seedColor: c.accent, brightness: brightness).copyWith(
    primary: c.accent,
    surface: c.surface,
    error: c.danger,
    onSurface: c.textPrimary,
    outlineVariant: c.separator,
  );
  final text = _textTheme(c);
  final base = ThemeData(colorScheme: scheme, brightness: brightness, useMaterial3: true, fontFamily: 'Inter');
  final roundRect = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.row));
  // iOS cells turn grey while pressed instead of rippling.
  final pressGrey = c.textPrimary.withValues(alpha: brightness == Brightness.light ? 0.06 : 0.10);
  return base.copyWith(
    scaffoldBackgroundColor: c.bgGrouped,
    textTheme: text,
    extensions: [c],
    splashFactory: NoSplash.splashFactory,
    highlightColor: pressGrey,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    // iOS back chevron instead of Material's arrow.
    actionIconTheme: ActionIconThemeData(backButtonIconBuilder: (_) => const Icon(AppIcons.previous)),
    cupertinoOverrideTheme: CupertinoThemeData(primaryColor: c.accent, brightness: brightness),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? c.success : null),
      thumbColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Colors.white : null),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected) ? Colors.transparent : null,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const CircleBorder(),
      side: BorderSide(color: c.separator, width: 1.5),
      splashRadius: 0,
    ),
    dividerTheme: DividerThemeData(color: c.separator, thickness: 0.5, space: 0.5),
    listTileTheme: ListTileThemeData(
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodySmall,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l),
      minVerticalPadding: Space.m,
      iconColor: c.textSecondary,
      selectedColor: c.accent,
      selectedTileColor: c.accent.withValues(alpha: 0.10),
      shape: roundRect,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bgGrouped,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleMedium,
      toolbarHeight: 52,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: c.accent, fixedSize: const Size.square(44), iconSize: 24),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: roundRect,
        minimumSize: const Size(64, 50),
        textStyle: text.titleMedium, // 17 semibold, like iOS buttons
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        shape: roundRect,
        textStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: Space.m),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: roundRect, minimumSize: const Size(64, 50), textStyle: text.titleMedium),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      labelStyle: text.titleSmall,
      padding: const EdgeInsets.symmetric(horizontal: Space.s),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: text.bodyLarge,
      labelTextStyle: WidgetStatePropertyAll(text.bodyLarge),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surfaceElevated),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sheet - 4)),
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium?.copyWith(color: c.textPrimary),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: c.bgGrouped,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(Radii.sheet))),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: Colors.white,
      elevation: 6,
      highlightElevation: 2,
      shape: const CircleBorder(),
      sizeConstraints: const BoxConstraints.tightFor(width: 60, height: 60),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: text.bodyMedium?.copyWith(color: brightness == Brightness.light ? Colors.white : Colors.black),
      elevation: 6,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false, // SheetGrabber: iOS-sized, without Material's 48dp handle area
      dragHandleSize: const Size(36, 5),
      dragHandleColor: c.separator,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
  );
}
