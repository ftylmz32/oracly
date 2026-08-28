/// OR wait — small breathing presence disk. Not a mascot spinner.
library;

import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../theme/oracly_quiet_motion.dart';
import '../oracly_chrome.dart';

class LoadingStageOr extends StatefulWidget {
  const LoadingStageOr({super.key, this.size = 48});

  final double size;

  @override
  State<LoadingStageOr> createState() => _LoadingStageOrState();
}

class _LoadingStageOrState extends State<LoadingStageOr>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.45);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = _breath.value;
        final scale = 0.94 + t * 0.06;
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: OraclyChrome.gold.withValues(alpha: 0.14 + t * 0.10),
                  blurRadius: 18,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: ClipOval(
        child: OraclyAssetImage(
          assetPath: AppAssets.heroOrbPremium,
          width: s,
          height: s,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          fallback: ColoredBox(
            color: OraclyChrome.midnight,
            child: Icon(
              Icons.circle_outlined,
              size: s * 0.4,
              color: OraclyChrome.gold.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
