/// Prepares a sanitized card, then hands it to the share port.
library;

import 'dart:typed_data';

import '../copy/discovery_share_copy.dart';
import '../models/shareable_discovery.dart';
import 'discovery_share_port.dart';
import 'discovery_share_sanitize.dart';
import '../../share_reopen/services/issued_share_reference.dart';
import '../../share_reopen/services/share_reference_issuer.dart';

class DiscoveryShareController {
  const DiscoveryShareController({
    required this.port,
    this.renderer = const SilentDiscoveryShareCard(),
    this.references,
  });

  final DiscoverySharePort port;
  final DiscoveryShareCardRenderer renderer;
  final ShareReferenceIssuer? references;

  ShareableDiscovery prepare(ShareableDiscovery discovery) {
    var highlight = DiscoveryShareSanitize.highlight(discovery.highlight);
    if (DiscoveryShareSanitize.leaksPrivate(highlight) ||
        DiscoveryShareSanitize.leaksPrivate(discovery.caption)) {
      highlight = discovery.kind == DiscoveryShareKind.soulMate
          ? DiscoveryShareCopy.soulMateHighlight
          : DiscoveryShareCopy.fallbackHighlight;
    }
    return ShareableDiscovery(
      kind: discovery.kind,
      typeLabel: discovery.typeLabel,
      highlight: highlight,
      visual: discovery.visual,
      visualAsset: discovery.visualAsset,
      subjectLabel: discovery.subjectLabel,
    );
  }

  Future<DiscoveryShareOutcome> share(ShareableDiscovery discovery) async {
    final clean = prepare(discovery);
    Uint8List? image;
    try {
      image = await renderer.render(clean);
    } catch (_) {
      image = clean.visual;
    }
    image ??= clean.visual;
    var caption = clean.caption;
    IssuedShareReference? issued;
    final issuer = references;
    if (issuer != null) {
      try {
        issued = await issuer.issue(clean);
        caption = '$caption\n\n${issued.uri}';
      } catch (_) {}
    }
    try {
      final outcome = await port.share(
        DiscoveryShareRequest(caption: caption, imageBytes: image),
      );
      if (outcome == DiscoveryShareOutcome.completed &&
          issued != null &&
          issuer != null) {
        try {
          await issuer.bind(issued);
        } catch (_) {}
      }
      return outcome;
    } catch (_) {
      return DiscoveryShareOutcome.unavailable;
    }
  }
}
