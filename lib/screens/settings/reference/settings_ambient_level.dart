/// Atmospheric music level — live while dragging, saved on release.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/design_system/app_colors.dart';

class SettingsAmbientLevel extends ConsumerStatefulWidget {
  const SettingsAmbientLevel({
    super.key,
    required this.level,
    required this.label,
    required this.onCommit,
  });

  final double level;
  final String label;
  final ValueChanged<double> onCommit;

  static const min = 0.1;

  @override
  ConsumerState<SettingsAmbientLevel> createState() =>
      _SettingsAmbientLevelState();
}

class _SettingsAmbientLevelState extends ConsumerState<SettingsAmbientLevel> {
  late double _value = _clamp(widget.level);

  static double _clamp(double v) =>
      v.clamp(SettingsAmbientLevel.min, 1.0).toDouble();

  @override
  void didUpdateWidget(SettingsAmbientLevel old) {
    super.didUpdateWidget(old);
    if (old.level != widget.level) _value = _clamp(widget.level);
  }

  void _preview(double v) {
    setState(() => _value = v);
    ref.read(oraclySoundServiceProvider).setAmbientLevel(v);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final quiet = palette.goldLight.withValues(alpha: 0.62);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          Icon(Icons.volume_down_rounded, size: 20, color: quiet),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                activeTrackColor: palette.gold.withValues(alpha: 0.86),
                inactiveTrackColor: palette.gold.withValues(alpha: 0.18),
                thumbColor: palette.goldLight,
                overlayColor: palette.gold.withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                key: const ValueKey('settings-ambient-level'),
                value: _value,
                min: SettingsAmbientLevel.min,
                divisions: 18,
                semanticFormatterCallback: (v) =>
                    '${widget.label} ${(v * 100).round()}%',
                onChanged: _preview,
                onChangeEnd: widget.onCommit,
              ),
            ),
          ),
          Icon(Icons.volume_up_rounded, size: 20, color: quiet),
        ],
      ),
    );
  }
}
