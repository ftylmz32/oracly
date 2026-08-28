/// Subtle gold focus marks — only when [CoffeeSymbolFocus] is reliable.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../models/coffee_symbol.dart';
import '../../models/coffee_symbol_focus.dart';

class CoffeeGroundedMark {
  const CoffeeGroundedMark({
    required this.index,
    required this.focus,
    required this.label,
  });

  final int index;
  final CoffeeSymbolFocus focus;
  final String label;
}

abstract final class CoffeeGroundedMarks {
  CoffeeGroundedMarks._();

  /// Firm symbols with real coords only — never invents positions.
  static List<CoffeeGroundedMark> from(List<CoffeeSymbol> symbols) {
    final out = <CoffeeGroundedMark>[];
    for (final symbol in symbols) {
      final focus = symbol.focus;
      if (!symbol.trust.isFirm || focus == null || !focus.isReliable) {
        continue;
      }
      final name = symbol.name.trim();
      if (name.isEmpty) continue;
      out.add(
        CoffeeGroundedMark(
          index: out.length + 1,
          focus: focus,
          label: name,
        ),
      );
      if (out.length >= 5) break;
    }
    return out;
  }
}

class CoffeeResultMarkerLayer extends StatelessWidget {
  const CoffeeResultMarkerLayer({
    super.key,
    required this.marks,
    this.onTap,
  });

  final List<CoffeeGroundedMark> marks;
  final ValueChanged<CoffeeGroundedMark>? onTap;

  @override
  Widget build(BuildContext context) {
    if (marks.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            for (final mark in marks)
              Positioned(
                left: mark.focus.x * w,
                top: mark.focus.y * h,
                width: mark.focus.w * w,
                height: mark.focus.h * h,
                child: Semantics(
                  button: onTap != null,
                  label: '${mark.index}. ${mark.label}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap == null ? null : () => onTap!(mark),
                    child: CustomPaint(
                      painter: _MarkerPainter(index: mark.index),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter({required this.index});

  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = OraclyChrome.gold.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.68),
    );
    final badge = Rect.fromLTWH(rect.left - 1, rect.top - 1, 17, 17);
    canvas.drawCircle(
      badge.center,
      8,
      Paint()..color = OraclyChrome.midnight.withValues(alpha: 0.86),
    );
    canvas.drawCircle(
      badge.center,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95
        ..color = OraclyChrome.gold.withValues(alpha: 0.78),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '$index',
        style: TextStyle(
          color: OraclyChrome.cream.withValues(alpha: 0.92),
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(badge.center.dx - tp.width / 2, badge.center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MarkerPainter oldDelegate) =>
      oldDelegate.index != index;
}
