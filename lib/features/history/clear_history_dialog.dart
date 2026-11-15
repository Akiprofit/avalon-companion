import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/counter_stepper.dart';
import '../../core/widgets/danger_button.dart';
import '../../core/widgets/secondary_button.dart';

/// What the MC chose in [showClearHistoryDialog].
class ClearHistoryChoice {
  /// The [count] oldest stored matches.
  const ClearHistoryChoice.oldest(int this.count);

  /// Every stored match.
  const ClearHistoryChoice.everything() : count = null;

  /// How many of the oldest matches go; null means all of them.
  final int? count;

  bool get isEverything => count == null;
}

/// Asks how much of the stored history to delete.
///
/// Both ways of clearing are here because both are wanted: a number of the
/// oldest matches, or the whole record. The count never includes a match still
/// in progress, which is the match the home screen offers to continue.
///
/// Resolves to null when the MC backs out.
Future<ClearHistoryChoice?> showClearHistoryDialog(
  BuildContext context, {
  required int stored,
  required int inProgress,
}) {
  return showDialog<ClearHistoryChoice>(
    context: context,
    builder: (_) => _ClearHistoryDialog(stored: stored, inProgress: inProgress),
  );
}

class _ClearHistoryDialog extends StatefulWidget {
  const _ClearHistoryDialog({required this.stored, required this.inProgress});

  /// Finished and abandoned matches: the only ones that can go.
  final int stored;

  /// Running matches, kept whatever the MC picks.
  final int inProgress;

  @override
  State<_ClearHistoryDialog> createState() => _ClearHistoryDialogState();
}

class _ClearHistoryDialogState extends State<_ClearHistoryDialog> {
  int _count = 1;

  bool get _all => _count >= widget.stored;

  String get _confirmLabel {
    if (!_all) return 'Delete the oldest $_count';
    return widget.stored == 1
        ? 'Delete the match'
        : 'Delete all ${widget.stored} matches';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Clear history'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Deleting removes the match from this phone, with its votes and '
              'its quests. It cannot be undone.',
              style: AppText.body,
            ),
            if (widget.inProgress > 0) ...[
              const SizedBox(height: Space.xs),
              Text(
                widget.inProgress == 1
                    ? 'The match in progress is kept.'
                    : 'The ${widget.inProgress} matches in progress are kept.',
                style: AppText.caption.copyWith(color: AppColors.lightGold),
              ),
            ],
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'The oldest go first.',
                    style: AppText.caption,
                  ),
                ),
                if (widget.stored > 1)
                  TextButton(
                    key: const Key('history_clear_all'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      minimumSize: const Size(48, kMinTapTarget),
                    ),
                    onPressed: () =>
                        setState(() => _count = widget.stored),
                    child: Text(
                      'All ${widget.stored}',
                      style: AppText.caption.copyWith(color: AppColors.gold),
                    ),
                  ),
              ],
            ),
            CounterStepper(
              key: const Key('history_clear_stepper'),
              label: 'Matches',
              value: _count,
              min: 1,
              max: widget.stored,
              keyPrefix: 'history_clear',
              icon: Icons.delete_sweep_outlined,
              tone: AppColors.parchment,
              onIncrement: _all ? null : () => setState(() => _count++),
              onDecrement: _count > 1
                  ? () => setState(() => _count--)
                  : null,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DangerButton(
              key: const Key('history_clear_confirm'),
              label: _confirmLabel,
              icon: Icons.delete_outline,
              onPressed: () => Navigator.of(context).pop(
                _all
                    ? const ClearHistoryChoice.everything()
                    : ClearHistoryChoice.oldest(_count),
              ),
            ),
            const SizedBox(height: Space.xs),
            SecondaryButton(
              key: const Key('history_clear_cancel'),
              label: 'Keep the history',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}
