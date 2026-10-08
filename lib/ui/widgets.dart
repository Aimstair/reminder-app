/// Shared components (screens.md §4): icon tiles, inset groups, rows, headers, banners, empty states,
/// sheet frame, undo snackbar.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reminder_core/reminder_core.dart';

import '../l10n/gen/app_localizations.dart';
import 'bell.dart';
import 'motion.dart';
import 'tokens.dart';
import 'icons.dart';

/// Rounded-square tile tinted in a type color with a line icon (DS11).
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color, this.size = 40, this.filled = false});

  factory IconTile.kind(BuildContext context, Kind kind, {double size = 40}) =>
      IconTile(icon: kindIcon(kind), color: AppColors.of(context).kind(kind), size: size);

  /// The item's own icon (bill, bag, phone…) in its type color — rows and cards (DS11).
  factory IconTile.item(BuildContext context, Reminder r, {double size = 40}) =>
      IconTile(icon: glyphIcon(glyphFor(r)), color: AppColors.of(context).kind(r.kind), size: size);

  final IconData icon;
  final Color color;
  final double size;

  /// Solid tile with a white glyph (settings / form rows).
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: filled ? color : color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(size * 0.26),
    ),
    child: Icon(icon, color: filled ? Colors.white : color, size: size * 0.55),
  );
}

/// Inset grouped list (rounded card, hairline separators) on the grouped background.
class InsetGroup extends StatelessWidget {
  const InsetGroup({super.key, required this.children, this.indent = 56, this.margin, this.color});

  final List<Widget> children;
  final double indent;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: Space.l),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.row),
        child: Material(
          color: color ?? c.surface,
          child: Column(
            children: [
              for (var n = 0; n < children.length; n++) ...[if (n > 0) Divider(indent: indent), children[n]],
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.count, this.danger = false, this.trailing});
  final String title;
  final int? count;
  final bool danger;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l + Space.xs, Space.l, Space.l, Space.s),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(color: danger ? c.danger : null),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: Space.s),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: (danger ? c.danger : c.textSecondary).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child: Text('$count', style: text.labelSmall?.copyWith(color: danger ? c.danger : null)),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small caption above a settings/form group.
class GroupCaption extends StatelessWidget {
  const GroupCaption(this.text, {super.key, this.inset = Space.l * 2});
  final String text;

  /// Left edge: 32 on a page (16 margin + 16 into the card); 16 inside an already padded sheet.
  final double inset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(inset, Space.xl, Space.l, Space.s),
    child: Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 0.3),
    ),
  );
}

/// The reminder row (screens.md §4, mockup 02-schedule-home): round checkbox in the type color,
/// title, a subline (clock + when, repeat, nag and context chips), and the item's icon tile.
/// Overdue = red subline; done = filled checkbox, faded, struck through.
class ReminderRow extends StatelessWidget {
  const ReminderRow({
    super.key,
    required this.reminder,
    required this.when,
    this.overdue = false,
    this.done = false,
    this.nagLabel,
    this.onTap,
    this.onCheck,
    this.trailing,
  });

  final Reminder reminder;
  final String when;
  final bool overdue;
  final bool done;

  /// "Every 2h" when the item nags (ALR-9); null hides the chip.
  final String? nagLabel;
  final VoidCallback? onTap;

  /// Tapping the checkbox; null = not completable here (meetings, events, calendar items).
  final VoidCallback? onCheck;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final r = reminder;
    final type = c.kind(r.kind);
    final sub = overdue ? c.danger : c.textSecondary;
    final subStyle = text.bodyMedium?.copyWith(color: sub);
    return InkWell(
      onTap: onTap,
      child: Container(
        // Fixed height: every row lines up, whatever the title length (one line, then …).
        height: rowHeight,
        // CheckCircle brings its own 8dp touch padding, so both edges sit 12dp in.
        padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.m, 0),
        child: AnimatedOpacity(
          duration: Motion.standard,
          opacity: done ? 0.5 : 1,
          child: Row(
            children: [
              CheckCircle(color: type, checked: done, onTap: onCheck),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(r.isCalendarEvent ? AppIcons.calendar : AppIcons.clockSmall, size: 14, color: sub),
                        const SizedBox(width: Space.xs),
                        Flexible(
                          child: Text(when, style: subStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (r.rrule != null) ...[
                          const SizedBox(width: Space.xs),
                          Icon(AppIcons.repeat, size: 14, color: sub),
                        ],
                        if (nagLabel case final nag?) ...[
                          const SizedBox(width: Space.xs),
                          Flexible(child: MiniChip(nag, color: overdue ? c.danger : c.textSecondary)),
                        ],
                        if (r.context == ReminderContext.work) ...[
                          const SizedBox(width: Space.xs),
                          Flexible(child: MiniChip(l10n.ctxWork, color: c.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.m),
              trailing ?? IconTile.item(context, r),
            ],
          ),
        ),
      ),
    );
  }

  static const rowHeight = 64.0;

  /// Where the title starts (4 + 40 check + 4): separators line up with it, iOS-style.
  static const dividerIndent = 48.0;
}

/// Round checkbox in a type color (mockup rows). Fills and pops with a tick when [checked].
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.color, this.checked = false, this.onTap, this.padded = true});
  final Color color;
  final bool checked;
  final VoidCallback? onTap;

  /// 8dp around the 24dp circle (a 40dp touch target), so rows line up whether or not it's tappable.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final circle = TweenAnimationBuilder<double>(
      tween: Tween(end: checked ? 1 : 0),
      duration: reduceMotion(context) ? Duration.zero : Motion.standard,
      curve: Curves.easeOutBack,
      builder: (_, v, _) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(Colors.transparent, color, v.clamp(0, 1)),
          border: Border.all(color: color, width: 2),
        ),
        child: v <= 0.01
            ? null
            : Transform.scale(
                scale: v,
                child: const Icon(AppIcons.check, size: 15, color: Colors.white),
              ),
      ),
    );
    if (onTap == null) return padded ? Padding(padding: const EdgeInsets.all(Space.s), child: circle) : circle;
    return Semantics(
      button: true,
      label: l10n.actionDone,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(Space.s), child: circle),
      ),
    );
  }
}

/// Small rounded chip inside a row subline ("Every 2h", "Work").
class MiniChip extends StatelessWidget {
  const MiniChip(this.label, {super.key, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

enum BannerTone { info, warning }

/// iOS-style segmented control (mockup 03): gray track, a white thumb that slides to the selected
/// item, optional colored dot per item. Fixed 36dp height; labels truncate.
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({super.key, required this.items, required this.selected, required this.onChanged});
  final List<({T value, String label, Color? dot})> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final index = items.indexWhere((i) => i.value == selected);
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.separator.withValues(alpha: dark ? 0.35 : 0.18),
        borderRadius: BorderRadius.circular(9),
      ),
      child: SlidingCells(
        count: items.length,
        selected: index,
        highlight: DecoratedBox(
          decoration: BoxDecoration(
            color: dark ? c.surfaceElevated : c.surface,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 1, offset: const Offset(0, 0.5)),
            ],
          ),
        ),
        cell: (context, n) {
          final i = items[n];
          final on = n == index;
          return Semantics(
            button: true,
            selected: on,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (i.dot != null) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: i.dot, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: Motion.micro,
                        style: text.titleSmall!.copyWith(
                          fontSize: 14,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                          color: on ? c.textPrimary : c.textPrimary.withValues(alpha: 0.75),
                        ),
                        child: Text(i.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Persistent banners on the home shell (G2–G4, G10).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.text,
    this.action,
    this.onAction,
    this.tone = BannerTone.warning,
    this.icon,
  });
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final BannerTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = tone == BannerTone.warning ? c.warning : c.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.row),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.xs, Space.s),
          child: Row(
            children: [
              Icon(icon ?? AppIcons.info, color: color, size: 20),
              const SizedBox(width: Space.s),
              Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textPrimary)),
              ),
              if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state with the bell (G1, G6, G7, Completed).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.sub,
    this.compact = false,
    this.action,
    this.onAction,
    this.mood = BellMood.calm,
  });
  final String title;
  final String? sub;
  final bool compact;
  final String? action;
  final VoidCallback? onAction;
  final BellMood mood;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Space.xxxl, vertical: compact ? Space.l : Space.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Bell(size: compact ? 56 : 112, mood: mood),
          const SizedBox(height: Space.m),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (sub != null) ...[
            const SizedBox(height: Space.xs),
            Text(sub!, style: text.bodyMedium, textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: Space.m),
            FilledButton.tonal(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

/// iOS-style sheet bar: [left] · title · [right].
class SheetBar extends StatelessWidget {
  const SheetBar({super.key, required this.title, this.left, this.right});
  final String title;
  final Widget? left;
  final Widget? right;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Row(
      children: [
        SizedBox(
          width: 96,
          child: Align(alignment: Alignment.centerLeft, child: left),
        ),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center, maxLines: 1),
        ),
        SizedBox(
          width: 96,
          child: Align(alignment: Alignment.centerRight, child: right),
        ),
      ],
    ),
  );
}

/// A tappable form row: colored icon tile, label, value, chevron (iOS form, DS11).
class FormRow extends StatelessWidget {
  const FormRow({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.color,
    this.onTap,
    this.flagged = false,
    this.trailing,
    this.subtitle,
    this.destructive = false,
  });
  final String label;
  final String? value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool flagged;
  final Widget? trailing;
  final String? subtitle;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s + 2),
          child: Row(
            children: [
              if (icon != null) ...[
                IconTile(icon: icon!, color: color ?? c.accent, size: 30, filled: true),
                const SizedBox(width: 14), // label starts at 12 + 30 + 14 = 56 = InsetGroup indent
              ],
              // Label fills the left; the value sits against the chevron, capped at half the screen, so
              // every row's chevron lands on the same edge and long values truncate.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(color: destructive ? c.danger : null),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (value != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.5),
                  child: Padding(
                    padding: const EdgeInsets.only(left: Space.s),
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: text.bodyLarge?.copyWith(color: flagged ? c.warning : c.textSecondary),
                    ),
                  ),
                ),
              if (trailing != null)
                trailing!
              else if (onTap != null) ...[
                const SizedBox(width: Space.xs),
                Icon(AppIcons.next, color: c.textSecondary.withValues(alpha: 0.6), size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Switch row for forms and settings.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.color,
  });
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => FormRow(
    label: label,
    subtitle: subtitle,
    icon: icon,
    color: color,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    trailing: CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: AppColors.of(context).success),
  );
}

/// Snackbar with Undo (screens.md §4), 5 s (OCC-5, DAT-1).
void showUndoSnack(BuildContext context, String message, {String? undoLabel, VoidCallback? onUndo}) =>
    showUndoSnackOn(ScaffoldMessenger.of(context), message, undoLabel: undoLabel, onUndo: onUndo);

/// [showUndoSnack] on a messenger captured before an await (the caller may be gone by then).
void showUndoSnackOn(ScaffoldMessengerState messenger, String message, {String? undoLabel, VoidCallback? onUndo}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5), // OCC-5
        persist: false, // Flutter keeps snackbars with an action until dismissed otherwise
        action: onUndo == null || undoLabel == null ? null : SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
}

/// Bottom sheet with rounded top, safe area and keyboard padding.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder, {bool expand = false}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: expand
            ? FractionallySizedBox(
                heightFactor: 0.9,
                child: Column(
                  children: [
                    const SheetGrabber(),
                    Expanded(child: builder(ctx)),
                  ],
                ),
              )
            : SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SheetGrabber(),
                    Flexible(child: builder(ctx)),
                  ],
                ),
              ),
      ),
    );

/// iOS sheet grabber: a 36 × 5 pill, 6dp from the top edge (14dp tall in all).
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 3),
    child: Container(
      width: 36,
      height: 5,
      decoration: BoxDecoration(color: AppColors.of(context).separator, borderRadius: BorderRadius.circular(3)),
    ),
  );
}
