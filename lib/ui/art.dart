/// Illustration pieces (DS15): iOS-style gradient glyph badges, page heroes with a soft glow and
/// drifting accents, choice rows with icons, and the small screen previews used by visual pickers.
/// All drawn with widgets (no image assets), tinted from the tokens, so they follow light/dark.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

/// Rounded-square badge with a top-lit gradient, a white glyph and a colored shadow
/// (the look of an iOS Settings / app icon). Fixed size.
class GlyphBadge extends StatelessWidget {
  const GlyphBadge({super.key, required this.icon, required this.color, this.size = 72});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final top = Color.lerp(color, Colors.white, 0.28)!;
    final bottom = Color.lerp(color, Colors.black, 0.08)!;
    final r = BorderRadius.circular(size * 0.27);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: size * 0.28, offset: Offset(0, size * 0.1)),
          ],
        ),
        child: Stack(
          children: [
            // Glossy top sheen.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: size * 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.27)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(icon, color: Colors.white, size: size * 0.52),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header illustration for a page: a floating [GlyphBadge] in a soft glow with a few drifting
/// accent shapes, and an optional centered caption under it (like iOS Settings detail pages).
class PageHero extends StatelessWidget {
  const PageHero({super.key, required this.icon, required this.color, this.title, this.caption, this.size = 76});
  final IconData icon;
  final Color color;
  final String? title;
  final String? caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FadeSlideIn(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xxxl, Space.s, Space.xxxl, Space.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: size + 48,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _Glow(color: color, size: size * 2.1),
                  ..._accents(color, size),
                  Floating(
                    amplitude: 4,
                    child: GlyphBadge(icon: icon, color: color, size: size),
                  ),
                ],
              ),
            ),
            if (title != null) ...[
              Text(
                title!,
                style: text.titleLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Space.xs),
            ],
            if (caption != null)
              Text(
                caption!,
                style: text.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  /// Small circles and a sparkle around the badge, each drifting on its own phase.
  static List<Widget> _accents(Color color, double size) {
    final d = size * 0.95;
    final specs = <(double angle, double r, double phase)>[
      (-2.5, 7, 0.0),
      (-0.55, 5, 0.35),
      (0.5, 9, 0.7),
      (2.55, 4, 0.2),
    ];
    return [
      for (final (a, r, phase) in specs)
        Transform.translate(
          offset: Offset(math.cos(a) * d, math.sin(a) * d * 0.62),
          child: Floating(
            amplitude: 5,
            phase: phase,
            period: Duration(milliseconds: 2400 + (phase * 1600).round()),
            child: Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.28 + phase * 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      Transform.translate(
        offset: Offset(d * 0.78, -d * 0.48),
        child: Floating(
          amplitude: 3,
          phase: 0.5,
          child: Icon(
            const IconData(0xe6a2, fontFamily: 'PhosphorFill'),
            size: 16,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ),
    ];
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size * 0.75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)]),
      ),
    ),
  );
}

/// One choice in a single-select list: colored icon tile, label, optional subtitle, and a check
/// that pops in when selected. Fixed 52 dp height (60 with a subtitle).
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
    this.subtitle,
    this.trailing,
  });
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: subtitle == null ? 52 : 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.m),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: color ?? c.accent, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 14), // text at 56, like FormRow
                ] else
                  const SizedBox(width: Space.xs),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: text.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitle != null)
                        Text(subtitle!, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                ?trailing,
                SizedBox(
                  width: 28,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: reduceMotion(context) ? Duration.zero : Motion.standard,
                    curve: selected ? Curves.easeOutBack : Curves.easeIn,
                    child: Icon(const IconData(0xe182, fontFamily: 'Phosphor'), color: c.accent, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of picture cards to choose from (theme, start view): a fixed-size preview, its label,
/// and an iOS-style check circle under it. The selected card's ring animates in.
class PreviewChoices<T> extends StatelessWidget {
  const PreviewChoices({super.key, required this.items, required this.selected, required this.onChanged});
  final List<({T value, String label, Widget preview})> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final fast = reduceMotion(context) ? Duration.zero : Motion.standard;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Space.l),
      padding: const EdgeInsets.fromLTRB(Space.s, Space.l, Space.s, Space.m),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.row)),
      child: Row(
        children: [
          for (final i in items)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(i.value),
                child: Semantics(
                  button: true,
                  selected: i.value == selected,
                  label: i.label,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: fast,
                        curve: Motion.spring,
                        width: 64,
                        height: 112,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: i.value == selected ? c.accent : c.separator.withValues(alpha: 0.5),
                            width: i.value == selected ? 2.5 : 1,
                          ),
                        ),
                        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: i.preview),
                      ),
                      const SizedBox(height: Space.s),
                      SizedBox(
                        height: 20,
                        child: Text(
                          i.label,
                          style: text.bodyMedium?.copyWith(color: c.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      AnimatedContainer(
                        duration: fast,
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i.value == selected ? c.accent : Colors.transparent,
                          border: Border.all(color: i.value == selected ? c.accent : c.separator, width: 1.5),
                        ),
                        child: AnimatedScale(
                          scale: i.value == selected ? 1 : 0,
                          duration: fast,
                          curve: Curves.easeOutBack,
                          child: const Icon(IconData(0xe182, fontFamily: 'Phosphor'), size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A tiny phone screen: status bar, a header bar and a few rows in [bg]/[fg] (theme previews).
/// [split] draws the left half light and the right half dark (System).
class MiniScreen extends StatelessWidget {
  const MiniScreen.light({super.key}) : dark = false, split = false;
  const MiniScreen.dark({super.key}) : dark = true, split = false;
  const MiniScreen.system({super.key}) : dark = false, split = true;
  final bool dark;
  final bool split;

  @override
  Widget build(BuildContext context) {
    if (!split) return _screen(dark ? AppColors.dark : AppColors.light);
    return Stack(
      fit: StackFit.expand,
      children: [
        _screen(AppColors.light),
        ClipRect(clipper: const _RightHalf(), child: _screen(AppColors.dark)),
      ],
    );
  }

  static Widget _screen(AppColors c) => ColoredBox(
    color: c.bgGrouped,
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(c.textPrimary, 18, 5),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(5)),
            child: Column(
              children: [
                for (final k in [c.task, c.meeting, c.occasion]) ...[
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: k, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 3),
                      Expanded(child: _bar(c.textSecondary, double.infinity, 3)),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 22,
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(5)),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    ),
  );

  static Widget _bar(Color color, double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
  );
}

class _RightHalf extends CustomClipper<Rect> {
  const _RightHalf();
  @override
  Rect getClip(Size size) => Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

/// Tiny previews of the three home views (start-in picker): list rows, a day timeline, a month grid.
class MiniView extends StatelessWidget {
  const MiniView.schedule({super.key}) : kind = 0;
  const MiniView.day({super.key}) : kind = 1;
  const MiniView.month({super.key}) : kind = 2;
  const MiniView.last({super.key}) : kind = 3;
  final int kind;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget bar(double w, double h, Color col) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(2)),
    );
    final body = switch (kind) {
      0 => Column(
        children: [
          for (final k in [c.task, c.meeting, c.event, c.occasion]) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: k, shape: BoxShape.circle),
                ),
                const SizedBox(width: 3),
                Expanded(child: bar(double.infinity, 3, c.textSecondary.withValues(alpha: 0.5))),
              ],
            ),
            const SizedBox(height: 7),
          ],
        ],
      ),
      1 => Column(
        children: [
          for (var i = 0; i < 6; i++)
            SizedBox(
              height: 13,
              child: Row(
                children: [
                  bar(6, 2, c.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: i == 1 || i == 3
                        ? Container(
                            height: 11,
                            decoration: BoxDecoration(
                              color: (i == 1 ? c.meeting : c.event).withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                              border: Border(left: BorderSide(color: i == 1 ? c.meeting : c.event, width: 2)),
                            ),
                          )
                        : Container(height: 0.5, color: c.separator),
                  ),
                ],
              ),
            ),
        ],
      ),
      2 => GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          for (var i = 0; i < 20; i++)
            Container(
              decoration: BoxDecoration(
                color: i == 9 ? c.accent : c.textSecondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      _ => Center(
        child: Icon(const IconData(0xe1a0, fontFamily: 'Phosphor'), size: 26, color: c.accent), // clockCounterClockwise
      ),
    };
    return ColoredBox(
      color: c.bgGrouped,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(22, 5, c.textPrimary.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
