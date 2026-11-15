import 'package:material_ui/material_ui.dart';

import '../../game_engine/models/quest_slot.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

/// Five quest markers — success/fail/current/pending, icon + colour, never colour alone.
class QuestTracker extends StatelessWidget {
  const QuestTracker({
    super.key,
    required this.slots,
    this.currentIndex,
  });

  /// Always five entries, quest 1 to 5.
  final List<QuestSlot> slots;
  final int? currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) const SizedBox(width: Space.xs),
          Expanded(child: _QuestCell(number: i + 1, slot: slots[i])),
        ],
      ],
    );
  }
}

class _QuestCell extends StatelessWidget {
  const _QuestCell({required this.number, required this.slot});

  final int number;
  final QuestSlot slot;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (slot) {
      QuestSlot.success => (AppColors.success, Icons.check_rounded, 'won'),
      QuestSlot.fail => (AppColors.danger, Icons.close_rounded, 'lost'),
      QuestSlot.current => (AppColors.gold, Icons.local_fire_department_outlined, 'current'),
      QuestSlot.pending => (AppColors.mutedText, Icons.remove_rounded, 'pending'),
    };

    return Semantics(
      label: 'Quest $number, $label',
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: slot == QuestSlot.current
              ? AppColors.surfaceRaised
              : AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(
            color: slot == QuestSlot.current ? AppColors.gold : AppColors.divider,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: Space.xxs),
            Text(
              '$number',
              style: AppText.numeral.copyWith(fontSize: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
