/// Subtle Paylaş control — present, never the primary ritual action.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../../../app/providers/app_providers.dart';
import '../copy/discovery_share_copy.dart';
import '../models/shareable_discovery.dart';
import '../providers/discovery_share_providers.dart';
import '../services/discovery_share_port.dart';

class DiscoveryShareAction extends ConsumerWidget {
  const DiscoveryShareAction({super.key, required this.discovery});

  final ShareableDiscovery discovery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Semantics(
        button: true,
        label: DiscoveryShareCopy.share,
        child: OraclyPressable(
          onTap: () => invokeDiscoveryShare(context, discovery),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.ios_share_rounded,
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

/// Canonical share entry — open/completed analytics once, metadata only.
Future<DiscoveryShareOutcome> invokeDiscoveryShare(
  BuildContext context,
  ShareableDiscovery discovery,
) async {
  final container = ProviderScope.containerOf(context);
  final analytics = container.read(analyticsServiceProvider);
  analytics.logShareOpened(kind: discovery.kind.name);
  final outcome = await container
      .read(discoveryShareControllerProvider)
      .share(discovery);
  analytics.logShareCompleted(
    kind: discovery.kind.name,
    outcome: outcome.name,
  );
  if (!context.mounted) return outcome;
  if (outcome == DiscoveryShareOutcome.unavailable) {
    OraclySnackBar.show(context, message: DiscoveryShareCopy.unavailable);
  }
  return outcome;
}
