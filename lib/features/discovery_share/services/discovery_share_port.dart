/// OS share sheet port — never throws into UI.
library;

import 'dart:typed_data';

import '../models/shareable_discovery.dart';

enum DiscoveryShareOutcome { completed, canceled, unavailable }

abstract class DiscoverySharePort {
  Future<DiscoveryShareOutcome> share(DiscoveryShareRequest request);
}

abstract class DiscoveryShareCardRenderer {
  Future<Uint8List?> render(ShareableDiscovery discovery);
}

class UnavailableDiscoveryShare implements DiscoverySharePort {
  const UnavailableDiscoveryShare();

  @override
  Future<DiscoveryShareOutcome> share(DiscoveryShareRequest request) async {
    return DiscoveryShareOutcome.unavailable;
  }
}

class SilentDiscoveryShareCard implements DiscoveryShareCardRenderer {
  const SilentDiscoveryShareCard();

  @override
  Future<Uint8List?> render(ShareableDiscovery discovery) async => null;
}
