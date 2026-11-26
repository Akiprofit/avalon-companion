import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/avalon_screen.dart';
import '../../../core/widgets/medieval_card.dart';
import '../protocol/table_invite.dart';
import '../table_mode_providers.dart';

/// Screen — the camera, looking for the board's QR.
///
/// It returns the payload through `Navigator.pop`; the join screen parses it.
/// The camera itself comes from [tableScannerBuilderProvider], so a widget test
/// drives this screen without ever constructing a camera.
class JoinScanScreen extends ConsumerStatefulWidget {
  const JoinScanScreen({super.key});

  @override
  ConsumerState<JoinScanScreen> createState() => _JoinScanScreenState();
}

class _JoinScanScreenState extends ConsumerState<JoinScanScreen> {
  bool _handled = false;
  bool _foreignCode = false;

  void _onDetected(String raw) {
    if (_handled) return;
    final invite = TableInvite.parse(raw);
    if (invite == null) {
      // Not ours: keep looking, and say so quietly. A menu QR should not end
      // the scan with an error.
      if (!_foreignCode) setState(() => _foreignCode = true);
      return;
    }
    _handled = true;
    context.pop(invite.encode());
  }

  @override
  Widget build(BuildContext context) {
    final buildScanner = ref.watch(tableScannerBuilderProvider);

    return AvalonScreen(
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Point the camera at the board',
            style: AppText.screenTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xs),
          Text(
            'The code fills itself in. Nothing is uploaded; the camera is read '
            'on this phone.',
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.lg),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.card),
              child: ColoredBox(
                color: AppColors.backgroundSecondary,
                child: buildScanner(context, _onDetected),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          MedievalCard(
            child: Text(
              _foreignCode
                  ? 'That is not an Avalon board. Keep looking, or type the '
                        'six-character code instead.'
                  : 'Dim room? The board also prints the six characters, and '
                        'you can type them on the join screen.',
              style: AppText.caption.copyWith(
                color: _foreignCode ? AppColors.danger : AppColors.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
