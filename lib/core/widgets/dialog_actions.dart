import 'package:material_ui/material_ui.dart';

import '../theme/app_metrics.dart';
import 'danger_button.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// The action block at the foot of a dialog.
///
/// Dialogs used to end in bare `TextButton`s, which read as links next to the
/// gold buttons on every screen behind them, and in a row when the rest of the
/// app stacks its actions. One dominant action at the top, one way out under
/// it, both full width and both a thumb's width tall.
class DialogActions extends StatelessWidget {
  const DialogActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryKey,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryKey,
    this.isDestructive = false,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final Key? primaryKey;
  final IconData? primaryIcon;

  /// The quiet way out. Omitted when a dialog has only one answer.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Key? secondaryKey;

  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDestructive)
          DangerButton(
            key: primaryKey,
            label: primaryLabel,
            icon: primaryIcon,
            onPressed: onPrimary,
          )
        else
          PrimaryButton(
            key: primaryKey,
            label: primaryLabel,
            icon: primaryIcon,
            onPressed: onPrimary,
          ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: Space.xs),
          SecondaryButton(
            key: secondaryKey,
            label: secondaryLabel!,
            onPressed: onSecondary,
          ),
        ],
      ],
    );
  }
}

/// The padding every dialog puts around [DialogActions].
const dialogActionsPadding = EdgeInsets.fromLTRB(
  Space.md,
  0,
  Space.md,
  Space.md,
);
