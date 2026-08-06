import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GreetingMoonPhase extends StatefulWidget {
  const GreetingMoonPhase({super.key, this.size = 28});
  final double size;

  @override
  State<GreetingMoonPhase> createState() => _GreetingMoonPhaseState();
}

class _GreetingMoonPhaseState extends State<GreetingMoonPhase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 14200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(DateTime date) {
    var y = date.year;
    var m = date.month;
    if (m < 3) {
      y--;
      m += 12;
    }
    final c = 365.25 * y + 30.6 * (m + 1) + date.day - 694039.09;
    return (c / 29.5305882) - (c / 29.5305882).floorToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = .08 + (_pulse.value * .035);
        return Container(
          width: widget.size + 8,
          height: widget.size + 8,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: glow),
                blurRadius: 10 + (_pulse.value * 4),
              ),
            ],
          ),
          child: Transform.scale(
            scale: .985 + (_pulse.value * .022),
            child: child,
          ),
        );
      },
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _MoonPhasePainter(phase: _phase(DateTime.now())),
      ),
    );
  }
}

class GreetingProfileButton extends StatelessWidget {
  const GreetingProfileButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 22,
                color: AppColors.gold.withValues(alpha: .85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoonPhasePainter extends CustomPainter {
  const _MoonPhasePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = AppColors.gold.withValues(alpha: .88));
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(
      c + Offset(math.cos(phase * 2 * math.pi) * r * .88, 0),
      r * .96,
      Paint()..color = AppColors.surfaceDark.withValues(alpha: .95),
    );
    canvas.restore();
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.gold.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
  }

  @override
  bool shouldRepaint(covariant _MoonPhasePainter old) => old.phase != phase;
}
