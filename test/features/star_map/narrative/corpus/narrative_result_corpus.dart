/// Scripted valid Narrative V1 result maps for tests.
library;

import 'package:oracly_new/features/star_map/narrative/versions.dart';

import 'narrative_result_corpus_full.dart';

Map<String, dynamic> _block(
  String text, {
  List<String> facts = const [],
  List<String> themes = const [],
}) =>
    {
      'text': text,
      'factRefs': facts,
      'themeRefs': themes,
    };

abstract final class NarrativeResultCorpus {
  NarrativeResultCorpus._();

  static Map<String, dynamic> legacyTr() => {
        'contractVersion': kYildiznameResultContractVersion,
        'languageCode': 'tr',
        'scope': 'legacy',
        'summary': _block(
          'Güneş Boğa burcunda; kimliğin sabır ve somut değerler üzerinden '
          'şekillenme eğilimindedir. Bu, bir burç özeti değil; sınırlı '
          'kanıta dayalı sakin bir yansımadır.',
          facts: ['placement.sun'],
        ),
        'sections': [
          {
            'kind': 'core_identity',
            'text':
                'Boğa Güneşi, istikrar ve duyusal güven arayışını güçlendirebilir. '
                'Bu eğilim kesin kader değildir; yalnızca sunulan güneş kimliğine '
                'dayanan bir okuma.',
            'factRefs': ['placement.sun'],
            'themeRefs': <String>[],
          },
          {
            'kind': 'practical_reflection',
            'text':
                'Bugün kendine şunu sorabilirsin: Hangi somut adım bana daha '
                'güvende hissettirir? Yanıtı senin içinden gelsin.',
            'factRefs': ['placement.sun'],
            'themeRefs': <String>[],
          },
        ],
        'reflectionPrompt': _block(
          'Hangi alışkanlığın seni yavaş ama emin adımlarla besliyor?',
          facts: ['placement.sun'],
        ),
        'closingMessage': _block(
          'Bu kısa okuma sınırlı kanıtla yazıldı; yine de kendi ritmini '
          'dinlemek için yeterli bir durak olabilir.',
          facts: ['placement.sun'],
        ),
      };

  static Map<String, dynamic> reducedEn() => {
        'contractVersion': kYildiznameResultContractVersion,
        'languageCode': 'en',
        'scope': 'reduced',
        'summary': _block(
          'With interval-stable signs, your Sun in Taurus and Moon in Scorpio '
          'suggest a quiet tension between steadiness and emotional depth.',
          facts: ['placement.sun', 'placement.moon'],
        ),
        'sections': [
          {
            'kind': 'core_identity',
            'text':
                'Sun in Taurus may favor patience and tangible values without '
                'claiming a destiny. It is one stable thread among others.',
            'factRefs': ['placement.sun'],
            'themeRefs': <String>[],
          },
          {
            'kind': 'emotional_world',
            'text':
                'Moon in Scorpio can deepen feeling and privacy. Together with '
                'Sun in Taurus, intensity meets a need for calm ground.',
            'factRefs': ['placement.moon', 'placement.sun'],
            'themeRefs': <String>[],
          },
          {
            'kind': 'mind_and_expression',
            'text':
                'Mercury in Aries may quicken speech. Even without exact degrees, '
                'this interval-safe sign invites clearer starts.',
            'factRefs': ['placement.mercury'],
            'themeRefs': <String>[],
          },
        ],
        'reflectionPrompt': _block(
          'Where do steadiness and emotional honesty ask for the same care?',
          facts: ['placement.sun', 'placement.moon'],
        ),
        'closingMessage': _block(
          'This reduced reading stays within interval-safe facts only.',
          facts: ['placement.sun'],
        ),
      };

  static Map<String, dynamic> fullEn() => NarrativeFullCorpus.en();
  static Map<String, dynamic> fullTr() => NarrativeFullCorpus.tr();
  static Map<String, dynamic> fullRu() => NarrativeFullCorpus.ru();
}
