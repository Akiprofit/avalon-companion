import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/routes.dart';
import '../../core/services/feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_bottom_navigation.dart';
import '../../core/widgets/avalon_icon_button.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../database/database_provider.dart';
import '../../database/match_store.dart';
import '../../game_engine/models/game_state.dart';
import 'clear_history_dialog.dart';
import 'match_detail_sheet.dart';

/// Stored matches, newest first. Read fresh each time the screen opens, so a
/// match that just ended is already in the list.
final matchHistoryProvider = FutureProvider.autoDispose<List<MatchSummary>>((
  ref,
) async {
  final store = ref.watch(matchStoreProvider);
  if (store == null) return const [];
  return store.matches();
});

/// Screen 13 — the public record of past matches.
///
/// Only what the table already knows: when it was played, how many sat down,
/// which quests passed and who won. There is no role column to show, and the
/// assassination is recorded as an outcome, never as a name.
///
/// Long-pressing a finished or abandoned match starts a selection: the card
/// lifts, buzzes and shows a check, and the app bar becomes the delete bar.
/// Tapping toggles cards while selecting, and selecting all never includes the
/// match still in progress — that is the match **Continue Game** offers.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final Set<int> _selected = {};
  final Set<int> _removing = {};
  bool _deleting = false;

  bool get _selecting => _selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(matchHistoryProvider);

    // A match can disappear while the screen is open (a store refresh, or a
    // deletion from the clear dialog). Drop ids that are no longer stored so
    // the count in the app bar can never include a card that is gone.
    ref.listen(matchHistoryProvider, (_, next) {
      final data = next.asData?.value;
      if (data == null) return;
      final ids = {for (final match in data) match.id};
      if (_selected.any((id) => !ids.contains(id))) {
        setState(() {
          _selected.removeWhere((id) => !ids.contains(id));
          _removing.removeWhere((id) => !ids.contains(id));
        });
      }
    });

    final matches = history.asData?.value ?? const <MatchSummary>[];
    final deletable = [
      for (final match in matches)
        if (!match.isInProgress) match,
    ];
    final inProgress = matches.length - deletable.length;
    final allSelected =
        deletable.isNotEmpty && _selected.length >= deletable.length;

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selecting) _exitSelection();
      },
      child: AvalonScreen(
        appBar: _appBar(
          selecting: _selecting,
          selected: _selected.length,
          deletable: deletable,
          allSelected: allSelected,
          inProgress: inProgress,
        ),
        backgroundImage: Artwork.history,
        padded: false,
        capBottom: false,
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
                'The saved matches could not be read. The matches themselves '
                'are not affected.',
            icon: Icons.error_outline,
            action: PrimaryButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: () => ref.invalidate(matchHistoryProvider),
            ),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return EmptyState(
                title: 'No matches yet',
                message:
                    'Finished and abandoned matches are listed here with their '
                    'outcome and quest record. Nothing is stored until a match '
                    'starts.',
                action: PrimaryButton(
                  label: 'New Game',
                  onPressed: () => context.goNamed(RouteNames.setup),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Space.screenPadding,
                Space.md,
                Space.screenPadding,
                Space.xl,
              ),
              itemCount: rows.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _header(
                    selecting: _selecting,
                    stored: rows.length,
                    deletable: deletable,
                    inProgress: inProgress,
                  );
                }
                return _tile(rows[index - 1], index - 1);
              },
            );
          },
        ),
      ),
    );
  }

  /// The normal title, or the selection title and its two actions.
  PreferredSizeWidget _appBar({
    required bool selecting,
    required int selected,
    required List<MatchSummary> deletable,
    required bool allSelected,
    required int inProgress,
  }) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : Motion.micro;

    return AppBar(
      leading: selecting
          ? IconButton(
              key: const Key('history_selection_close'),
              icon: const Icon(Icons.close),
              tooltip: 'Cancel selection',
              onPressed: _deleting ? null : _exitSelection,
            )
          : null,
      title: AnimatedSwitcher(
        duration: duration,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Text(
          selecting ? '$selected selected' : 'GAME HISTORY',
          key: ValueKey(
            selecting ? 'history_title_$selected' : 'history_title',
          ),
          style: selecting
              ? AppText.screenTitle.copyWith(
                  fontSize: 18,
                  color: AppColors.gold,
                )
              : null,
        ),
      ),
      actions: [
        AnimatedSwitcher(
          duration: duration,
          child: selecting
              ? Row(
                  key: const ValueKey('history_selection_actions'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AvalonIconButton(
                      key: const Key('history_select_all'),
                      icon: allSelected ? Icons.deselect : Icons.select_all,
                      semanticLabel: allSelected
                          ? 'Deselect all matches'
                          : 'Select all matches',
                      tooltip: allSelected ? 'Deselect all' : 'Select all',
                      onPressed: _deleting
                          ? null
                          : () => _toggleSelectAll(deletable),
                    ),
                    AvalonIconButton(
                      key: const Key('history_delete_selected'),
                      icon: Icons.delete_outline,
                      semanticLabel: 'Delete selected matches',
                      tooltip: 'Delete selected',
                      onPressed: _deleting
                          ? null
                          : () => _deleteSelected(inProgress: inProgress),
                    ),
                    const SizedBox(width: Space.xxs),
                  ],
                )
              : const SizedBox(
                  key: ValueKey('history_normal_actions'),
                  width: 0,
                  height: 0,
                ),
        ),
      ],
    );
  }

  /// The list heading. It changes to a short instruction while selecting, and
  /// the clear-history control steps aside so there is only one delete action.
  Widget _header({
    required bool selecting,
    required int stored,
    required List<MatchSummary> deletable,
    required int inProgress,
  }) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : Motion.transition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: duration,
          child: SectionHeader(
            key: ValueKey(
              selecting ? 'history_header_select' : 'history_header',
            ),
            title: selecting ? 'Select matches' : 'Past matches',
            trailing: selecting
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: duration,
                        child: MetaPill(
                          key: ValueKey('history_stored_$stored'),
                          label: '$stored stored',
                        ),
                      ),
                      const SizedBox(width: Space.xxs),
                      AvalonIconButton(
                        key: const Key('history_clear'),
                        icon: Icons.delete_sweep_outlined,
                        semanticLabel: 'Clear history',
                        tooltip: 'Clear history',
                        onPressed: deletable.isEmpty
                            ? null
                            : () => _clear(
                                deletable: deletable.length,
                                inProgress: inProgress,
                              ),
                      ),
                    ],
                  ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          alignment: Alignment.topLeft,
          child: selecting
              ? Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: Text(
                    'Tap a match to add or remove it. A match in progress is '
                    'kept.',
                    style: AppText.caption,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _tile(MatchSummary summary, int index) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : Motion.transition;
    final removing = _removing.contains(summary.id);

    return _HistoryEntrance(
      key: ValueKey('history_entrance_${summary.id}'),
      index: index,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
        child: removing
            ? SizedBox(
                key: ValueKey('history_removed_${summary.id}'),
                width: double.infinity,
              )
            : _MatchTile(
                key: ValueKey('history_tile_${summary.id}'),
                summary: summary,
                selecting: _selecting,
                selected: _selected.contains(summary.id),
                onTap: _deleting ? null : () => _onTap(summary),
                onLongPress: _deleting ? null : () => _onLongPress(summary),
              ),
      ),
    );
  }

  void _onTap(MatchSummary summary) {
    if (!_selecting) {
      unawaited(showMatchDetail(context, summary));
      return;
    }
    if (summary.isInProgress) {
      _explainKept();
      return;
    }
    _toggle(summary, firm: false);
  }

  void _onLongPress(MatchSummary summary) {
    if (_deleting) return;
    if (summary.isInProgress) {
      _explainKept();
      return;
    }
    if (!_selected.contains(summary.id)) {
      setState(() => _selected.add(summary.id));
    }
    // The card's own press animation gives the visual pulse; this is the part
    // the MC feels rather than sees.
    ref.read(feedbackProvider).select();
  }

  void _toggle(MatchSummary summary, {required bool firm}) {
    setState(() {
      if (!_selected.remove(summary.id)) _selected.add(summary.id);
    });
    if (_selected.isEmpty && !firm) {
      ref.read(feedbackProvider).tap();
      return;
    }
    final feedback = ref.read(feedbackProvider);
    firm ? feedback.select() : feedback.tap();
  }

  void _toggleSelectAll(List<MatchSummary> deletable) {
    final allSelected = _selected.length >= deletable.length;
    setState(() {
      _selected.clear();
      if (!allSelected) {
        _selected.addAll(deletable.map((match) => match.id));
      }
    });
    ref.read(feedbackProvider).select();
  }

  void _exitSelection() {
    if (_selected.isEmpty) return;
    setState(() => _selected.clear());
    ref.read(feedbackProvider).tap();
  }

  void _explainKept() {
    ref.read(feedbackProvider).warning();
    _showSnack(
      'A match in progress cannot be deleted. Open it from the home screen '
      'to continue.',
    );
  }

  /// Asks first, then collapses the chosen cards and deletes exactly those ids.
  Future<void> _deleteSelected({required int inProgress}) async {
    if (_deleting) return;
    final ids = _selected.toSet();
    if (ids.isEmpty) return;

    final count = ids.length;
    final confirmed = await confirmAction(
      context,
      ref,
      title: count == 1 ? 'Delete this match?' : 'Delete $count matches?',
      message: [
        count == 1
            ? 'It leaves this phone with its votes and its quests. This '
                  'cannot be undone.'
            : 'They leave this phone with their votes and their quests. This '
                  'cannot be undone.',
        if (inProgress > 0) 'The match in progress is kept.',
      ].join(' '),
      confirmLabel: count == 1 ? 'Delete the match' : 'Delete $count matches',
      cancelLabel: count == 1 ? 'Keep it' : 'Keep them',
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _deleting = true;
      _removing.addAll(ids);
    });

    // Let the cards collapse before the list is re-read. Reduced motion skips
    // the wait, because there is nothing on screen to finish.
    if (!MediaQuery.of(context).disableAnimations) {
      await Future<void>.delayed(Motion.transition);
    }
    if (!mounted) return;

    final store = ref.read(matchStoreProvider);
    if (store == null) {
      setState(() {
        _deleting = false;
        _removing.clear();
      });
      _showSnack('History cannot be cleared: storage is unavailable.');
      return;
    }

    try {
      final deleted = await store.deleteMatches(ids);
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _removing.clear();
        _selected.clear();
      });
      ref.invalidate(matchHistoryProvider);
      _showSnack(
        deleted == 0
            ? 'Nothing was deleted.'
            : deleted == 1
            ? 'Deleted 1 match.'
            : 'Deleted $deleted matches.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _removing.clear();
      });
      _showSnack('The stored matches could not be deleted.');
    }
  }

  /// Asks how much to delete, deletes it and re-reads the list.
  Future<void> _clear({required int deletable, required int inProgress}) async {
    final choice = await showClearHistoryDialog(
      context,
      stored: deletable,
      inProgress: inProgress,
    );
    if (choice == null || !mounted) return;

    final store = ref.read(matchStoreProvider);
    if (store == null) {
      _showSnack('History cannot be cleared: storage is unavailable.');
      return;
    }

    try {
      final deleted = await store.deleteHistory(count: choice.count);
      ref.read(feedbackProvider).tap();
      if (!mounted) return;
      _showSnack(
        deleted == 1 ? 'Deleted 1 match.' : 'Deleted $deleted matches.',
      );
      ref.invalidate(matchHistoryProvider);
    } catch (_) {
      if (!mounted) return;
      _showSnack('The stored matches could not be deleted.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Fades and lifts one history card into place, with a small stagger so the
/// list arrives as a list rather than a single flash.
class _HistoryEntrance extends StatefulWidget {
  const _HistoryEntrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_HistoryEntrance> createState() => _HistoryEntranceState();
}

class _HistoryEntranceState extends State<_HistoryEntrance> {
  Timer? _timer;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _visible) return;
    if (MediaQuery.of(context).disableAnimations) {
      _visible = true;
      return;
    }
    // Cap the wait: a long history should not take a second to finish arriving.
    final order = widget.index > 7 ? 7 : widget.index;
    _timer = Timer(Duration(milliseconds: 24 * order), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : Motion.transition;
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    super.key,
    required this.summary,
    required this.selecting,
    required this.selected,
    this.onTap,
    this.onLongPress,
  });

  final MatchSummary summary;
  final bool selecting;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final (title, tone) = switch (summary) {
      _ when summary.isInProgress => ('In progress', AppColors.lightGold),
      _ when summary.isAbandoned => ('Abandoned', AppColors.mutedText),
      _ when summary.winner == 'good' => ('Good victory', AppColors.gold),
      _ => ('Evil victory', AppColors.danger),
    };

    return MedievalCard(
      key: Key('history_match_${summary.id}'),
      onTap: onTap,
      onLongPress: onLongPress,
      isSelected: selected,
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
          Row(
            children: [
              Expanded(child: Text(_detail(summary), style: AppText.caption)),
              _trailing(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trailing() {
    if (!selecting) {
      return const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.mutedText,
      );
    }
    if (summary.isInProgress) {
      return const Tooltip(
        message: 'In progress — kept',
        child: Icon(Icons.lock_outline, size: 19, color: AppColors.mutedText),
      );
    }
    return _SelectionMark(selected: selected);
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
        WinReason.assassination =>
          summary.assassinationOutcome == 'identified'
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

/// The check drawn on a card that is part of the selection.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : Motion.transition;

    return TweenAnimationBuilder<double>(
      key: ValueKey(selected),
      tween: Tween(begin: selected ? 0.6 : 1, end: 1),
      duration: duration,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: AnimatedContainer(
        duration: duration,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.gold : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.mutedText,
            width: 2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: duration,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: selected
              ? const Icon(
                  Icons.check,
                  key: ValueKey('selected'),
                  size: 17,
                  color: AppColors.onGold,
                )
              : const SizedBox(key: ValueKey('unselected')),
        ),
      ),
    );
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
