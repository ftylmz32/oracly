/// Gold archival spine — ties real entries into one timeline, not a table.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class DiscoveryJournalSpine extends StatelessWidget {
  const DiscoveryJournalSpine({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  final bool isFirst;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: CustomPaint(
              painter: _SpinePainter(isFirst: isFirst, isLast: isLast),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SpinePainter extends CustomPainter {
  const _SpinePainter({required this.isFirst, required this.isLast});

  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    const nodeY = 22.0;
    final line = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          OraclyChrome.gold.withValues(alpha: isFirst ? 0.08 : 0.38),
          OraclyChrome.goldLight.withValues(alpha: 0.55),
          OraclyChrome.gold.withValues(alpha: isLast ? 0.08 : 0.28),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(x, isFirst ? nodeY : 0),
      Offset(x, isLast ? nodeY : size.height),
      line,
    );
    // Diamond node — archive fragment mark, not a UI bullet.
    final c = Offset(x, nodeY);
    final path = Path()
      ..moveTo(c.dx, c.dy - 3.6)
      ..lineTo(c.dx + 3.2, c.dy)
      ..lineTo(c.dx, c.dy + 3.6)
      ..lineTo(c.dx - 3.2, c.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = OraclyChrome.goldLight.withValues(alpha: 0.90),
    );
    canvas.drawCircle(
      c,
      1.1,
      Paint()..color = OraclyChrome.midnight.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_SpinePainter old) =>
      old.isFirst != isFirst || old.isLast != isLast;
}
