/// Plain-text store diagnostics for the hidden support sheet.
///
/// Built ONLY from whitelisted typed fields of [StoreCatalogSnapshot] and
/// [StorePurchaseStreamEvent]; every free-text value passes through
/// [StoreDiagnosticsRedaction]. Never receipts, JWS, verification data,
/// purchase tokens, transaction payloads, identity, keys or issuer ids.
library;

import 'package:flutter/foundation.dart';

import '../models/store_catalog_snapshot.dart';
import 'store_diagnostics_redaction.dart';
import 'store_purchase_stream_diagnostics.dart';

abstract final class StoreDiagnosticsFormatter {
  StoreDiagnosticsFormatter._();

  static const maxIds = 8;
  static const maxIdLength = 64;
  static const notStamped = 'not-stamped';

  static const _version = String.fromEnvironment('ORACLY_APP_VERSION');
  static const _build = String.fromEnvironment('ORACLY_BUILD_NUMBER');

  static String format({
    required StoreCatalogSnapshot? catalog,
    required List<StorePurchaseStreamEvent> stream,
    String appVersion = _version,
    String buildNumber = _build,
    TargetPlatform? platform,
  }) {
    final lines = <String>[
      'ORACLY store diagnostics',
      'app: ${_stamp(appVersion)} (${_stamp(buildNumber)})',
      'platform: ${(platform ?? defaultTargetPlatform).name}',
      ..._catalog(catalog),
      'purchaseStream (${stream.length}):',
      if (stream.isEmpty) '  no events',
      for (final event in stream) '  ${_event(event)}',
    ];
    return lines.join('\n');
  }

  static List<String> _catalog(StoreCatalogSnapshot? s) {
    if (s == null) return const ['catalog: not checked yet'];
    return [
      'catalog @ ${_time(s.at)}:',
      '  storeAvailable: ${s.storeAvailable}',
      '  availabilityTimedOut: ${s.availabilityTimedOut}',
      '  availabilityException: ${_text(s.availabilityExceptionType)}',
      '  attempt: ${s.attempt}',
      '  requested: ${_ids(s.requestedIds)}',
      '  returned: ${_ids(s.returnedIds)}',
      '  notFound: ${_ids(s.notFoundIds)}',
      '  errorCode: ${_text(s.errorCode, maxLength: 64)}',
      '  errorMessage: ${_text(s.errorMessage)}',
      '  queryTimedOut: ${s.queryTimedOut}',
      '  queryException: ${_text(s.queryExceptionType)}',
    ];
  }

  static String _event(StorePurchaseStreamEvent e) {
    final parts = <String>[
      _time(e.at),
      e.kind.name,
      if (e.status != null) 'status=${_text(e.status, maxLength: 32)}',
      if (e.product != null) 'product=${_text(e.product, maxLength: 64)}',
      if (e.reason != null) 'reason=${_text(e.reason, maxLength: 48)}',
      if (e.errorType != null) 'error=${_text(e.errorType, maxLength: 64)}',
    ];
    return parts.join(' ');
  }

  static String _ids(List<String> ids) {
    if (ids.isEmpty) return '(none)';
    final shown = ids
        .take(maxIds)
        .map((id) => StoreDiagnosticsRedaction.scrub(id, maxLength: maxIdLength))
        .join(', ');
    final extra = ids.length - maxIds;
    return extra > 0 ? '$shown (+$extra more)' : shown;
  }

  static String _text(String? raw, {int maxLength = 160}) {
    if (raw == null || raw.trim().isEmpty) return 'none';
    return StoreDiagnosticsRedaction.scrub(raw, maxLength: maxLength);
  }

  /// Compile-time build stamps: version-safe characters only, capped.
  static String _stamp(String raw) {
    final safe = raw.replaceAll(RegExp(r'[^0-9A-Za-z.+\-_]'), '');
    if (safe.isEmpty) return notStamped;
    return safe.length > 32 ? safe.substring(0, 32) : safe;
  }

  static String _time(DateTime at) => at.toUtc().toIso8601String();
}
