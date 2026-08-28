/// Riverpod wiring for soul-mate draw port.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/production/oracly_ai_providers.dart';
import '../services/proxy_soul_mate_draw.dart';
import '../services/soul_mate_draw_port.dart';
import '../services/unavailable_soul_mate_draw.dart';

final soulMateDrawPortProvider = Provider<SoulMateDrawPort>((ref) {
  final config = ref.watch(aiRuntimeConfigProvider);
  final transport = ref.watch(aiTransportProvider);
  if (transport == null || !config.usesProxy) {
    return const UnavailableSoulMateDraw();
  }
  return ProxySoulMateDraw(transport: transport);
});
