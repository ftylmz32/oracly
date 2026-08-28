/// Reference settings app bar — back · AYARLAR · crystal capsule.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_app_bar.dart';
import '../../../core/l10n/l10n.dart';
import '../../../features/gems/widgets/oracly_live_gem_capsule.dart';

class SettingsReferenceAppBar extends StatelessWidget {
  const SettingsReferenceAppBar({
    super.key,
    this.onBack,
    this.title,
    this.backLabel,
  });

  final VoidCallback? onBack;
  final String? title;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    return OraclyAppBar(
      title: title ?? OraclyL10n.t(L10nKeys.settingsTitle),
      leadingLabel: backLabel ?? OraclyL10n.t(L10nKeys.back),
      onLeadingTap: onBack ?? () => Navigator.maybePop(context),
      trailing: const OraclyLiveGemCapsule(),
    );
  }
}
