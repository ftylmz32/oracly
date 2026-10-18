import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Centered door title. Long labels break on a space before they meet the frame.
class EncounterInterestLabel extends StatelessWidget {
  const EncounterInterestLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.labelMedium.copyWith(
      color: AppColors.goldLight,
      fontSize: 12,
      height: 1.2,
      letterSpacing: 0.1,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final inner = constraints.maxWidth;
        final full = _width(label, style, scaler);
        final natural = full <= inner * 0.72 ? full : _twoLineWidth(label, style, scaler);
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: natural,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        );
      },
    );
  }
}

double _twoLineWidth(String label, TextStyle style, TextScaler scaler) {
  final words = label.split(' ');
  if (words.length < 2) return _width(label, style, scaler);
  var best = double.infinity;
  for (var i = 1; i < words.length; i++) {
    final left = _width(words.sublist(0, i).join(' '), style, scaler);
    final right = _width(words.sublist(i).join(' '), style, scaler);
    final need = left > right ? left : right;
    if (need < best) best = need;
  }
  return best + 2;
}

double _width(String text, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  return painter.width;
}
