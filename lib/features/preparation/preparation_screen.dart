import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/gold_divider.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../game_engine/models/character.dart';
import '../../game_engine/rules/avalon_tables.dart';
import '../setup/setup_controller.dart';

/// Screen 04 — final confirmation before the match, including the reminder to
/// deal the physical character cards.
class PreparationScreen extends ConsumerWidget {
  const PreparationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(setupProvider);
    final composition = draft.composition;

    return AvalonScreen(
      appBar: AppBar(title: const Text('PREPARATION')),
      backgroundImage: Artwork.preparation,
      showBackButton: true,
      onBack: () => context.goNamed(RouteNames.setup),
      padded: false,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.xs,
          Space.screenPadding,
          Space.md,
        ),
        child: PrimaryButton(
          key: const Key('preparation_begin'),
          label: 'Begin the match',
          icon: Icons.play_arrow_rounded,
          onPressed: draft.canStart
              ? () {
                  ref.read(gameSessionProvider.notifier).start(
                    names: draft.trimmedNames,
                    composition: composition,
                  );
                  context.goNamed(RouteNames.dashboard);
                }
              : null,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.md,
          Space.screenPadding,
          Space.xxl,
        ),
        children: [
          const Text(
            'THE ROUND TABLE',
            style: AppText.screenTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xxs),
          Text(
            '${draft.playerCount} players are seated.',
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
          const GoldDivider(),
          MedievalCard(
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Players',
                  value: '${draft.playerCount}',
                ),
                _SummaryRow(
                  label: 'Good',
                  value: '${composition.goodTotal}',
                  tone: AppColors.success,
                ),
                _SummaryRow(
                  label: 'Evil',
                  value: '${composition.evilTotal}',
                  tone: AppColors.danger,
                ),
                _SummaryRow(
                  label: 'Starting leader',
                  value: draft.trimmedNames.isEmpty
                      ? 'Seat 1'
                      : draft.trimmedNames.first,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          const SectionHeader(title: 'Composition'),
          MedievalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in composition.counts.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          entry.key.alignment == Allegiance.good
                              ? Icons.shield_outlined
                              : Icons.dark_mode_outlined,
                          size: 15,
                          color: entry.key.alignment == Allegiance.good
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: Text(entry.key.label, style: AppText.body),
                        ),
                        Text(
                          '×${entry.value}',
                          style: AppText.numeral.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          const SectionHeader(title: 'Quest requirements'),
          MedievalCard(
            child: Row(
              children: [
                for (var quest = 1; quest <= AvalonTables.questCount; quest++)
                  Expanded(
                    child: Column(
                      children: [
                        Text('Q$quest', style: AppText.caption),
                        const SizedBox(height: Space.xxs),
                        Text(
                          '${AvalonTables.teamSize(draft.playerCount, quest)}',
                          style: AppText.numeral,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          MedievalCard(
            borderColor: AppColors.mutedGold,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.style_outlined,
                  size: 18,
                  color: AppColors.gold,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deal the cards now', style: AppText.bodyStrong),
                      const SizedBox(height: Space.xxs),
                      Text(
                        'Shuffle and deal the physical character cards. This app '
                        'never asks who received which card, and it stores no '
                        'such information.',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (composition.warnings.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            const SectionHeader(title: 'Worth knowing'),
            MedievalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final warning in composition.warnings)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.mutedGold,
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: Text(
                              warning.message,
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
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.caption)),
          Text(
            value,
            style: AppText.bodyStrong.copyWith(color: tone ?? AppColors.parchment),
          ),
        ],
      ),
    );
  }
}
