import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/game_progress_header.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../game_engine/models/phase.dart';
import '../settings/settings_controller.dart';

/// Screen 11 — the assassination.
///
/// The table conducts the accusation with the physical cards; the phone only
/// offers the two possible outcomes. It never asks for, or stores, the name:
/// whether Merlin was identified is the entire record (master plan §2.2).
class AssassinationScreen extends ConsumerStatefulWidget {
  const AssassinationScreen({super.key});

  @override
  ConsumerState<AssassinationScreen> createState() =>
      _AssassinationScreenState();
}

class _AssassinationScreenState extends ConsumerState<AssassinationScreen> {
  bool _recording = false;

  Future<void> _record({required bool merlinIdentified}) async {
    if (_recording) return;

    final confirmed = await confirmAction(
      context,
      ref,
      title: merlinIdentified
          ? 'Record a successful assassination?'
          : "Record Merlin's escape?",
      message: merlinIdentified
          ? 'Merlin was named. Evil wins the match. This cannot be undone.'
          : 'Merlin was not named. Good wins the match. This cannot be undone.',
      confirmLabel: merlinIdentified ? 'Record Evil victory' : 'Record Good victory',
      cancelLabel: 'Not yet',
      isDestructive: merlinIdentified,
    );
    if (!confirmed || !mounted) return;

    setState(() => _recording = true);
    ref
        .read(gameSessionProvider.notifier)
        .resolveAssassination(merlinIdentified: merlinIdentified);
    if (!mounted) return;
    context.goNamed(RouteNames.results);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameSessionProvider);
    if (game == null || game.phase != Phase.assassination) {
      return AvalonScreen(
        appBar: AppBar(title: const Text('THE ASSASSINATION')),
        backgroundImage: Artwork.assassination,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The accusation only follows three successful quests.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.lg),
              PrimaryButton(
                key: const Key('assassination_none_back'),
                label: 'Back to the table',
                icon: Icons.arrow_back,
                onPressed: () => context.goNamed(RouteNames.dashboard),
              ),
            ],
          ),
        ),
      );
    }

    return AvalonScreen(
      padded: false,
      backgroundImage: Artwork.assassination,
      appBar: AppBar(
        title: const Text('THE ASSASSINATION'),
        leading: IconButton(
          key: const Key('assassination_back'),
          icon: const Icon(Icons.arrow_back),
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
            PrimaryButton(
              key: const Key('assassination_named'),
              label: 'Merlin was named — Evil wins',
              icon: Icons.gavel_rounded,
              onPressed: _recording
                  ? null
                  : () => _record(merlinIdentified: true),
            ),
            const SizedBox(height: Space.xs),
            SecondaryButton(
              key: const Key('assassination_survived'),
              label: 'Merlin survived — Good wins',
              icon: Icons.shield_outlined,
              onPressed: _recording
                  ? null
                  : () => _record(merlinIdentified: false),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          GameProgressHeader(
            leaderName: game.leader.displayName,
            questNumber: game.questNumber,
            requiredTeamSize: game.requiredTeamSize,
            rejectionCount: game.rejectionCount,
            showRejections: ref.watch(
              settingsProvider.select((s) => s.teamVoteEnabled),
            ),
            phaseLabel: game.phase.label,
            questSlots: game.questSlots,
          ),
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
                        'GOOD HAS COMPLETED THREE QUESTS.',
                        style: AppText.screenTitle.copyWith(
                          color: AppColors.lightGold,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Text(
                        'The assassin now wakes and names one player. Do not '
                        'touch this phone until the name has been spoken and '
                        "that player's character card has been turned over.",
                        style: AppText.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                const SectionHeader(title: 'How the accusation runs'),
                MedievalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Step(
                        number: 1,
                        text: 'The MC asks the assassin to name one player.',
                      ),
                      const SizedBox(height: Space.sm),
                      _Step(
                        number: 2,
                        text: 'That player turns over their character card.',
                      ),
                      const SizedBox(height: Space.sm),
                      _Step(
                        number: 3,
                        text:
                            'Was the named player Merlin? Record only the '
                            'answer below.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                MedievalCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.mutedGold,
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          'The app records the outcome, never the name. No '
                          'player is ever linked to a character.',
                          style: AppText.caption,
                        ),
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

/// One numbered instruction.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold),
          ),
          child: Text(
            '$number',
            style: AppText.caption.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(child: Text(text, style: AppText.body)),
      ],
    );
  }
}
