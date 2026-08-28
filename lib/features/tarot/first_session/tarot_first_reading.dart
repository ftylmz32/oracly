/// RC-012 — Shared first-reading spread for onboarding and tarot CTAs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/first_session/first_session_intent.dart';
import '../../../core/first_session/first_session_scope.dart';
import '../domain/models/tarot_spread.dart';
import '../shared/tarot_scope.dart';

abstract final class TarotFirstReading {
  TarotFirstReading._();

  static const spread = TarotSpreadType.single;

  static bool shouldUseFirstSpread(BuildContext context, WidgetRef ref) {
    if (FirstSessionScope.of(context)) return true;
    return FirstSessionIntent.isPending(ref.read(localStorageProvider));
  }

  static Future<void> applySpread(WidgetRef ref, BuildContext context) async {
    final scope = TarotScope.maybeOf(context);
    scope?.flow.selectSpread(spread);
    ref.read(selectedSpreadProvider.notifier).state = spread.label;
    await ref.read(tarotServiceProvider).selectSpread(spread.label);
  }
}
