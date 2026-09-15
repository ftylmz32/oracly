/// Waiting and acceleration copy. No technical operation language.
library;

import '../../../core/l10n/l10n.dart';
import '../models/reading_operation_status.dart';

abstract final class ReadingLiveCopy {
  ReadingLiveCopy._();

  static String title(ReadingType type) {
    return switch (type) {
      ReadingType.coffee => OraclyL10n.t('read.wait.title.coffee'),
      ReadingType.palm => OraclyL10n.t('read.wait.title.palm'),
      ReadingType.soulmate => OraclyL10n.t('read.wait.title.soulmate'),
    };
  }

  static String get processing => OraclyL10n.t('read.wait.processing');
  static String get processingDetail =>
      OraclyL10n.t('read.wait.processing_detail');
  /// Shown once an operation's own readyAt has elapsed but the server
  /// hasn't claimed it yet (Cloud Tasks queue delay, cold start, backoff) --
  /// never implies a failure, just "any moment now".
  static String get overdueWaiting =>
      OraclyL10n.t('read.wait.overdue_waiting');
  static String get accelerate => OraclyL10n.t('read.wait.accelerate');
  static String get leave => OraclyL10n.t('read.wait.leave');
  static String get insufficient => OraclyL10n.t('read.wait.insufficient');
  static String get priceChanged => OraclyL10n.t('read.wait.price_changed');
  static String get refunded => OraclyL10n.t('read.wait.refunded');
  static String get failed => OraclyL10n.t('read.wait.failed');

  static String get headline => OraclyL10n.t('read.wait.headline');
  static String get subtitle => OraclyL10n.t('read.wait.subtitle');
  static String get hoursLabel => OraclyL10n.t('read.wait.hours');
  static String get minutesLabel => OraclyL10n.t('read.wait.minutes');
  static String get secondsLabel => OraclyL10n.t('read.wait.seconds');
  static String get accelerateCta => OraclyL10n.t('read.wait.accelerate_cta');
  /// Shown only once the server has quoted a real cost for this operation
  /// -- never a client-invented number. Falls back to [accelerateCta]
  /// (no number) while the quote hasn't arrived yet.
  static String accelerateCtaWithCost(int? cost) {
    if (cost == null) return accelerateCta;
    return OraclyL10n.t(
      'read.wait.accelerate_cta_cost',
    ).replaceAll('{cost}', '$cost');
  }
  static String get backgroundInfo =>
      OraclyL10n.t('read.wait.background_info');

  static String countdown(Duration remaining) {
    final total = remaining.inSeconds.clamp(0, 864000);
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$mm:$ss';
    return '$minutes:$ss';
  }
}
