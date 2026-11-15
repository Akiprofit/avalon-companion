import 'package:material_ui/material_ui.dart';

import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

/// One settings row inside a [MedievalCard].
///
/// Two shapes share the component so the settings screen has a single rhythm:
/// [SettingsTile.toggle] for a switch and [SettingsTile.slider] for a value
/// with a range. Both expose the same label hierarchy and divider behaviour.
class SettingsTile extends StatelessWidget {
  const SettingsTile._({
    super.key,
    required this.label,
    this.description,
    this.trailing,
    this.slider,
    this.last = false,
  });

  /// A labelled switch. [last] removes the trailing divider for the final row
  /// of a card.
  factory SettingsTile.toggle({
    Key? key,
    required String label,
    String? description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool last = false,
  }) {
    return SettingsTile._(
      key: key,
      label: label,
      description: description,
      last: last,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }

  /// A labelled range control, with the current value shown on the right.
  factory SettingsTile.slider({
    Key? key,
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SettingsTile._(
      key: key,
      label: label,
      last: true,
      slider: _SliderField(
        label: label,
        valueLabel: valueLabel,
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  final String label;
  final String? description;
  final Widget? trailing;
  final Widget? slider;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final slider = this.slider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (slider != null)
          slider
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.bodyStrong),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(description!, style: AppText.caption),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Space.sm),
                trailing!,
              ],
            ],
          ),
        if (!last && trailing != null) const Divider(height: Space.lg),
      ],
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppText.body)),
            Text(valueLabel, style: AppText.bodyStrong.copyWith(fontSize: 13)),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
