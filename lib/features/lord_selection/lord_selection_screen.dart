import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/services/feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../game_engine/engine/game_engine.dart';
import '../../game_engine/models/phase.dart';
import '../../game_engine/models/player.dart';
import '../settings/settings_controller.dart';

/// Screen 06 — the Lord (King) is drawn by the wheel.
///
/// The draw is real: a seat is picked from the seated players when the wheel
/// starts spinning, and the reel is animated to land on it. The engine then
/// records that seat as the leader, so nothing downstream depends on the
/// animation. Only public seats and names take part.
///
/// With "New King every round" the wheel starts itself as soon as the screen
/// opens; in the manual mode the MC presses the button. Either way the same
/// draw runs, and the King who has just served is left out of it so nobody
/// leads twice in a row.
class LordSelectionScreen extends ConsumerStatefulWidget {
  const LordSelectionScreen({super.key, this.random});

  /// Injectable source of randomness so a test can pin the outcome.
  final Random? random;

  @override
  ConsumerState<LordSelectionScreen> createState() =>
      _LordSelectionScreenState();
}

class _LordSelectionScreenState extends ConsumerState<LordSelectionScreen>
    with SingleTickerProviderStateMixin {
  static const _itemHeight = 56.0;
  static const _visibleRows = 3;
  static const _laps = 5;

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  final _fallbackRandom = Random.secure();
  int? _winnerIndex;
  bool _spinning = false;
  bool _revealed = false;
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    // Automatic King mode: the round is opened by the wheel itself, so the MC
    // only has to hand the phone to the table.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoStarted) return;
      _autoStarted = true;
      final game = ref.read(gameSessionProvider);
      final automatic = ref.read(settingsProvider).kingsDrawnAutomatically;
      if (automatic && game != null && game.phase == Phase.lordSelection) {
        _draw();
      }
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _draw() {
    final game = ref.read(gameSessionProvider);
    if (game == null || game.players.isEmpty || _spinning) return;

    // The engine decides who may be drawn: everybody on the first draw of the
    // match, and everybody but the King who has just served after that.
    final candidates = GameEngine.drawableLordSeats(game);
    if (candidates.isEmpty) return;
    final random = widget.random ?? _fallbackRandom;
    final seat = candidates[random.nextInt(candidates.length)];
    final index = game.players.indexWhere((player) => player.seat == seat);
    setState(() {
      _winnerIndex = index < 0 ? 0 : index;
      _spinning = true;
      _revealed = false;
    });

    _spin.duration = motionDuration(
      context,
      const Duration(milliseconds: 2600),
    );
    _spin.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      ref.read(feedbackProvider).tap();
      setState(() {
        _spinning = false;
        _revealed = true;
      });
    });
  }

  void _continue(List<Player> players) {
    final index = _winnerIndex;
    if (index == null) return;
    ref.read(gameSessionProvider.notifier).chooseLord(players[index].seat);
    context.goNamed(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameSessionProvider);
    if (game == null) {
      return const AvalonScreen(child: SizedBox.shrink());
    }

    // Revisiting the screen after the draw shows the standing Lord instead of
    // offering a second spin: the engine only accepts one draw per round.
    final alreadyDrawn = game.phase != Phase.lordSelection;
    final firstDraw = game.questResults.isEmpty && game.rejectionCount == 0;
    final players = game.players;
    final required = game.requiredTeamSize;
    // Who may be drawn now: the whole table on the opening draw, everybody but
    // the King who has just served after that.
    final seatsInDraw =
        GameEngine.drawableLordSeats(game).length;

    return AvalonScreen(
      padded: false,
      backgroundImage: Artwork.roundTable,
      appBar: AppBar(
        title: const Text('CHOOSE THE LORD'),
        leading: IconButton(
          key: const Key('lord_back'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to the table',
          onPressed: () => context.goNamed(RouteNames.dashboard),
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.xs,
          Space.screenPadding,
          Space.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alreadyDrawn) ...[
              PrimaryButton(
                key: const Key('lord_continue'),
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.goNamed(RouteNames.dashboard),
              ),
            ] else if (_revealed) ...[
              PrimaryButton(
                key: const Key('lord_continue'),
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => _continue(players),
              ),
              const SizedBox(height: Space.xs),
              SecondaryButton(
                key: const Key('lord_redraw'),
                label: 'Draw again',
                icon: Icons.casino_outlined,
                onPressed: _draw,
              ),
            ] else
              PrimaryButton(
                key: const Key('lord_spin'),
                label: _spinning ? 'The wheel turns…' : 'Choose the Lord',
                icon: Icons.casino_outlined,
                onPressed: _spinning ? null : _draw,
              ),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.screenPadding,
                Space.md,
                Space.screenPadding,
                Space.xl,
              ),
              children: [
                MedievalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alreadyDrawn
                            ? 'The King for this round is already drawn.'
                            : firstDraw
                            ? 'The night is over. Draw the first Lord of the '
                                  'round table.'
                            : 'The vote is settled. Draw the King for quest '
                                  '${game.questNumber}.',
                        key: const Key('lord_heading'),
                        style: AppText.body,
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        'The Lord puts forward the team for quest '
                        '${game.questNumber}, which needs $required '
                        '${required == 1 ? 'player' : 'players'}. '
                        '${seatsInDraw < players.length ? 'The King who has '
                                  'just served sits this draw out.' : 'Every '
                                  'seat takes part in the draw.'}',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                SectionHeader(
                  title: 'The wheel of seats',
                  trailing: MetaPill(label: '${players.length} seated'),
                ),
                MedievalCard(
                  padding: const EdgeInsets.symmetric(vertical: Space.sm),
                  child: alreadyDrawn
                      ? _DrawnLord(name: game.leader.displayName)
                      : _Wheel(
                          players: players,
                          winnerIndex: _winnerIndex,
                          animation: _spin,
                          itemHeight: _itemHeight,
                          visibleRows: _visibleRows,
                          laps: _laps,
                          revealed: _revealed,
                        ),
                ),
                if (_revealed && !alreadyDrawn) ...[
                  const SizedBox(height: Space.md),
                  _Announcement(
                    name: players[_winnerIndex!].displayName,
                    questNumber: game.questNumber,
                  ),
                ],
                const SizedBox(height: Space.lg),
                const SectionHeader(title: 'At the table'),
                MedievalCard(
                  padding: const EdgeInsets.all(Space.xs),
                  child: Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xxs,
                    children: [
                      for (final player in players)
                        MetaPill(
                          label: '${player.seat}. ${player.displayName}',
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The reel: a clipped column of names that decelerates onto the winner.
class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.players,
    required this.winnerIndex,
    required this.animation,
    required this.itemHeight,
    required this.visibleRows,
    required this.laps,
    required this.revealed,
  });

  final List<Player> players;
  final int? winnerIndex;
  final Animation<double> animation;
  final double itemHeight;
  final int visibleRows;
  final int laps;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final entries = [for (var lap = 0; lap <= laps; lap++) ...players];
    // Middle row of the viewport must land on the winner, which sits in the
    // last lap: offset = (target - middleRow) * itemHeight.
    final target = winnerIndex == null
        ? 0.0
        : ((laps * players.length) + winnerIndex!).toDouble();
    final middleRow = ((visibleRows - 1) / 2).toDouble();
    final travel =
        (target - middleRow).clamp(0.0, double.infinity) * itemHeight;

    return Semantics(
      container: true,
      label: winnerIndex == null
          ? 'Wheel of seats, not yet spun'
          : 'Wheel of seats landing on ${players[winnerIndex!].displayName}',
      child: SizedBox(
        height: itemHeight * visibleRows,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Positioned so the reel keeps its natural height and is clipped by
            // the viewport instead of fighting the Stack's constraints.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final eased = Curves.easeOutQuart.transform(animation.value);
                  return Transform.translate(
                    offset: Offset(0, -(travel * eased)),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      SizedBox(
                        height: itemHeight,
                        child: Center(
                          child: Text(
                            entries[i].displayName,
                            key: i == laps * players.length + (winnerIndex ?? 0)
                                ? const Key('lord_winner_row')
                                : null,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sectionTitle.copyWith(
                              color: revealed
                                  ? AppColors.lightGold
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Highlight band across the centre row.
            IgnorePointer(
              child: Center(
                child: Container(
                  height: itemHeight,
                  decoration: BoxDecoration(
                    color: AppColors.goldOverlay,
                    borderRadius: BorderRadius.circular(Radii.card),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
            // Fade the rows above and below so the reel reads as a wheel.
            IgnorePointer(
              child: Column(
                children: [
                  _FadeEdge(alignment: Alignment.topCenter),
                  const Spacer(),
                  _FadeEdge(alignment: Alignment.bottomCenter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FadeEdge extends StatelessWidget {
  const _FadeEdge({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignment,
          end: alignment == Alignment.topCenter
              ? Alignment.bottomCenter
              : Alignment.topCenter,
          colors: [
            AppColors.backgroundSecondary.withValues(alpha: 0.95),
            AppColors.backgroundSecondary.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// The drawn name, with the sentence the MC reads out.
class _Announcement extends StatelessWidget {
  const _Announcement({required this.name, required this.questNumber});

  final String name;
  final int questNumber;

  @override
  Widget build(BuildContext context) {
    return MedievalCard(
      child: Column(
        children: [
          Text(
            'THE LORD HAS BEEN CHOSEN',
            style: AppText.sectionTitle.copyWith(
              color: AppColors.lightGold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xs),
          Text(
            name,
            key: const Key('lord_result_name'),
            style: AppText.display.copyWith(fontSize: 30),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xxs),
          Text(
            'Leads the table for quest $questNumber.',
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Shown when the screen is reopened after the draw.
class _DrawnLord extends StatelessWidget {
  const _DrawnLord({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      child: Column(
        children: [
          const Icon(
            Icons.military_tech_outlined,
            size: 32,
            color: AppColors.gold,
          ),
          const SizedBox(height: Space.xs),
          Text(name, style: AppText.display.copyWith(fontSize: 26)),
          const SizedBox(height: Space.xxs),
          Text('Holds the leadership token.', style: AppText.caption),
        ],
      ),
    );
  }
}
