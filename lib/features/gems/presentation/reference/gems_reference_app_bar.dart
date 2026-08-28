/// Mücevherler header — back · MÜCEVHERLER · live gem.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../copy/gems_copy.dart';
import '../../widgets/oracly_live_gem_capsule.dart';

class GemsReferenceAppBar extends StatelessWidget {
  const GemsReferenceAppBar({super.key, this.onBack});

  final VoidCallback? onBack;

  static String get title => GemsCopy.screenTitle;

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: title,
      onLeadingTap: onBack ?? () => Navigator.maybePop(context),
      trailing: const OraclyLiveGemCapsule(onTap: _ignoreGemTap),
    );
  }

  static void _ignoreGemTap() {}
}
