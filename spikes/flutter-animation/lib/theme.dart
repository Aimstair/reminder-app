// Tokens from docs/design-direction.md §3 (spike copy — same values as the RN spike)
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

enum Kind { task, meeting, event, occasion }

class AppColors {
  final Color bgGrouped, surface, surfaceElevated, textPrimary, textSecondary, separator, accent, danger, success, warning;
  final Map<Kind, Color> kind;
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
    required this.kind,
  });

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
    kind: {
      Kind.task: Color(0xFF007AFF),
      Kind.meeting: Color(0xFF5856D6),
      Kind.event: Color(0xFFFF9500),
      Kind.occasion: Color(0xFFFF2D55),
    },
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
    kind: {
      Kind.task: Color(0xFF0A84FF),
      Kind.meeting: Color(0xFF5E5CE6),
      Kind.event: Color(0xFFFF9F0A),
      Kind.occasion: Color(0xFFFF375F),
    },
  );

  static AppColors of(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark ? dark : light;
}

class AppText {
  static const _f = 'Inter';
  static const largeTitle = TextStyle(fontFamily: _f, fontSize: 34, fontWeight: FontWeight.w700);
  static const title2 = TextStyle(fontFamily: _f, fontSize: 22, fontWeight: FontWeight.w700);
  static const headline = TextStyle(fontFamily: _f, fontSize: 17, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontFamily: _f, fontSize: 17, fontWeight: FontWeight.w400);
  static const subheadline = TextStyle(fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w400);
  static const footnote = TextStyle(fontFamily: _f, fontSize: 13, fontWeight: FontWeight.w400);
  static const caption = TextStyle(fontFamily: _f, fontSize: 12, fontWeight: FontWeight.w500);
}

class Space {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 20.0, xxl = 24.0, xxxl = 32.0;
}

class Radii {
  static const chip = 10.0, row = 12.0, card = 16.0, sheet = 24.0;
}

/// Spring presets matching the RN spike (Things-like: soft, settles quickly)
class Springs {
  static const snappy = SpringDescription(mass: 0.6, stiffness: 260, damping: 14);
  static const soft = SpringDescription(mass: 0.8, stiffness: 160, damping: 18);
}

/// A Curve driven by a real spring simulation, for implicit animations and AnimatedList.
/// [duration] is the physics time the curve covers; pick it so the spring has settled.
class SpringCurve extends Curve {
  final SpringDescription spring;
  final double seconds;
  const SpringCurve(this.spring, {this.seconds = 0.6});

  @override
  double transformInternal(double t) => SpringSimulation(spring, 0, 1, 0).x(t * seconds);
}
