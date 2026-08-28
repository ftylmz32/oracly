/// Tarot revisit context from real history — hidden when resuming a session.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/experience/providers/continue_where_you_left_off_provider.dart';
import '../revisit/tarot_revisit_context.dart';
import '../revisit/tarot_revisit_service.dart';

final tarotRevisitProvider = Provider<TarotRevisitContext?>((ref) {
  final continueTarget = ref.watch(continueWhereYouLeftOffProvider).valueOrNull;
  if (continueTarget?.kind == ContinueWhereYouLeftOffKind.tarot) return null;
  final readings = ref.watch(readingHistoryProvider).valueOrNull ?? const [];
  return TarotRevisitService.fromHistory(readings);
});
