import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_bottom_navigation.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../database/database_provider.dart';
import '../../database/match_store.dart';
import '../../game_engine/models/game_state.dart';

/// Stored matches, newest first. Read fresh each time the screen opens, so a
/// match that just ended is already in the list.
final matchHistoryProvider =
    FutureProvider.autoDispose<List<MatchSummary>>((ref) async {
      final store = ref.watch(matchStoreProvider);
      if (store == null) return const [];
      return store.matches();
    });

/// Screen 13 — the public record of past matches.
///
/// Only what the table already knows: when it was played, how many sat down,
/// which quests passed and who won. There is no role column to show, and the
/// assassination is recorded as an outcome, never as a name.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(matchHistoryProvider);

    return AvalonScreen(
      appBar: AppBar(title: const Text('GAME HISTORY')),
      backgroundImage: Artwork.history,
      padded: false,
      bottom: AvalonBottomNavigation(
        currentRouteName: RouteNames.history,
        onSelected: (name) {
          if (name != RouteNames.history) context.goNamed(name);
        },
      ),
      child: history.when(
        loading: () => LoadingState(label: 'Reading the record…'),
        error: (error, _) => EmptyState(
          title: 'History unavailable',
          message:
              'The saved matches could not be read. The matches themselves are '
              'not affected.',
          icon: Icons.error_outline,
          action: PrimaryButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: () => ref.invalidate(matchHistoryProvider),
          ),
        ),
        data: (matches) => matches.isEmpty
            ? EmptyState(
                title: 'No matches yet',
                message:
                    'Finished and abandoned matches are listed here with their '
                    'outcome and quest record. Nothing is stored until a match '
                    'starts.',
                action: PrimaryButton(
                  label: 'New Game',
                  onPressed: () => context.goNamed(RouteNames.setup),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Space.screenPadding,
                  Space.md,
                  Space.screenPadding,
                  Space.xl,
                ),
                itemCount: matches.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return SectionHeader(
                      title: 'Past matches',
                      trailing: MetaPill(label: '${matches.length} stored'),
                    );
                  }
                  return _MatchTile(summary: matches[index - 1]);
                },
              ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.summary});

  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    final (title, tone) = switch (summary) {
      _ when summary.isInProgress => ('In progress', AppColors.lightGold),
      _ when summary.isAbandoned => ('Abandoned', AppColors.mutedText),
      _ when summary.winner == 'good' => ('Good victory', AppColors.gold),
      _ => ('Evil victory', AppColors.danger),
    };

    return MedievalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.bodyStrong.copyWith(color: tone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(summary.startedAt),
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                _QuestDot(
                  result: i < summary.questResults.length
                      ? summary.questResults[i]
                      : null,
                ),
                if (i < 4) const SizedBox(width: Space.xxs),
              ],
              const Spacer(),
              Text(
                summary.playerCount == 1
                    ? '1 player'
                    : '${summary.playerCount} players',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(_detail(summary), style: AppText.caption),
        ],
      ),
    );
  }

  static String _detail(MatchSummary summary) {
    if (summary.isInProgress) {
      return 'Still running — open it from the home screen.';
    }
    // Every match has five quest slots, so the tally is always out of five.
    final quests = '${summary.successCount} of 5 quests won';
    if (summary.isAbandoned) {
      return 'Left unfinished · $quests';
    }
    final duration = summary.duration;
    final threeQuests = summary.winReason == WinReason.threeQuests;
    return [
      switch (summary.winReason) {
        WinReason.threeQuests => 'Three quests won',
        WinReason.fiveRejections => 'Five proposals rejected',
        WinReason.assassination => summary.assassinationOutcome == 'identified'
            ? 'Merlin was identified'
            : 'Merlin survived the accusation',
        _ => 'Match complete',
      },
      // "Three quests won · 3 of 5 quests won" would say the same thing twice.
      if (!threeQuests) quests,
      if (duration != null)
        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
    ].join(' · ');
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

class _QuestDot extends StatelessWidget {
  const _QuestDot({this.result});

  final QuestResult? result;

  @override
  Widget build(BuildContext context) {
    final (color, border) = switch (result) {
      QuestResult.success => (AppColors.gold, AppColors.lightGold),
      QuestResult.fail => (AppColors.danger, AppColors.danger),
      null => (AppColors.surface, AppColors.mutedText),
    };
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color.withValues(alpha: result == null ? 0.4 : 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: border.withValues(alpha: 0.7)),
      ),
    );
  }
}
