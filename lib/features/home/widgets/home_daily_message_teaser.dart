/// Compact Home Today teaser - existing Daily Message loop, not a second card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../../daily_message/copy/daily_message_copy.dart';
import '../../daily_message/data/daily_return_store.dart';
import '../../daily_message/models/daily_message.dart';
import '../../daily_message/services/daily_message_session.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../premium/models/personalization_models.dart';

/// Thin teaser under Today ritual - opens Daily Message.
class HomeDailyMessageTeaser extends ConsumerStatefulWidget {
  const HomeDailyMessageTeaser({super.key});

  @override
  ConsumerState<HomeDailyMessageTeaser> createState() =>
      _HomeDailyMessageTeaserState();
}

class _HomeDailyMessageTeaserState
    extends ConsumerState<HomeDailyMessageTeaser> {
  bool _recorded = false;

  DailyMessage? _resolveOrNull({
    required String? profileName,
    required PersonalDiscoveryProfile? discovery,
    required AiPersonality? personality,
  }) {
    try {
      final storage = ref.read(localStorageProvider);
      return DailyMessageSession.resolve(
        store: DailyReturnStore(storage),
        day: DateTime.now(),
        profileName: profileName,
        discovery: discovery,
        recent: ref.read(discoverySurfaceMemoryProvider).all(),
        personality: personality,
      );
    } catch (_) {
      return null;
    }
  }

  void _persistOnce(DailyMessage message) {
    if (_recorded) return;
    _recorded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final storage = ref.read(localStorageProvider);
        DailyMessageSession.persist(
          store: DailyReturnStore(storage),
          memory: ref.read(discoverySurfaceMemoryProvider),
          message: message,
        );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final discoveryAsync = ref.watch(personalDiscoveryProfileProvider);
    if (profileAsync.isLoading ||
        settingsAsync.isLoading ||
        discoveryAsync.isLoading ||
        profileAsync.hasError ||
        settingsAsync.hasError ||
        discoveryAsync.hasError) {
      return const SizedBox.shrink();
    }
    final message = _resolveOrNull(
      profileName: profileAsync.valueOrNull?.name,
      discovery: discoveryAsync.valueOrNull,
      personality: settingsAsync.valueOrNull?.aiPersonality,
    );
    final text = message?.text.trim() ?? '';
    if (message == null || text.isEmpty) {
      return const SizedBox.shrink();
    }
    _persistOnce(message);

    return Semantics(
      button: true,
      label: '${DailyMessageCopy.prompt}. $text',
      child: OraclyPressable(
        onTap: () => OraclyNavigationService.openDailyMessage(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DailyMessageCopy.prompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          ReadingTypography.eyebrow(
                            color: OraclyChrome.goldLight.withValues(
                              alpha: 0.90,
                            ),
                            fontSize: 11,
                          ).copyWith(
                            letterSpacing:
                                CraftsmanshipRhythm.sectionLabelTracking + 0.2,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.bodyCore(
                  color: OraclyChrome.cream.withValues(alpha: 0.88),
                ).copyWith(fontSize: 13.5, height: 1.38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
