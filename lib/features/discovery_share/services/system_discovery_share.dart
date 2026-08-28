/// System share sheet — fail closed if the OS cannot share.
library;

import 'package:share_plus/share_plus.dart';

import '../models/shareable_discovery.dart';
import 'discovery_share_port.dart';

class SystemDiscoveryShare implements DiscoverySharePort {
  const SystemDiscoveryShare();

  @override
  Future<DiscoveryShareOutcome> share(DiscoveryShareRequest request) async {
    try {
      return await _share(request);
    } catch (_) {
      try {
        return await _share(DiscoveryShareRequest(caption: request.caption));
      } catch (_) {
        return DiscoveryShareOutcome.unavailable;
      }
    }
  }

  Future<DiscoveryShareOutcome> _share(DiscoveryShareRequest request) async {
    final bytes = request.imageBytes;
    final result = await SharePlus.instance.share(
      ShareParams(
        text: request.caption,
        files: bytes == null || bytes.isEmpty
            ? null
            : [
                XFile.fromData(
                  bytes,
                  mimeType: 'image/png',
                  name: 'oracly.png',
                ),
              ],
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => DiscoveryShareOutcome.completed,
      ShareResultStatus.dismissed => DiscoveryShareOutcome.canceled,
      ShareResultStatus.unavailable => DiscoveryShareOutcome.unavailable,
    };
  }
}
