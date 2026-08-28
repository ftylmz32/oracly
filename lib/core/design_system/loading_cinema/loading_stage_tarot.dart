/// Tarot wait — physical deck anticipation, never a spinner.
library;

import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../theme/oracly_quiet_motion.dart';
import '../oracly_chrome.dart';

class LoadingStageTarot extends StatefulWidget {
  const LoadingStageTarot({super.key, this.size = 168});

  final double size;

  @override
  State<LoadingStageTarot> createState() => _LoadingStageTarotState();
}

class _LoadingStageTarotState extends State<LoadingStageTarot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.5);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = _breath.value;
        final lift = -4.0 + t * 8.0;
        final glow = 0.12 + t * 0.10;
        return Transform.translate(
          offset: Offset(0, lift),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: OraclyChrome.heroRadius,
              boxShadow: [
                BoxShadow(
                  color: OraclyChrome.gold.withValues(alpha: glow),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: OraclyChrome.heroRadius,
        child: SizedBox(
          width: widget.size * 0.72,
          height: widget.size,
          child: OraclyAssetImage(
            assetPath: AppAssets.tarotHero,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            fallback: ColoredBox(
              color: OraclyChrome.midnight,
              child: Icon(
                Icons.style_outlined,
                color: OraclyChrome.gold.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
