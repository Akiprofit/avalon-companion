import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/services/feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/secondary_button.dart';
import '../../narration_engine/controllers/voice_packs_controller.dart';
import '../../narration_engine/models/narration_instruction.dart';
import '../../narration_engine/models/voice_pack.dart';
import '../../narration_engine/services/narration_clips.dart';
import '../../narration_engine/services/voice_files.dart';
import '../../narration_engine/services/voice_import.dart';
import '../../narration_engine/services/voice_pack_catalogue.dart';
import 'settings_controller.dart';

/// The narrator voices, and the way to import, rename, hide and delete them.
///
/// A voice is a whole pack — one recording per line — so this lists packs, not
/// files. Every action here is about a label or a folder: no match state, no
/// player, and nothing that can change how a game is scored.
Future<void> showVoicePackPicker(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const VoicePackPickerDialog(),
  );
}

class VoicePackPickerDialog extends ConsumerWidget {
  const VoicePackPickerDialog({super.key, this.showHidden = false});

  /// When true, lists the voices the MC took out of the way.
  final bool showHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(voicePacksProvider);
    final selected = ref.watch(settingsProvider).narratorPackId;
    final list = showHidden ? packs.hidden : packs.visible;

    return AlertDialog(
      title: Text(showHidden ? 'Hidden voices' : 'Narrator voice'),
      contentPadding: const EdgeInsets.symmetric(vertical: Space.md),
      content: SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460),
          child: ListView(
            shrinkWrap: true,
            children: [
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  child: Text(
                    showHidden
                        ? 'No voice is hidden.'
                        : 'No voice is available. The shipped recordings are '
                              'missing from this build, so the phone reads the '
                              'night instead.',
                    style: AppText.caption,
                  ),
                ),
              for (final pack in list)
                _VoicePackRow(
                  pack: pack,
                  selected: pack.id ==
                      (selected ?? VoicePackCatalogue.classicId),
                  showHidden: showHidden,
                ),
              if (!showHidden) ...[
                if (VoiceFiles.supported)
                  ListTile(
                    key: const Key('voice_pack_import'),
                    leading: const Icon(
                      Icons.unarchive_outlined,
                      size: 20,
                      color: AppColors.gold,
                    ),
                    title: const Text('Import a voice…'),
                    subtitle: const Text(
                      'A .zip holding an en/ folder, a fil/ folder, or both.',
                    ),
                    onTap: () => _import(context, ref),
                  ),
                if (packs.hidden.isNotEmpty)
                  ListTile(
                    key: const Key('voice_pack_show_hidden'),
                    leading: const Icon(
                      Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.mutedText,
                    ),
                    title: Text('Hidden voices (${packs.hidden.length})'),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => const VoicePackPickerDialog(
                        showHidden: true,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        SecondaryButton(
          label: 'Done',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _VoicePackRow extends ConsumerWidget {
  const _VoicePackRow({
    required this.pack,
    required this.selected,
    required this.showHidden,
  });

  final VoicePack pack;
  final bool selected;
  final bool showHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: Key('voice_pack_${pack.id}'),
      leading: Icon(
        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        size: 20,
        color: selected ? AppColors.gold : AppColors.mutedText,
      ),
      title: Text(pack.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(coverageLabel(pack)),
      onTap: () {
        if (showHidden) {
          ref.read(voicePacksProvider.notifier).setHidden(pack.id, false);
        }
        ref.read(settingsProvider.notifier).setVoicePack(pack.id);
        ref.read(feedbackProvider).tap();
        Navigator.of(context).pop();
      },
      trailing: PopupMenuButton<String>(
        key: Key('voice_pack_menu_${pack.id}'),
        tooltip: 'Voice options',
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: AppColors.mutedText,
        ),
        onSelected: (action) => switch (action) {
          'rename' => _rename(context, ref),
          'hide' => _setHidden(context, ref, true),
          'restore' => _setHidden(context, ref, false),
          'delete' => _delete(context, ref),
          _ => null,
        },
        itemBuilder: (_) => [
          if (showHidden)
            const PopupMenuItem(value: 'restore', child: Text('Restore'))
          else ...[
            const PopupMenuItem(value: 'rename', child: Text('Rename…')),
            if (pack.builtIn)
              const PopupMenuItem(value: 'hide', child: Text('Hide'))
            else
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ],
      ),
    );
  }

  /// Bundled voices live inside the installed app, so "remove" can only mean
  /// "take it out of the list". Imported ones are deleted for real.
  Future<void> _setHidden(
    BuildContext context,
    WidgetRef ref,
    bool hidden,
  ) async {
    await ref.read(voicePacksProvider.notifier).setHidden(pack.id, hidden);
    if (hidden && _isActive(ref)) {
      ref.read(settingsProvider.notifier).setVoicePack(null);
    }
    ref.read(feedbackProvider).tap();
    if (context.mounted) Navigator.of(context).maybePop();
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await _askName(context, title: 'Rename voice', value: pack.name);
    if (name == null || !context.mounted) return;
    await ref.read(voicePacksProvider.notifier).rename(pack.id, name);
    ref.read(feedbackProvider).tap();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      ref,
      title: 'Delete ${pack.name}?',
      message:
          'Its recordings are removed from this phone. The rest of the app, '
          'and every saved match, is untouched.',
      confirmLabel: 'Delete the voice',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(voicePacksProvider.notifier).delete(pack);
    if (_isActive(ref)) {
      ref.read(settingsProvider.notifier).setVoicePack(null);
    }
    if (context.mounted) Navigator.of(context).maybePop();
  }

  bool _isActive(WidgetRef ref) =>
      ref.read(settingsProvider).narratorPackId == pack.id;
}

/// Picks the zip, asks for the name, and installs the voice.
Future<void> _import(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(voicePacksProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);

  final zipPath = await controller.pickZip();
  if (zipPath == null || !context.mounted) return;

  final name = await _askName(
    context,
    title: 'Name this voice',
    value: controller.suggestName(zipPath),
    hint: 'Voice of Dahlia',
  );
  if (name == null || !context.mounted) return;

  try {
    final pack = await controller.importZip(zipPath: zipPath, name: name);
    ref.read(settingsProvider.notifier).setVoicePack(pack.id);
    ref.read(feedbackProvider).tap();
    messenger.showSnackBar(
      SnackBar(content: Text('${pack.name} is now the narrator.')),
    );
    if (context.mounted) Navigator.of(context).maybePop();
  } on VoiceImportException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  }
}

Future<String?> _askName(
  BuildContext context, {
  required String title,
  required String value,
  String? hint,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(title: title, value: value, hint: hint),
  );
}

/// The name field, owning its controller so the exit animation cannot outlive
/// it.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.value, this.hint});

  final String title;
  final String value;
  final String? hint;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _field = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_field.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: TextField(
          key: const Key('voice_pack_name_field'),
          controller: _field,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: widget.hint ?? 'Voice of Dahlia',
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        SecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          key: const Key('voice_pack_name_save'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// "English 14/14 · Filipino 0/14" — how much of the night a voice covers.
String coverageLabel(VoicePack pack) {
  final total = NarrationClips.ids.length;
  String part(NarrationLanguage language) {
    final have = pack.clipCount(language);
    if (have == 0) return 'not recorded';
    return '$have/${math.max(total, have)}';
  }

  return 'English ${part(NarrationLanguage.english)} · '
      'Filipino ${part(NarrationLanguage.filipino)}';
}

/// The settings row that names the voice in use.
///
/// Reads the bundle once when settings open, which is the only place the list
/// has to be current: a voice is chosen between matches, not during one.
class VoicePackSummaryTile extends ConsumerStatefulWidget {
  const VoicePackSummaryTile({super.key});

  @override
  ConsumerState<VoicePackSummaryTile> createState() =>
      _VoicePackSummaryTileState();
}

class _VoicePackSummaryTileState extends ConsumerState<VoicePackSummaryTile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(voicePacksProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(voicePacksProvider);
    final selected = ref.watch(settingsProvider).narratorPackId;
    final active = packs.active(selected);

    return InkWell(
      key: const Key('settings_voice_pack'),
      borderRadius: BorderRadius.circular(Radii.card),
      onTap: () => showVoicePackPicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Narrator voice', style: AppText.bodyStrong),
                  const SizedBox(height: 2),
                  Text(coverageLabel(active), style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            Flexible(
              child: Text(
                active.name,
                style: AppText.bodyStrong.copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
