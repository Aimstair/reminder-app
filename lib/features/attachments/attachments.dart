/// Notes, links and files on a reminder (ATT-1…ATT-6): the editable group used by the capture sheet
/// (S-20) and the editor (S-22), the read-only list on the detail page (S-30), and notes text with
/// tappable links (ATT-5). Files are copied into app storage by the platform layer (ATT-3).
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/icons.dart';
import '../../ui/motion.dart';
import '../../ui/tokens.dart';

/// Tile icon and color by attachment type.
(IconData, Color) attachmentLook(AppColors c, Attachment a) {
  if (a.kind == AttachmentKind.link) return (AppIcons.link, c.accent);
  final mime = a.mime ?? '';
  final ext = a.name.contains('.') ? a.name.split('.').last.toLowerCase() : '';
  if (mime == 'application/pdf' || ext == 'pdf') return (AppIcons.filePdf, c.danger);
  if (mime.startsWith('image/')) return (AppIcons.fileImage, c.success);
  if (mime.startsWith('video/')) return (AppIcons.fileVideo, c.purple);
  if (mime.startsWith('audio/')) return (AppIcons.fileAudio, c.occasion);
  if (mime.contains('zip') || ext == 'zip') return (AppIcons.fileZip, c.textSecondary);
  if (mime.contains('sheet') || mime.contains('excel') || ['xls', 'xlsx', 'csv'].contains(ext)) {
    return (AppIcons.fileSheet, c.success);
  }
  if (mime.contains('presentation') || ['ppt', 'pptx', 'key'].contains(ext)) return (AppIcons.fileSlides, c.event);
  if (mime.contains('word') || mime.startsWith('text/') || ['doc', 'docx', 'txt', 'rtf'].contains(ext)) {
    return (AppIcons.fileDoc, c.meeting);
  }
  return (AppIcons.file, c.textSecondary);
}

/// "240 KB" / "1.2 MB".
String fileSizeText(AppLocalizations l10n, int bytes) {
  if (bytes < 1024 * 1024) return l10n.sizeKb('${(bytes / 1024).ceil()}');
  final mb = bytes / (1024 * 1024);
  return l10n.sizeMb(mb >= 10 ? mb.round().toString() : mb.toStringAsFixed(1));
}

/// Links: the address without "https://" and "www." (so an untitled link doesn't repeat its
/// name); files: the size.
String attachmentSubtitle(AppLocalizations l10n, Attachment a) => a.kind == AttachmentKind.link
    ? a.uri.replaceFirst(RegExp(r'^https?://(www\.)?'), '')
    : (a.size == null ? '' : fileSizeText(l10n, a.size!));

/// ATT-4: links open in the browser (or mail / phone app); files open in an app that can show them.
Future<void> openAttachment(BuildContext context, WidgetRef ref, Attachment a) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = a.kind == AttachmentKind.link
        ? await launchUrl(Uri.parse(a.uri), mode: LaunchMode.externalApplication)
        : await ref.read(servicesProvider).platform?.openAttachment(a) ?? false;
  } catch (_) {}
  if (!ok) {
    messenger.showSnackBar(
      SnackBar(content: Text(a.kind == AttachmentKind.link ? l10n.errOpenLink : l10n.errNoAppForFile)),
    );
  }
}

/// ATT-6: remove stored copies of files that were never saved or were taken off a reminder.
Future<void> discardFiles(WidgetRef ref, Iterable<Attachment> files) async {
  final p = ref.read(servicesProvider).platform;
  for (final a in files) {
    if (a.kind == AttachmentKind.file) {
      try {
        await p?.deleteAttachment(a);
      } catch (_) {}
    }
  }
}

/// ATT-2: the Add link dialog. Pre-fills from the clipboard when it holds a link.
Future<Attachment?> askForLink(BuildContext context) async {
  final clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
  if (!context.mounted) return null;
  return showDialog<Attachment>(
    context: context,
    builder: (_) => _LinkDialog(initial: isValidUrl(clip) ? clip : ''),
  );
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.initial});
  final String initial;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final _url = TextEditingController(text: widget.initial);
  final _name = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  void _add() {
    if (!isValidUrl(_url.text)) return setState(() => _showError = true);
    Navigator.pop(context, Attachment.link(_url.text, name: _name.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    InputDecoration deco(String label, {String? hint, String? error}) => InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      errorMaxLines: 2,
      filled: true,
      fillColor: c.bgGrouped,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.chip), borderSide: BorderSide.none),
    );
    return AlertDialog(
      title: Text(l10n.linkDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            autofocus: widget.initial.isEmpty,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
            decoration: deco(
              l10n.linkFieldUrl,
              hint: l10n.linkFieldUrlHint,
              error: _showError ? l10n.errBadLink : null,
            ),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: deco(l10n.linkFieldName),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
        TextButton(onPressed: _add, child: Text(l10n.actionAdd)),
      ],
    );
  }
}

/// ATT-3: pick a file; shows why when it can't be added. Null if cancelled.
Future<Attachment?> pickFileAttachment(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final p = ref.read(servicesProvider).platform;
  if (p == null) return null;
  try {
    return await p.pickAttachment();
  } on PlatformException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.code == 'too_large' ? l10n.errFileTooLarge : l10n.errAttach)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.errAttach)));
  }
  return null;
}

/// One link or file: type tile, name, site or size; fixed 60 dp. [onRemove] shows a remove button,
/// otherwise an "opens elsewhere" glyph.
class AttachmentRow extends ConsumerWidget {
  const AttachmentRow({super.key, required this.attachment, this.onRemove});
  final Attachment attachment;
  final VoidCallback? onRemove;

  static const height = 60.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final (icon, color) = attachmentLook(c, attachment);
    final sub = attachmentSubtitle(l10n, attachment);
    return InkWell(
      onTap: () => openAttachment(context, ref, attachment),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.only(left: Space.m, right: Space.xs),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(attachment.name, style: text.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (sub.isNotEmpty) Text(sub, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: l10n.actionRemove,
                  onPressed: onRemove,
                  icon: Icon(AppIcons.remove, color: c.danger, size: 22),
                )
              else
                SizedBox(width: 44, child: Icon(AppIcons.openExternal, size: 18, color: c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Editable "Notes, links & files" group (S-20 capture, S-22 editor). [notes] shows a notes field
/// when [notesOpen]; otherwise an "Add note" row opens it. Rows animate in and out.
class AttachmentsEditor extends ConsumerWidget {
  const AttachmentsEditor({
    super.key,
    required this.attachments,
    required this.onChanged,
    this.notes,
    this.notesOpen = true,
    this.onOpenNotes,
  });
  final List<Attachment> attachments;
  final ValueChanged<List<Attachment>> onChanged;
  final TextEditingController? notes;
  final bool notesOpen;
  final VoidCallback? onOpenNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    Widget addRow(IconData icon, Color color, String label, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.m),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: text.bodyLarge?.copyWith(color: c.accent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(AppIcons.add, size: 18, color: c.accent),
            ],
          ),
        ),
      ),
    );

    final rows = <Widget>[
      if (notes != null && notesOpen)
        TextField(
          key: const ValueKey('notes'),
          controller: notes,
          autofocus: onOpenNotes != null && notes!.text.isEmpty,
          minLines: 2,
          maxLines: 8,
          style: text.bodyLarge,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.fieldNotes,
            border: InputBorder.none,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: Space.m, right: Space.m),
              child: Icon(AppIcons.notes, color: c.textSecondary, size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 24),
            contentPadding: const EdgeInsets.fromLTRB(0, Space.m + 2, Space.l, Space.m + 2),
          ),
        ),
      for (final a in attachments)
        FadeSlideIn(
          key: ValueKey(a),
          offset: 8,
          child: AttachmentRow(attachment: a, onRemove: () => onChanged([...attachments]..remove(a))),
        ),
      if (notes != null && !notesOpen) addRow(AppIcons.notes, c.warning, l10n.actionAddNote, onOpenNotes ?? () {}),
      addRow(AppIcons.link, c.accent, l10n.actionAddLink, () async {
        final a = await askForLink(context);
        if (a != null && !attachments.contains(a)) onChanged([...attachments, a]);
      }),
      addRow(AppIcons.attach, c.purple, l10n.actionAddFile, () async {
        final a = await pickFileAttachment(context, ref);
        if (a != null) onChanged([...attachments, a]);
      }),
    ];
    return AnimatedSize(
      duration: reduceMotion(context) ? Duration.zero : Motion.standard,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.row),
        child: Material(
          color: c.surface,
          child: Column(
            children: [
              for (var n = 0; n < rows.length; n++) ...[if (n > 0) const Divider(indent: 56), rows[n]],
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only links and files on the detail page; tapping one opens it.
class AttachmentList extends StatelessWidget {
  const AttachmentList({super.key, required this.attachments});
  final List<Attachment> attachments;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.card),
      child: Material(
        color: c.surface,
        child: Column(
          children: [
            for (var n = 0; n < attachments.length; n++) ...[
              if (n > 0) const Divider(indent: 56),
              AttachmentRow(attachment: attachments[n]),
            ],
          ],
        ),
      ),
    );
  }
}

/// ATT-5: notes with web links underlined and tappable; the rest stays selectable text.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final spans = <InlineSpan>[];
    var at = 0;
    for (final l in findLinks(widget.text)) {
      if (l.start > at) spans.add(TextSpan(text: widget.text.substring(at, l.start)));
      final r = TapGestureRecognizer()
        ..onTap = () async {
          var ok = false;
          try {
            ok = await launchUrl(Uri.parse(l.url), mode: LaunchMode.externalApplication);
          } catch (_) {}
          if (!ok) messenger.showSnackBar(SnackBar(content: Text(l10n.errOpenLink)));
        };
      _recognizers.add(r);
      spans.add(
        TextSpan(
          text: widget.text.substring(l.start, l.end),
          style: TextStyle(color: c.accent, decoration: TextDecoration.underline, decorationColor: c.accent),
          recognizer: r,
        ),
      );
      at = l.end;
    }
    if (at < widget.text.length) spans.add(TextSpan(text: widget.text.substring(at)));
    return SelectableText.rich(TextSpan(style: widget.style, children: spans));
  }
}
