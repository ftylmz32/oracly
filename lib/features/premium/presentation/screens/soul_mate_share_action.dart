/// Share — premium-gated, never leaks private form inputs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../discovery_share/copy/discovery_share_copy.dart';
import '../../../discovery_share/models/shareable_discovery.dart';
import '../../../discovery_share/widgets/discovery_share_action.dart';

class SoulMateShareAction extends ConsumerWidget {
  const SoulMateShareAction({
    super.key,
    required this.discovery,
    required this.enabled,
    required this.onLocked,
  });

  final ShareableDiscovery discovery;
  final bool enabled;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Semantics(
        button: true,
        label: DiscoveryShareCopy.share,
        child: OraclyPressable(
          onTap: () {
            if (!enabled) {
              onLocked();
              return;
            }
            invokeDiscoveryShare(context, discovery);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  enabled ? Icons.ios_share_rounded : Icons.lock_outline_rounded,
                  size: 16,
                  color: OraclyChrome.gold.withValues(alpha: 0.78),
                ),
                const SizedBox(width: 8),
                Text(
                  DiscoveryShareCopy.share,
                  style: ReadingTypography.sectionLabel(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.86),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
