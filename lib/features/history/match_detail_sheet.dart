import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../database/match_store.dart';
import '../../game_engine/models/game_state.dart';

/// Opens the record of one stored match.
Future<void> showMatchDetail(BuildContext context, MatchSummary summary) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
    ),
    builder: (_) => MatchDetailSheet(summary: summary),
  );
}

/// What the table can read back about a finished match: the result, the quests
/// and the team that went on each one.
///
/// Public state only. There is no role column here because none is stored: the
/// sheet is exactly the record the table itself could keep on paper.
class MatchDetailSheet extends StatelessWidget {
  const MatchDetailSheet({super.key, required this.summary});

  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    final (title, tone) = _title();
    final height = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height),
        child: SingleChildScrollView(
          key: const Key('history_detail_sheet'),
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.sm,
            Space.lg,
            Space.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      key: const Key('history_detail_title'),
                      style: AppText.sectionTitle.copyWith(color: tone),
                    ),
                  ),
                  IconButton(
                    key: const Key('history_detail_close'),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close the record',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                _formatDate(summary.startedAt),
                style: AppText.caption.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: Space.md),
              Text(_outcome(), style: AppText.body),
              const SizedBox(height: Space.md),
              _DetailRow(label: 'Players', value: '${summary.playerCount}'),
              _DetailRow(
                label: 'Quests won by Good',
                value: '${summary.successCount} of 5',
                tone: AppColors.success,
              ),
              _DetailRow(
                label: 'Quests lost to Evil',
                value: '${summary.failCount} of 5',
                tone: AppColors.danger,
              ),
              if (summary.rejectionCount > 0)
                _DetailRow(
                  label: 'Proposals rejected in the last round',
                  value: '${summary.rejectionCount}',
                ),
              if (summary.duration != null)
                _DetailRow(
                  label: 'Match length',
                  value: _duration(summary.duration!),
                  isLast: true,
                ),
              const SizedBox(height: Space.lg),
              Text(
                'THE QUESTS',
                style: AppText.sectionTitle.copyWith(
                  letterSpacing: 2,
                  color: AppColors.mutedGold,
                ),
              ),
              const SizedBox(height: Space.xs),
              if (summary.questResults.isEmpty)
                Text(
                  summary.isInProgress
                      ? 'No quest has resolved yet.'
                      : 'No quest was resolved before the match ended.',
                  style: AppText.body,
                )
              else
                for (var i = 0; i < summary.questResults.length; i++)
                  _QuestRow(
                    number: i + 1,
                    result: summary.questResults[i],
                    seats: i < summary.questTeams.length
                        ? summary.questTeams[i]
                        : const [],
                  ),
              if (summary.questResults.length < 5 &&
                  summary.questResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text(
                    summary.questResults.length == 4
                        ? 'The fifth quest was not played.'
                        : 'The remaining quests were not played.',
                    style: AppText.caption,
                  ),
                ),
              const SizedBox(height: Space.lg),
              Text(
                'Roles are never stored. This record is the public state the '
                'table saw: the result, the quests and the teams it approved — '
                'never who held which card.',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _title() {
    if (summary.isInProgress) return ('Still running', AppColors.lightGold);
    if (summary.isAbandoned) return ('Abandoned', AppColors.mutedText);
    if (summary.winner == 'good') return ('Good victory', AppColors.gold);
    return ('Evil victory', AppColors.danger);
  }

  String _outcome() {
    if (summary.isInProgress) {
      return 'This match is still in progress. Open it from the home screen '
          'to continue.';
    }
    if (summary.isAbandoned) {
      return 'The match was left unfinished after '
          '${summary.questResults.length} '
          '${summary.questResults.length == 1 ? 'quest' : 'quests'}.';
    }
    return switch (summary.winReason) {
      WinReason.threeQuests => 'Good won three quests and held the line.',
      WinReason.fiveRejections =>
        'Five proposals were rejected in a row, so Evil took the match.',
      WinReason.assassination =>
        summary.assassinationOutcome == 'identified'
            ? 'Evil identified Merlin in the accusation.'
            : 'Merlin survived the accusation, so Good held the victory.',
      _ => 'The match is complete.',
    };
  }

  static String _duration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_months[date.month - 1]} ${date.year} · '
        '$hour:$minute';
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.number,
    required this.result,
    required this.seats,
  });

  final int number;
  final QuestResult result;
  final List<int> seats;

  @override
  Widget build(BuildContext context) {
    final won = result == QuestResult.success;
    final color = won ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            won ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quest $number · ${won ? 'won' : 'lost'}',
                  style: AppText.bodyStrong.copyWith(color: color),
                ),
                Text(
                  seats.isEmpty
                      ? 'The team was not recorded for this quest.'
                      : seats.length == 1
                      ? 'Seat ${seats.first} went on the quest.'
                      : 'Seats ${seats.join(', ')} went on the quest.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.tone,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Color? tone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : Space.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: Space.sm),
          Text(
            value,
            style: AppText.bodyStrong.copyWith(
              color: tone ?? AppColors.parchment,
            ),
          ),
        ],
      ),
    );
  }
}
