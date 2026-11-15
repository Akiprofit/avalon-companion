import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../game_engine/models/character.dart';
import '../../game_engine/rules/avalon_tables.dart';
import 'setup_controller.dart';

/// Screen 03 — player count, names and character composition.
/// The MC never assigns a character to a player.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final List<TextEditingController> _nameControllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers(ref.read(setupProvider).playerCount);
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(int count) {
    while (_nameControllers.length < count) {
      final index = _nameControllers.length;
      _nameControllers.add(
        TextEditingController(text: ref.read(setupProvider).names[index]),
      );
    }
    while (_nameControllers.length > count) {
      _nameControllers.removeLast().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(setupProvider);
    final notifier = ref.read(setupProvider.notifier);
    final issues = draft.composition.validate();
    final good = draft.composition.goodTotal;
    final evil = draft.composition.evilTotal;
    final requiredGood = AvalonTables.goodCount(draft.playerCount);
    final requiredEvil = AvalonTables.evilCount(draft.playerCount);

    return AvalonScreen(
      showBackButton: true,
      backgroundImage: Artwork.setup,
      appBar: AppBar(title: const Text('GAME SETUP')),
      onBack: () => context.goNamed(RouteNames.home),
      padded: false,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.xs,
          Space.screenPadding,
          Space.md,
        ),
        child: PrimaryButton(
          key: const Key('setup_continue'),
          label: 'Review and prepare',
          icon: Icons.arrow_forward_rounded,
          onPressed: draft.canStart
              ? () => context.goNamed(RouteNames.preparation)
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
          const SectionHeader(title: 'Players'),
          MedievalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How many are at the table?',
                  style: AppText.body,
                ),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    for (var count = AvalonTables.minPlayers;
                        count <= AvalonTables.maxPlayers;
                        count++)
                      _CountChip(
                        key: Key('setup_count_$count'),
                        label: '$count',
                        selected: draft.playerCount == count,
                        onTap: () {
                          notifier.setPlayerCount(count);
                          _syncControllers(count);
                          for (var i = 0; i < _nameControllers.length; i++) {
                            if (_nameControllers[i].text.isEmpty) {
                              _nameControllers[i].text =
                                  ref.read(setupProvider).names[i];
                            }
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                Text(
                  '$playerLabel — $requiredGood good, $requiredEvil evil.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          const SectionHeader(title: 'Seating order'),
          MedievalCard(
            child: Column(
              children: [
                for (var seat = 0; seat < draft.playerCount; seat++) ...[
                  if (seat > 0) const SizedBox(height: Space.xs),
                  Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${seat + 1}',
                          style: AppText.numeral.copyWith(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          key: Key('setup_name_$seat'),
                          controller: _nameControllers[seat],
                          textCapitalization: TextCapitalization.words,
                          style: AppText.body,
                          decoration: InputDecoration(
                            hintText: 'Player ${seat + 1}',
                            isDense: true,
                          ),
                          onChanged: (value) => notifier.setName(seat, value),
                        ),
                      ),
                      if (seat == 0)
                        const Padding(
                          padding: EdgeInsets.only(left: Space.xs),
                          child: Tooltip(
                            message: 'Starting leader',
                            child: Icon(
                              Icons.workspace_premium_outlined,
                              size: 18,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (draft.hasDuplicateNames) ...[
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 15,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: Space.xxs),
                      Expanded(
                        child: Text(
                          'Two players share the same name.',
                          style: AppText.caption.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          SectionHeader(
            title: 'Good characters',
            trailing: MetaPill(label: '$good / $requiredGood'),
          ),
          MedievalCard(
            child: Column(
              children: [
                _CharacterRow(
                  character: Character.merlin,
                  count: draft.composition.countOf(Character.merlin),
                  notifier: notifier,
                ),
                _CharacterRow(
                  character: Character.percival,
                  count: draft.composition.countOf(Character.percival),
                  notifier: notifier,
                ),
                _CharacterRow(
                  character: Character.loyalServant,
                  count: draft.composition.countOf(Character.loyalServant),
                  notifier: notifier,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          SectionHeader(
            title: 'Evil characters',
            trailing: MetaPill(label: '$evil / $requiredEvil'),
          ),
          MedievalCard(
            child: Column(
              children: [
                for (final character in Character.of(Allegiance.evil))
                  _CharacterRow(
                    character: character,
                    count: draft.composition.countOf(character),
                    notifier: notifier,
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          const SectionHeader(title: 'Quests'),
          MedievalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                const SizedBox(height: Space.sm),
                Text(
                  draft.playerCount >= 7
                      ? 'Quest 4 needs two fail cards in a game this size. '
                            'Every other quest needs one.'
                      : 'Every quest fails on a single fail card at this '
                            'player count.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            const SectionHeader(title: 'Before you start'),
            MedievalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final issue in issues) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          issue.isError
                              ? Icons.error_outline
                              : Icons.info_outline,
                          size: 15,
                          color: issue.isError
                              ? AppColors.danger
                              : AppColors.mutedGold,
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: Text(
                            issue.message,
                            style: AppText.caption.copyWith(
                              color: issue.isError
                                  ? AppColors.danger
                                  : AppColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get playerLabel {
    final count = ref.read(setupProvider).playerCount;
    return '$count players';
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label players',
      child: Material(
        color: selected ? AppColors.surfaceRaised : AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
          side: BorderSide(
            color: selected ? AppColors.gold : AppColors.divider,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.chip),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 44,
            child: Center(
              child: Text(
                label,
                style: AppText.numeral.copyWith(
                  fontSize: 15,
                  color: selected ? AppColors.gold : AppColors.parchment,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterRow extends StatelessWidget {
  const _CharacterRow({
    required this.character,
    required this.count,
    required this.notifier,
  });

  final Character character;
  final int count;
  final SetupController notifier;

  @override
  Widget build(BuildContext context) {
    final canDecrease = count > 0;
    final canIncrease = character.isUnique ? count == 0 : true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        children: [
          Icon(
            character.isGood
                ? Icons.shield_outlined
                : Icons.dark_mode_outlined,
            size: 16,
            color: character.isGood ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(character.label, style: AppText.body),
          ),
          _StepperButton(
            key: Key('setup_dec_${character.name}'),
            icon: Icons.remove,
            onPressed: canDecrease
                ? () => notifier.setCharacterCount(character, count - 1)
                : null,
          ),
          SizedBox(
            width: 34,
            child: Center(
              child: Text(
                '$count',
                style: AppText.numeral.copyWith(fontSize: 15),
              ),
            ),
          ),
          _StepperButton(
            key: Key('setup_inc_${character.name}'),
            icon: Icons.add,
            onPressed: canIncrease
                ? () => notifier.setCharacterCount(character, count + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: icon == Icons.add ? 'Add one' : 'Remove one',
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: AppColors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.chip),
            side: const BorderSide(color: AppColors.divider),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.chip),
            onTap: onPressed,
            child: Icon(
              icon,
              size: 17,
              color: enabled ? AppColors.gold : AppColors.mutedText.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
