/// Completion gate: splash may remove only after art painted or failed.
library;

class SplashCompletionGate {
  bool artPainted = false;
  bool artFailed = false;
  bool animationEnded = false;
  bool pendingFinish = false;

  bool get artSettled => artPainted || artFailed;

  /// Call when the branded splash controller completes (~1.5–2.0s).
  bool requestFinish() {
    if (artSettled) return true;
    pendingFinish = true;
    return false;
  }

  /// Call when decoded art has painted (or load failed).
  bool onArtSettled({required bool painted}) {
    if (painted) {
      artPainted = true;
    } else {
      artFailed = true;
    }
    return pendingFinish && artSettled;
  }
}
