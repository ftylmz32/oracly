/// Full-scope positive corpus shared map builder.
library;

Map<String, dynamic> narrativeFullMap({
  required String language,
  required String summary,
  required String core,
  required String emotion,
  required String angles,
  required String patterns,
  required String closing,
  required String reflect,
  required String close,
}) {
  Map<String, dynamic> block(
    String text, {
    List<String> facts = const [],
  }) =>
      {'text': text, 'factRefs': facts, 'themeRefs': <String>[]};

  return {
    'contractVersion': 1,
    'languageCode': language,
    'scope': 'full',
    'summary': block(
      summary,
      facts: ['placement.sun', 'placement.moon', 'angle.ascendant'],
    ),
    'sections': [
      {
        'kind': 'core_identity',
        'text': core,
        'factRefs': ['placement.sun', 'placement.mercury'],
        'themeRefs': <String>[],
      },
      {
        'kind': 'emotional_world',
        'text': emotion,
        'factRefs': ['placement.moon', 'aspect.sun.moon.opposition'],
        'themeRefs': <String>[],
      },
      {
        'kind': 'angles_and_houses',
        'text': angles,
        'factRefs': [
          'angle.ascendant',
          'placement.sun',
          'placement.venus',
          'house.10',
        ],
        'themeRefs': <String>[],
      },
      {
        'kind': 'patterns_and_tensions',
        'text': patterns,
        'factRefs': [
          'aspect.venus.mars.sextile',
          'placement.jupiter',
          'placement.saturn',
        ],
        'themeRefs': <String>[],
      },
      {
        'kind': 'practical_reflection',
        'text': closing,
        'factRefs': ['placement.sun', 'angle.ascendant'],
        'themeRefs': <String>[],
      },
    ],
    'reflectionPrompt': block(
      reflect,
      facts: ['placement.sun', 'placement.moon'],
    ),
    'closingMessage': block(close, facts: ['placement.sun']),
  };
}
