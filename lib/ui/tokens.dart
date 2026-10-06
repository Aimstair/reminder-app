/// Design tokens (docs/design-direction.md §3). Starting values; tuned during visual design.
library;

import 'package:flutter/material.dart';
import 'package:reminder_core/reminder_core.dart';

/// Colors not covered by Material's ColorScheme, read with `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgGrouped,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.separator,
    required this.accent,
    required this.danger,
    required this.success,
    required this.warning,
    required this.task,
    required this.meeting,
    required this.event,
    required this.occasion,
  });

  final Color bgGrouped, surface, surfaceElevated, textPrimary, textSecondary, separator;
  final Color accent, danger, success, warning;
  final Color task, meeting, event, occasion;

  static const light = AppColors(
    bgGrouped: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0x993C3C43),
    separator: Color(0x4A3C3C43),
    accent: Color(0xFF007AFF),
    danger: Color(0xFFFF3B30),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9500),
    task: Color(0xFF007AFF),
    meeting: Color(0xFF5856D6),
    event: Color(0xFFFF9500),
    occasion: Color(0xFFFF2D55),
  );

  static const dark = AppColors(
    bgGrouped: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceElevated: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0x99EBEBF5),
    separator: Color(0x99545458),
    accent: Color(0xFF0A84FF),
    danger: Color(0xFFFF453A),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    task: Color(0xFF0A84FF),
    meeting: Color(0xFF5E5CE6),
    event: Color(0xFFFF9F0A),
    occasion: Color(0xFFFF375F),
  );

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

  /// VW-4: each type has a color (never the only signal — see [kindIcon]).
  Color kind(Kind k) => switch (k) {
    Kind.task => task,
    Kind.meeting => meeting,
    Kind.event => event,
    Kind.occasion => occasion,
  };

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

IconData kindIcon(Kind k) => switch (k) {
  Kind.task => Icons.check_circle_outline_rounded,
  Kind.meeting => Icons.groups_outlined,
  Kind.event => Icons.event_outlined,
  Kind.occasion => Icons.cake_outlined,
};

/// Spacing (4-pt grid) and radii.
abstract final class Space {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 20.0, xxl = 24.0, xxxl = 32.0;
}

abstract final class Radii {
  static const chip = 10.0, row = 12.0, card = 16.0, sheet = 24.0;
}
