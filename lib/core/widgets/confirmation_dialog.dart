import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Destructive confirmation. The confirm label is an explicit verb and the message
/// restates the consequence — `avalon-ui-system` copy rules.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.isDestructive = true,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(message, style: AppText.body),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        Space.md,
        0,
        Space.md,
        Space.md,
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDestructive)
              SizedBox(
                height: 52,
                child: Material(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(Radii.input),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.input),
                    onTap: () => Navigator.of(context).pop(true),
                    child: Center(
                      child: Text(
                        confirmLabel,
                        style: AppText.button.copyWith(
                          color: AppColors.parchment,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              PrimaryButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            const SizedBox(height: Space.xs),
            SecondaryButton(
              label: cancelLabel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows [ConfirmationDialog] and resolves to the MC's choice. Defaults to false.
Future<bool> showConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !isDestructive,
    builder: (_) => ConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );
  return result ?? false;
}
