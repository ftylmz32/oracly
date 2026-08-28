/// One contextual cross-feature line — tap only when evidence supports it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../../../features/personal_discovery/providers/personal_discovery_providers.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../models/session_continuation.dart';
import '../services/session_continuation_engine.dart';
import '../services/session_continuation_opener.dart';

class SessionContinuationLink extends ConsumerWidget {
  const SessionContinuationLink({
    super.key,
    required this.source,
    this.sessionThemes = const [],
    this.orAlreadyOffered = false,
    this.oracleContext,
  });

  final SessionContinuationSource source;
  final List<String> sessionThemes;
  final bool orAlreadyOffered;
  final OracleReadingContext? oracleContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(personalDiscoveryProfileProvider).valueOrNull ??
            PersonalDiscoveryProfile.empty;
    final item = SessionContinuationEngine.decide(
      from: source,
      profile: profile,
      sessionThemes: sessionThemes,
      orAlreadyOffered: orAlreadyOffered,
    );
    if (item == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8, bottom: AppSpacing.s8),
      child: Semantics(
        button: true,
        label: item.line,
        child: OraclyPressable(
          onTap: () => SessionContinuationOpener.open(
            context,
            item,
            storage: ref.read(localStorageProvider),
            oracleContext: oracleContext,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                item.line,
                textAlign: TextAlign.center,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
