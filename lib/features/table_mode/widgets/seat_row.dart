import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/avalon_icon_button.dart';
import '../../../core/widgets/status_indicator.dart';
import '../model/seat.dart';

/// One seat on the board: number, name, presence, and — for a phone that is not
/// coming back — the action that frees the seat.
///
/// Nothing here can show a character: [Seat] has none, and this widget imports
/// only [Seat].
class SeatRow extends StatelessWidget {
  const SeatRow({super.key, required this.seat, this.onRelease});

  final Seat seat;

  /// Null for a seat whose phone is present: a connected player is released by
  /// leaving, not by the MC.
  final VoidCallback? onRelease;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs + 2),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceRaised,
              border: Border.all(color: AppColors.divider),
            ),
            child: Text('${seat.number}', style: AppText.numeral),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              seat.name,
              style: AppText.bodyStrong,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusIndicator(
            label: seat.connected ? 'Connected' : 'Away',
            tone: seat.connected ? StatusTone.success : StatusTone.danger,
          ),
          if (onRelease != null)
            AvalonIconButton(
              icon: Icons.person_remove_outlined,
              semanticLabel: 'Release seat ${seat.number}',
              tooltip: 'Release seat',
              onPressed: onRelease,
            )
          else
            const SizedBox(width: Space.xxs),
        ],
      ),
    );
  }
}
