/// Smart revisit copy — warm, never guilt, never surveillance.

library;



import '../../../core/l10n/l10n.dart';

import '../revisit/tarot_revisit_context.dart';

import '../revisit/tarot_revisit_mode.dart';



abstract final class TarotRevisitCopy {

  TarotRevisitCopy._();



  static String _t(String key) => OraclyL10n.t(key);



  static String get sheetTitle => _t('tarot.revisit.title');

  static String get body => _t('tarot.revisit.body');

  static String get actionNewSpread => _t('tarot.revisit.action.new_spread');

  static String get actionOpenPrior => _t('tarot.revisit.action.open_prior');

  static String get actionAngle => _t('tarot.revisit.action.angle');

  static String get topicCareer => _t('tarot.revisit.topic.career');

  static String get topicLove => _t('tarot.revisit.topic.love');

  static String get topicDaily => _t('tarot.revisit.topic.daily');

  static String get topicGeneral => _t('tarot.revisit.topic.general');

  static String get topicDecision => _t('tarot.revisit.topic.decision');

  static String get topicGuidance => _t('tarot.revisit.topic.guidance');



  static String contextLine(TarotRevisitContext context) {

    final topic = context.topicLabel;

    if (topic == null || topic.isEmpty) {

      return context.spreadLabel;

    }

    return _t('tarot.revisit.context')

        .replaceAll('{topic}', topic)

        .replaceAll('{spread}', context.spreadLabel);

  }



  static String revisitInstruction(TarotRevisitMode mode) => switch (mode) {

        TarotRevisitMode.differentAngle => _t('tarot.revisit.prompt.angle'),

        TarotRevisitMode.compare => _t('tarot.revisit.prompt.compare'),

      };

}


