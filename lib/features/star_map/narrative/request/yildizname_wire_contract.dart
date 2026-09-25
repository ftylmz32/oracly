/// Proxy wire envelope for Yıldızname Narrative V1.
library;

import '../versions.dart';
import 'yildizname_narrative_request.dart';

abstract final class YildiznameWireContract {
  YildiznameWireContract._();

  /// Paid request sets operation; payload carries mode + narrative body.
  static Map<String, dynamic> payload(YildiznameNarrativeRequest request) {
    return {
      'mode': kYildiznameNarrativeMode,
      'contractVersion': kYildiznameContractVersion,
      'language': request.languageCode,
      'narrative': request.toProviderJson(),
    };
  }
}
