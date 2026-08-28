/// Yıldızname wait — quiet archive atmosphere, never natal math.
library;

import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../theme/oracly_quiet_motion.dart';

class LoadingStageYildizname extends StatefulWidget {
  const LoadingStageYildizname({super.key, this.size = 176});

  final double size;

  @override
  State<LoadingStageYildizname> createState() => _LoadingStageYildiznameState();
}

class _LoadingStageYildiznameState extends State<LoadingStageYildizname>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  static const _brass = Color(0xFFD4A86A);
  static const _candle = Color(0xFFC4A574);
  static const _ink = Color(0xFF07040F);

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _drift, reverse: true, rest: 0.48);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.size;
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        final t = _drift.value;
        return SizedBox(
          width: d,
          height: d,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _candle.withValues(alpha: 0.16 + t * 0.10),
                      blurRadius: 30,
                    ),
                    BoxShadow(
                      color: const Color(0xFF1A0A2E).withValues(
                        alpha: 0.20 + t * 0.08,
                      ),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: child,
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _brass.withValues(alpha: 0.28 + t * 0.10),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _brass.withValues(alpha: 0.14 + t * 0.06),
                        width: 0.65,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: ClipOval(
        child: OraclyAssetImage(
          assetPath: AppAssets.yildiznameHero,
          width: d,
          height: d,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          fallback: const ColoredBox(color: _ink),
        ),
      ),
    );
  }
}
