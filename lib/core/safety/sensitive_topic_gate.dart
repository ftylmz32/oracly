/// Routes sensitive user turns to calm, honest responses — before AI.

library;



import '../l10n/l10n.dart';

import 'sensitive_topic_detector.dart';

import 'sensitive_topic_kind.dart';



abstract final class SensitiveTopicGate {

  SensitiveTopicGate._();



  static SensitiveTopicKind? classify(String text) =>

      SensitiveTopicDetector.detect(text);



  /// Non-null when the turn must not continue as fortune-telling.

  static String? maybeRespond(String text) {

    final kind = classify(text);

    if (kind == null) return null;

    return OraclyL10n.t(_key(kind));

  }



  static String promptRule() =>

      'Sağlık teşhisi, hukuki tavsiye, finansal garanti, kesin aşk iddiası, '

      'ölüm/felaket kehaneti ve kriz anında fal dili kullanma. '

      'Sembolik okuma bir çerçevedir; gerçek karar ve acil durumlar '

      'profesyonel destek gerektirir.';



  static String _key(SensitiveTopicKind kind) => switch (kind) {

        SensitiveTopicKind.crisis => 'safety.crisis',

        SensitiveTopicKind.health => 'safety.health',

        SensitiveTopicKind.financial => 'safety.financial',

        SensitiveTopicKind.legal => 'safety.legal',

        SensitiveTopicKind.relationship => 'safety.relationship',

        SensitiveTopicKind.fear => 'safety.fear',

      };

}


