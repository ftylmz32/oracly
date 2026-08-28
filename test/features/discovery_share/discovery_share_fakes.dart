/// Shared fakes for discovery share tests.
library;

import 'package:oracly_new/features/discovery_share/models/shareable_discovery.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_port.dart';

class RecordingDiscoveryShare implements DiscoverySharePort {
  DiscoveryShareRequest? last;
  DiscoveryShareOutcome next = DiscoveryShareOutcome.completed;

  @override
  Future<DiscoveryShareOutcome> share(DiscoveryShareRequest request) async {
    last = request;
    return next;
  }
}

class ThrowingDiscoveryShare implements DiscoverySharePort {
  @override
  Future<DiscoveryShareOutcome> share(DiscoveryShareRequest request) {
    throw StateError('share unavailable');
  }
}
