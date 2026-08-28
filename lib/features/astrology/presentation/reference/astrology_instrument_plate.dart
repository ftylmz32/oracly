/// Illustrated brass-glass instrument plate under symbolic sky overlays.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';

class AstrologyInstrumentPlate extends StatelessWidget {
  const AstrologyInstrumentPlate({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OraclyChrome.midnight,
      child: OraclyAssetImage(
        assetPath: AppAssets.astrologyInstrumentPlate,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        fallback: const SizedBox.expand(),
      ),
    );
  }
}
