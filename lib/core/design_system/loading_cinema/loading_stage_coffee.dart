/// Coffee wait — ritual cup atmosphere when no live photo path.
library;

import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../theme/oracly_quiet_motion.dart';
import '../oracly_chrome.dart';

class LoadingStageCoffee extends StatefulWidget {
  const LoadingStageCoffee({super.key, this.size = 168});

  final double size;

  @override
  State<LoadingStageCoffee> createState() => _LoadingStageCoffeeState();
}

class _LoadingStageCoffeeState extends State<LoadingStageCoffee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
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
    final s = widget.size;
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = _breath.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: OraclyChrome.heroRadius,
            boxShadow: [
              BoxShadow(
                color: OraclyChrome.gold.withValues(alpha: 0.10 + t * 0.12),
                blurRadius: 28,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: OraclyChrome.heroRadius,
        child: SizedBox(
          width: s,
          height: s * 0.72,
          child: OraclyAssetImage(
            assetPath: AppAssets.coffeeRitualHero,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            fallback: ColoredBox(color: OraclyChrome.midnight),
          ),
        ),
      ),
    );
  }
}
