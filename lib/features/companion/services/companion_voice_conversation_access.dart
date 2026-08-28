/// Voice conversation (SOHBET) is Premium — honest gate, never a fake unlock.
library;

import 'package:flutter/material.dart';

import '../../premium/services/premium_access.dart';
import '../presentation/reference/companion_reference_voice_conversation_preview.dart';

abstract final class CompanionVoiceConversationAccess {
  CompanionVoiceConversationAccess._();

  static bool isAllowed(BuildContext context) =>
      PremiumAccess.isActive(context);

  /// True when Premium. Otherwise shows the preview and returns false.
  static bool ensure(BuildContext context) {
    if (isAllowed(context)) return true;
    preview(context);
    return false;
  }

  static Future<void> preview(BuildContext context) {
    return CompanionReferenceVoiceConversationPreview.show(context);
  }
}
