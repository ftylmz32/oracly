/// What the OR UI may show and do for a resolved [OrSessionState].
library;

import 'or_session_state.dart';

class OrSessionPresentation {
  const OrSessionPresentation({
    required this.state,
    required this.canCompose,
    required this.canUseMic,
    required this.showPreview,
    required this.showPaywallDock,
    this.statusLine,
    this.canRetry = false,
    this.connecting = false,
  });

  final OrSessionState state;

  /// Text composer for live turns (Premium path only).
  final bool canCompose;

  /// Mic / STT when Premium; still allowed if only TTS is down.
  final bool canUseMic;

  /// Free-chamber preview (presence + sample + paywall host).
  final bool showPreview;

  /// Bottom Premium dock when chat is gated.
  final bool showPaywallDock;

  /// Calm status strip copy; null hides the strip.
  final String? statusLine;

  /// Offer retry on the strip / notice.
  final bool canRetry;

  /// Bootstrap / reconnect glow — not a separate product state.
  final bool connecting;

  bool get showStatusStrip =>
      statusLine != null && statusLine!.trim().isNotEmpty;

  bool get isGated =>
      (state == OrSessionState.free && !canCompose) ||
      state == OrSessionState.purchasePending;

  bool get softStatus =>
      state == OrSessionState.voiceUnavailable ||
      state == OrSessionState.purchasePending ||
      state == OrSessionState.reconnecting ||
      state == OrSessionState.retrying ||
      state == OrSessionState.saveFailed;
}
