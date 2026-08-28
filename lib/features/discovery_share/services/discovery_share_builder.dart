/// Builds public share cards from discovery highlights only.
library;

import 'dart:typed_data';

import '../copy/discovery_share_copy.dart';
import '../models/shareable_discovery.dart';
import 'discovery_share_sanitize.dart';

abstract final class DiscoveryShareBuilder {
  DiscoveryShareBuilder._();

  static ShareableDiscovery coffee({
    String? symbolName,
    String overall = '',
    Uint8List? cupImage,
  }) {
    return ShareableDiscovery(
      kind: DiscoveryShareKind.coffee,
      typeLabel: DiscoveryShareCopy.coffeeType,
      highlight: DiscoveryShareSanitize.highlight(symbolName ?? overall),
      visual: cupImage,
      subjectLabel: DiscoveryShareCopy.coffeeType,
    );
  }

  static ShareableDiscovery palm({
    String? theme,
    String? symbol,
    String overall = '',
  }) {
    return _of(
      kind: DiscoveryShareKind.palm,
      typeLabel: DiscoveryShareCopy.palmType,
      source: theme ?? symbol ?? overall,
      subjectLabel: DiscoveryShareCopy.palmType,
    );
  }

  static ShareableDiscovery tarot({
    String? theme,
    String cardName = '',
    String? cardAsset,
  }) {
    final name = cardName.trim();
    return ShareableDiscovery(
      kind: DiscoveryShareKind.tarot,
      typeLabel: DiscoveryShareCopy.tarotType,
      highlight: DiscoveryShareSanitize.highlight(
        theme ?? (name.isEmpty ? '' : name),
      ),
      visualAsset: cardAsset,
      subjectLabel: name.isEmpty ? null : name,
    );
  }

  static ShareableDiscovery astrology({
    String? innerTheme,
    String signName = '',
  }) {
    final sign = signName.trim();
    return ShareableDiscovery(
      kind: DiscoveryShareKind.astrology,
      typeLabel: DiscoveryShareCopy.astrologyType,
      highlight: DiscoveryShareSanitize.highlight(
        innerTheme ?? (sign.isEmpty ? '' : sign),
      ),
      subjectLabel: sign.isEmpty ? null : sign,
    );
  }

  static ShareableDiscovery starMap({String highlight = ''}) {
    return _of(
      kind: DiscoveryShareKind.starMap,
      typeLabel: DiscoveryShareCopy.starMapType,
      source: highlight,
      subjectLabel: DiscoveryShareCopy.starMapType,
    );
  }

  static ShareableDiscovery soulMate({
    required List<int> portrait,
    required String interpretation,
    String? name,
  }) {
    final highlight = DiscoveryShareSanitize.highlight(
      interpretation,
      denylist: [?name],
      fallback: DiscoveryShareCopy.soulMateHighlight,
    );
    return ShareableDiscovery(
      kind: DiscoveryShareKind.soulMate,
      typeLabel: DiscoveryShareCopy.soulMateType,
      highlight: highlight,
      visual: portrait.isEmpty ? null : Uint8List.fromList(portrait),
      subjectLabel: DiscoveryShareCopy.soulMateType,
    );
  }

  static ShareableDiscovery dailyInsight({String highlight = ''}) {
    return _of(
      kind: DiscoveryShareKind.dailyInsight,
      typeLabel: DiscoveryShareCopy.dailyType,
      source: highlight,
      subjectLabel: DiscoveryShareCopy.dailyType,
    );
  }

  static ShareableDiscovery _of({
    required DiscoveryShareKind kind,
    required String typeLabel,
    required String source,
    String? subjectLabel,
  }) {
    return ShareableDiscovery(
      kind: kind,
      typeLabel: typeLabel,
      highlight: DiscoveryShareSanitize.highlight(source),
      subjectLabel: subjectLabel,
    );
  }
}
