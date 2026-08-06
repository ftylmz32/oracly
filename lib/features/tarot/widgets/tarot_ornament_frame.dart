import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

/// Gold corner ornaments for interpretation panel (reference).
class TarotOrnamentFrame extends StatelessWidget {
  const TarotOrnamentFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 0.8),
            boxShadow: AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: child,
          ),
        ),
        ..._corners(),
      ],
    );
  }

  List<Widget> _corners() {
    return [
      _corner(const Alignment(-1, -1)),
      _corner(const Alignment(1, -1), flip: true),
      _corner(const Alignment(-1, 1), flipY: true),
      _corner(const Alignment(1, 1), flip: true, flipY: true),
    ];
  }

  Widget _corner(Alignment a, {bool flip = false, bool flipY = false}) {
    return Align(
      alignment: a,
      child: Transform.flip(
        flipX: flip,
        flipY: flipY,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.gold.withValues(alpha: 0.6), width: 1),
              left: BorderSide(color: AppColors.gold.withValues(alpha: 0.6), width: 1),
            ),
          ),
        ),
      ),
    );
  }
}
