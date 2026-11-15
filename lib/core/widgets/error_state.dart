import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';
import 'secondary_button.dart';

/// Plain-language failure with a recovery action.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: AppColors.danger),
            const SizedBox(height: Space.md),
            Text(title, style: AppText.screenTitle, textAlign: TextAlign.center),
            const SizedBox(height: Space.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Space.lg),
              SizedBox(
                width: 200,
                child: SecondaryButton(label: retryLabel, onPressed: onRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
