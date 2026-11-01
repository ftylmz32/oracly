/// Privacy Control Center entry for UMP's privacy options. Invisible
/// unless the ads rollout is on AND UMP requires the entry point — with
/// the flag off the screen is exactly as before.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../premium/presentation/widgets/settings_tiles.dart';
import '../ads_rollout.dart';
import '../providers/ads_providers.dart';

class AdsPrivacyOptionsTile extends ConsumerWidget {
  const AdsPrivacyOptionsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AdsRollout.enabled) return const SizedBox.shrink();
    final gate = ref.watch(adsGateProvider);
    if (!gate.privacyOptionsRequired) return const SizedBox.shrink();
    return SettingsNavTile(
      icon: Icons.privacy_tip_outlined,
      title: OraclyL10n.t('ads.privacy_options.title'),
      subtitle: OraclyL10n.t('ads.privacy_options.subtitle'),
      onTap: () async {
        final shown = await gate.showPrivacyOptions();
        if (!shown && context.mounted) {
          OraclySnackBar.error(
            context,
            OraclyL10n.t('ads.privacy_options.failed'),
          );
        }
      },
    );
  }
}
