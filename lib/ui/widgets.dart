/// Shared components (screens.md §4): icon tiles, inset groups, rows, headers, banners, empty states,
/// sheet frame, undo snackbar.
library;

import 'package:flutter/material.dart';
import 'package:reminder_core/reminder_core.dart';

import 'bell.dart';
import 'tokens.dart';

/// Rounded-square tile tinted in a type color with a line icon (DS11).
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color, this.size = 40, this.filled = false});

  factory IconTile.kind(BuildContext context, Kind kind, {double size = 40}) =>
      IconTile(icon: kindIcon(kind), color: AppColors.of(context).kind(kind), size: size);

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
  const InsetGroup({super.key, required this.children, this.indent = 64, this.margin, this.color});

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
              for (var n = 0; n < children.length; n++) ...[
                if (n > 0) Divider(indent: indent),
                children[n],
              ],
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
          Flexible(child: Text(title, style: text.titleMedium?.copyWith(color: danger ? c.danger : null))),
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
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small caption above a settings/form group.
class GroupCaption extends StatelessWidget {
  const GroupCaption(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.l * 2, Space.xl, Space.l, Space.s),
    child: Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.5)),
  );
}

/// The reminder row (screens.md §4): icon tile, title, when, repeat/work/bell/calendar icons,
/// overdue and done styles.
class ReminderRow extends StatelessWidget {
  const ReminderRow({
    super.key,
    required this.reminder,
    required this.when,
    this.overdue = false,
    this.done = false,
    this.onTap,
    this.trailing,
  });

  final Reminder reminder;
  final String when;
  final bool overdue;
  final bool done;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final r = reminder;
    final small = c.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
        child: Opacity(
          opacity: done ? 0.55 : 1,
          child: Row(
            children: [
              IconTile.kind(context, r.kind),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: text.bodyLarge?.copyWith(decoration: done ? TextDecoration.lineThrough : null),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            when,
                            style: text.bodyMedium?.copyWith(color: overdue ? c.danger : null),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (r.rrule != null) ...[
                          const SizedBox(width: Space.xs),
                          Icon(Icons.repeat_rounded, size: 14, color: small),
                        ],
                        if (r.alertPlan.isNotEmpty && !r.isCalendarEvent) ...[
                          const SizedBox(width: Space.xs),
                          Icon(Icons.notifications_none_rounded, size: 14, color: small),
                        ],
                        if (r.isCalendarEvent) ...[
                          const SizedBox(width: Space.xs),
                          Icon(Icons.calendar_today_outlined, size: 13, color: small),
                          if (r.alertPlan.isNotEmpty) Icon(Icons.notifications_none_rounded, size: 14, color: small),
                        ],
                        if (r.context == ReminderContext.work) ...[
                          const SizedBox(width: Space.xs),
                          Icon(Icons.work_outline_rounded, size: 14, color: small),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

enum BannerTone { info, warning }

/// Persistent banners on the home shell (G2–G4, G10).
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.action, this.onAction, this.tone = BannerTone.warning, this.icon});
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
              Icon(icon ?? Icons.info_outline_rounded, color: color, size: 20),
              const SizedBox(width: Space.s),
              Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textPrimary))),
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
  const EmptyState({super.key, required this.title, this.sub, this.compact = false, this.action, this.onAction, this.mood = BellMood.calm});
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
        SizedBox(width: 96, child: Align(alignment: Alignment.centerLeft, child: left)),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center, maxLines: 1),
        ),
        SizedBox(width: 96, child: Align(alignment: Alignment.centerRight, child: right)),
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
                const SizedBox(width: Space.m),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.bodyLarge?.copyWith(color: destructive ? c.danger : null)),
                    if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                  ],
                ),
              ),
              if (value != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: Space.s),
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: text.bodyMedium?.copyWith(color: flagged ? c.warning : null),
                    ),
                  ),
                ),
              if (trailing != null) trailing! else if (onTap != null) ...[
                const SizedBox(width: Space.xs),
                Icon(Icons.chevron_right_rounded, color: c.textSecondary, size: 20),
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
  const SwitchRow({super.key, required this.label, required this.value, required this.onChanged, this.subtitle, this.icon, this.color});
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
    trailing: Switch.adaptive(value: value, onChanged: onChanged),
  );
}

/// Snackbar with Undo (screens.md §4), 5 s (OCC-5, DAT-1).
void showUndoSnack(BuildContext context, String message, {String? undoLabel, VoidCallback? onUndo}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
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
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: expand
            ? FractionallySizedBox(heightFactor: 0.9, child: builder(ctx))
            : SafeArea(top: false, child: builder(ctx)),
      ),
    );
