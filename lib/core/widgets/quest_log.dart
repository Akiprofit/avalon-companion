import 'package:material_ui/material_ui.dart';

import '../../game_engine/models/game_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

/// The board as it was played: which players went on each resolved quest.
///
/// This is public state only. The table saw every one of these teams when it
/// approved them, so reading them back says nothing about who holds which
/// loyalty card — it is exactly the memory the table is allowed to have.
class QuestLog extends StatelessWidget {
  const QuestLog({super.key, required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    final runs = game.questLog;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < runs.length; i++) ...[
          if (i > 0) const Divider(height: Space.lg),
          _QuestRunRow(run: runs[i], game: game),
        ],
      ],
    );
  }
}

/// One resolved quest: its number, its outcome and the players who went on it.
class _QuestRunRow extends StatelessWidget {
  const _QuestRunRow({required this.run, required this.game});

  final QuestRun run;
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final (color, icon, outcome) = run.succeeded
        ? (AppColors.success, Icons.check_rounded, 'won')
        : (AppColors.danger, Icons.close_rounded, 'lost');

    final names = [
      for (final seat in run.seats)
        game.playerAtSeat(seat)?.name ?? 'Seat $seat',
    ];

    return Semantics(
      label: 'Quest ${run.questNumber}, $outcome'
          '${names.isEmpty ? ', team not recorded' : ', taken by ${names.join(', ')}'}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(Radii.chip),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                '${run.questNumber}',
                style: AppText.numeral.copyWith(fontSize: 16, color: color),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: Space.xxs),
                      Text(
                        'Quest ${run.questNumber} · $outcome',
                        style: AppText.bodyStrong.copyWith(color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    names.isEmpty
                        ? 'The team was not recorded for this quest.'
                        : names.join(', '),
                    style: AppText.body,
                  ),
                  if (run.seats.isNotEmpty)
                    Text(
                      run.seats.length == 1
                          ? 'Seat ${run.seats.first}'
                          : 'Seats ${run.seats.join(', ')}',
                      style: AppText.caption,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
