import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/pin_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Asks for the MC PIN and unlocks the session when it is right.
///
/// Returns true straight away when no PIN is set, so callers do not have to
/// branch. A wrong PIN keeps the dialog open with the error inline; the MC can
/// close it and carry on with the match, which is exactly why aborting a match
/// also asks a second time before doing anything irreversible.
Future<bool> requestPin(
  BuildContext context,
  WidgetRef ref, {
  String title = 'Enter the MC PIN',
  String message =
      'Settings and match controls are protected on this device.',
  String confirmLabel = 'Unlock',
}) async {
  final pin = ref.read(pinProvider);
  if (!pin.enabled) return true;
  if (pin.unlocked) return true;

  final unlocked = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _PinPrompt(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    ),
  );
  return unlocked ?? false;
}

/// Asks for a new PIN twice and returns it, or null when cancelled.
Future<String?> requestNewPin(
  BuildContext context, {
  String title = 'Set the MC PIN',
  String message =
      'Four to eight digits. The app keeps only a salted hash, never the '
      'digits themselves.',
  String confirmLabel = 'Save PIN',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NewPinPrompt(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    ),
  );
}

class _PinPrompt extends ConsumerStatefulWidget {
  const _PinPrompt({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  ConsumerState<_PinPrompt> createState() => _PinPromptState();
}

class _PinPromptState extends ConsumerState<_PinPrompt> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (ref.read(pinProvider.notifier).submit(_controller.text)) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _error = 'That PIN is not right.');
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message, style: AppText.body),
            const SizedBox(height: Space.md),
            TextField(
              key: const Key('mc_pin_field'),
              controller: _controller,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'PIN',
                counterText: '',
                errorText: _error,
              ),
            ),
          ],
        ),
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
            PrimaryButton(label: widget.confirmLabel, onPressed: _submit),
            const SizedBox(height: Space.xs),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ],
    );
  }
}

class _NewPinPrompt extends StatefulWidget {
  const _NewPinPrompt({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  State<_NewPinPrompt> createState() => _NewPinPromptState();
}

class _NewPinPromptState extends State<_NewPinPrompt> {
  final _pin = TextEditingController();
  final _repeat = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pin.text;
    if (pin.length < 4) {
      setState(() => _error = 'Use at least four digits.');
      return;
    }
    if (pin != _repeat.text) {
      setState(() => _error = 'The two PINs do not match.');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message, style: AppText.body),
            const SizedBox(height: Space.md),
            TextField(
              key: const Key('mc_pin_new'),
              controller: _pin,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                counterText: '',
              ),
            ),
            TextField(
              key: const Key('mc_pin_repeat'),
              controller: _repeat,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Repeat PIN',
                counterText: '',
                errorText: _error,
                errorStyle: const TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
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
            PrimaryButton(label: widget.confirmLabel, onPressed: _submit),
            const SizedBox(height: Space.xs),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}
