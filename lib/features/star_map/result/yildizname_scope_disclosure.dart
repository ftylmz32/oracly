/// What the reading rests on — localized, evidence-derived, chrome only.
library;

import 'package:flutter/foundation.dart';

import 'yildizname_result_chrome.dart';
import 'yildizname_result_types.dart';
import 'yildizname_scope_resolver.dart';

@immutable
final class YildiznameScopeDisclosure {
  const YildiznameScopeDisclosure({
    required this.evidence,
    required this.kicker,
    required this.body,
  });

  /// Resolves display copy for [evidence] in [languageCode] (default: app).
  factory YildiznameScopeDisclosure.of(
    YildiznameResolvedScope evidence, {
    String? languageCode,
  }) {
    return YildiznameScopeDisclosure(
      evidence: evidence,
      kicker: YildiznameResultChrome.scopeKicker(languageCode),
      body: YildiznameResultChrome.scopeBody(evidence, languageCode),
    );
  }

  final YildiznameResolvedScope evidence;

  /// Short heading — the question the note answers.
  final String kicker;

  /// One or two calm sentences. Never lists a layer the evidence lacks.
  final String body;

  YildiznameResultScope get scope => evidence.scope;

  @override
  bool operator ==(Object other) =>
      other is YildiznameScopeDisclosure &&
      other.evidence == evidence &&
      other.kicker == kicker &&
      other.body == body;

  @override
  int get hashCode => Object.hash(evidence, kicker, body);
}
