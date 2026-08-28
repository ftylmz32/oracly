/// Astrology wait — observatory instrument plate + celestial aura.
library;

import 'package:flutter/material.dart';

import '../../../shared/widgets/oracly_asset_image.dart';
import '../../constants/app_assets.dart';
import '../oracly_chrome.dart';
import 'loading_stage_astrology_aura.dart';

class LoadingStageAstrology extends StatelessWidget {
  const LoadingStageAstrology({super.key, this.size = 168});

  final double size;

  @override
  Widget build(BuildContext context) {
    final d = size;
    return LoadingStageAstrologyAura(
      child: ClipOval(
        child: OraclyAssetImage(
          assetPath: AppAssets.astrologyInstrumentPlate,
          width: d,
          height: d,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          fallback: ColoredBox(color: OraclyChrome.midnight),
        ),
      ),
    );
  }
}
