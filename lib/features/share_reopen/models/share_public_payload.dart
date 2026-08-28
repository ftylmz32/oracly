/// Public-safe share body — never private text, never auth claims.
library;

import '../../discovery_share/models/shareable_discovery.dart';
import '../../discovery_share/services/discovery_share_sanitize.dart';

class SharePublicPayload {
  const SharePublicPayload({
    required this.id,
    required this.kind,
    required this.highlight,
  });

  final String id;
  final DiscoveryShareKind kind;
  final String highlight;

  static const allowedKeys = {'i', 'k', 'h'};

  Map<String, dynamic> toPublicJson() => {
        'i': id,
        'k': kind.wire,
        'h': highlight,
      };

  static SharePublicPayload? fromJson(Map<String, dynamic> json) {
    final id = '${json['i']}'.trim();
    final kind = DiscoveryShareKind.fromWire('${json['k']}');
    if (id.isEmpty || kind == null) return null;
    if (id.length > 48) return null;
    var highlight = DiscoveryShareSanitize.highlight('${json['h']}');
    if (DiscoveryShareSanitize.leaksPrivate(highlight)) {
      highlight = DiscoveryShareSanitize.highlight('');
    }
    return SharePublicPayload(id: id, kind: kind, highlight: highlight);
  }
}
