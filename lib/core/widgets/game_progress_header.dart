import 'package:material_ui/material_ui.dart';

import '../../game_engine/models/quest_slot.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';
import 'status_indicator.dart';

/// Live game summary strip shown on every in-game screen.
class GameProgressHeader extends StatelessWidget {
  const GameProgressHeader({
    super.key,
    required this.leaderName,
    required this.questNumber,
    required this.requiredTeamSize,
    required this.rejectionCount,
    required this.phaseLabel,
    this.phaseTone = StatusTone.active,
    this.questSlots = const [
      QuestSlot.current,
      QuestSlot.pending,
      QuestSlot.pending,
      QuestSlot.pending,
      QuestSlot.pending,
    ],
  });

  final String leaderName;
  final int questNumber;
  final int requiredTeamSize;
  final int rejectionCount;
  final String phaseLabel;

  /// Tone of the phase chip: danger while the match is paused.
  final StatusTone phaseTone;
  final List<QuestSlot> questSlots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, Space.sm),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: StatusIndicator(
                  label: phaseLabel,
                  tone: phaseTone,
                ),
              ),
              const SizedBox(width: Space.xs),
              Text(
                'QUEST $questNumber / 5',
                style: AppText.caption.copyWith(
                  color: AppColors.gold,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _Stat(
                  label: 'LEADER',
                  value: leaderName,
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
              const SizedBox(width: Space.xs),
              _Stat(
                label: 'TEAM',
                value: '$requiredTeamSize',
                icon: Icons.groups_2_outlined,
              ),
              const SizedBox(width: Space.xs),
              _Stat(
                label: 'REJECTED',
                value: '$rejectionCount/5',
                icon: Icons.block_outlined,
                tone: rejectionCount >= 4 ? AppColors.danger : null,
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              for (var i = 0; i < questSlots.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _QuestDot(slot: questSlots[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: tone ?? AppColors.mutedText),
        const SizedBox(width: Space.xxs),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppText.caption.copyWith(fontSize: 9.5)),
              Text(
                value,
                style: AppText.bodyStrong.copyWith(
                  fontSize: 13,
                  color: tone ?? AppColors.parchment,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestDot extends StatelessWidget {
  const _QuestDot({required this.slot});

  final QuestSlot slot;

  @override
  Widget build(BuildContext context) {
    final color = switch (slot) {
      QuestSlot.success => AppColors.success,
      QuestSlot.fail => AppColors.danger,
      QuestSlot.current => AppColors.gold,
      QuestSlot.pending => AppColors.divider,
    };
    return Semantics(
      label: 'quest ${slot.name}',
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
