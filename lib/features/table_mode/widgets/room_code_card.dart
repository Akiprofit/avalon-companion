import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/medieval_card.dart';
import '../model/room_code.dart';

/// The six characters, grouped for reading aloud, at table size.
class RoomCodeCard extends StatelessWidget {
  const RoomCodeCard({super.key, required this.code, this.caption = 'Join code'});

  final String code;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return MedievalCard(
      showTopRule: true,
      borderColor: AppColors.gold.withValues(alpha: 0.35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption.toUpperCase(),
            style: AppText.caption.copyWith(
              color: AppColors.mutedGold,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: Space.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              RoomCode.grouped(code),
              style: AppText.display.copyWith(
                fontSize: 46,
                letterSpacing: 12,
                color: AppColors.parchment,
              ),
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Type these six characters, or scan the code.',
            style: AppText.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
