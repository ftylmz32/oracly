/// Compact feature to OR handoff — never dumps full history.
library;

import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import 'or_discovery_handoff_quality.dart';

/// Pending reading context for the canonical OR screen.
abstract final class OrChatHandoffBuffer {
  OrChatHandoffBuffer._();

  static OracleReadingContext? _pending;

  static void offer(OracleReadingContext context) {
    _pending = context;
  }

  static OracleReadingContext? take() {
    final value = _pending;
    _pending = null;
    return value;
  }

  @visibleForTesting
  static void clear() => _pending = null;
}

/// Builds a short style/context line from a reading handoff.
abstract final class OrChatHandoff {
  OrChatHandoff._();

  static String compact(OracleReadingContext context) =>
      OrDiscoveryHandoffQuality.compact(context);

  /// Welcome when arriving from a discovery — context is already held.
  static String arrivalLine(OracleReadingContext context) {
    return switch (context.kind) {
      OracleReadingKind.tarot => OraclyL10n.t('or.handoff.arrive.tarot'),
      OracleReadingKind.coffee => OraclyL10n.t('or.handoff.arrive.coffee'),
      OracleReadingKind.astrology =>
        OraclyL10n.t('or.handoff.arrive.astrology'),
      OracleReadingKind.starMap || OracleReadingKind.birthChart =>
        OraclyL10n.t('or.handoff.arrive.star_map'),
      OracleReadingKind.palm => OraclyL10n.t('or.handoff.arrive.palm'),
      OracleReadingKind.dream => OraclyL10n.t('or.handoff.arrive.dream'),
      OracleReadingKind.dailyMessage => OraclyL10n.t('or.handoff.arrive.daily'),
      OracleReadingKind.soulMate => OraclyL10n.t('or.handoff.arrive.soulmate'),
      _ => OraclyL10n.t('or.handoff.arrive.generic'),
    };
  }
}
