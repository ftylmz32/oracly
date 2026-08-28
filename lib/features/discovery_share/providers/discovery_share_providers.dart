/// Riverpod wiring for the discovery share controller.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/discovery_share_card_png.dart';
import '../services/discovery_share_controller.dart';
import '../services/discovery_share_port.dart';
import '../services/system_discovery_share.dart';
import '../../share_reopen/providers/share_reopen_providers.dart';

final discoverySharePortProvider = Provider<DiscoverySharePort>(
  (ref) => const SystemDiscoveryShare(),
);

final discoveryShareRendererProvider = Provider<DiscoveryShareCardRenderer>(
  (ref) => const DiscoveryShareCardPng(),
);

final discoveryShareControllerProvider = Provider<DiscoveryShareController>(
  (ref) => DiscoveryShareController(
    port: ref.watch(discoverySharePortProvider),
    renderer: ref.watch(discoveryShareRendererProvider),
    references: ref.watch(shareReferenceIssuerProvider),
  ),
);
