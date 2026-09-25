/// Mutators that produce quality-failing Narrative V1 maps.
library;

import 'narrative_result_corpus.dart';

abstract final class NarrativeFailCorpus {
  NarrativeFailCorpus._();

  static Map<String, dynamic> wrongMoonSign() {
    final m = Map<String, dynamic>.from(NarrativeResultCorpus.fullEn());
    final sections = List<Map<String, dynamic>>.from(
      (m['sections'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    sections[1] = {
      ...sections[1],
      'text':
          'Moon in Pisces drifts through fog. This wrong sign must fail grounding.',
    };
    m['sections'] = sections;
    return m;
  }

  static Map<String, dynamic> ascWithoutEvidence() {
    final m = Map<String, dynamic>.from(NarrativeResultCorpus.legacyTr());
    final sections = List<Map<String, dynamic>>.from(
      (m['sections'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    sections.add({
      'kind': 'angles_and_houses',
      'text':
          'Başak yükseleni (Virgo rising) burada uydurulmuştur; kanıt yok.',
      'factRefs': <String>[],
      'themeRefs': <String>[],
    });
    m['sections'] = sections;
    return m;
  }

  static Map<String, dynamic> wrongVenusHouse() {
    final m = Map<String, dynamic>.from(NarrativeResultCorpus.fullEn());
    final sections = List<Map<String, dynamic>>.from(
      (m['sections'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    sections[2] = {
      ...sections[2],
      'text':
          'Venus in the 7 house claims partnership wrongly; evidence is house 11.',
    };
    m['sections'] = sections;
    return m;
  }

  static Map<String, dynamic> falseConjunction() {
    final m = Map<String, dynamic>.from(NarrativeResultCorpus.fullEn());
    final sections = List<Map<String, dynamic>>.from(
      (m['sections'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    sections[1] = {
      ...sections[1],
      'text':
          'A Sun–Moon conjunction invents unity; evidence only has opposition.',
    };
    m['sections'] = sections;
    return m;
  }

  static Map<String, dynamic> unsupportedChiron() {
    final m = Map<String, dynamic>.from(NarrativeResultCorpus.fullEn());
    final sections = List<Map<String, dynamic>>.from(
      (m['sections'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    sections[3] = {
      ...sections[3],
      'text':
          'Your Chiron wound and North Node destiny invent unsupported points.',
    };
    m['sections'] = sections;
    return m;
  }

  static Map<String, dynamic> safetyDeath() {
    final m = Map<String, dynamic>.from(NarrativeResultCorpus.legacyTr());
    final summary = Map<String, dynamic>.from(m['summary'] as Map);
    summary['text'] =
        'Güneş Boğa burcunda olsa da bu harita ölüm zamanını kesin söyler; '
        'kabul edilemez bir fatalism örneğidir.';
    m['summary'] = summary;
    return m;
  }

  static Map<String, dynamic> genericCosmic() {
    final m = Map<String, dynamic>.from(NarrativeResultCorpus.fullEn());
    final summary = Map<String, dynamic>.from(m['summary'] as Map);
    summary['text'] =
        'Cosmic energy guarantees your rise. The stars have spoken forever.';
    m['summary'] = summary;
    return m;
  }

  static Map<String, dynamic> archiveWithoutThemes() {
    final m = Map<String, dynamic>.from(NarrativeResultCorpus.fullEn());
    final sections = List<Map<String, dynamic>>.from(
      (m['sections'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    sections.add({
      'kind': 'archive_echo',
      'text':
          'Your recurring history shows again and again the same private theme.',
      'factRefs': ['placement.sun'],
      'themeRefs': <String>[],
    });
    m['sections'] = sections;
    return m;
  }
}
