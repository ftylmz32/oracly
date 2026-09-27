/// Phase 8B — build quality-grounded fake AI payloads from a live plan request.
library;

import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_placement_fact.dart';
import 'package:oracly_new/features/star_map/narrative/versions.dart';

Map<String, dynamic> _block(
  String text, {
  List<String> facts = const [],
}) =>
    {
      'text': text,
      'factRefs': facts,
      'themeRefs': <String>[],
    };

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// English prose grounded to request signs — passes Phase 5 quality for tests.
Map<String, dynamic> phase8bApprovedPayload(YildiznameNarrativeRequest request) {
  final placements = [
    for (final p in request.placements)
      if (p.sign.trim().isNotEmpty) p,
  ];
  final YildiznamePlacementFact sun = placements.firstWhere(
    (p) => p.body == 'sun',
    orElse: () => placements.first,
  );
  final YildiznamePlacementFact second = placements.length > 1
      ? placements.firstWhere((p) => p.body != sun.body)
      : sun;
  final sunSign = _cap(sun.sign);
  final secondSign = _cap(second.sign);

  final sections = <Map<String, dynamic>>[
    {
      'kind': 'core_identity',
      'text':
          'Sun in $sunSign may favor a calmer sense of self without claiming '
          'destiny. It is one stable thread among others in this reading.',
      'factRefs': [sun.factRef],
      'themeRefs': <String>[],
    },
    {
      'kind': 'emotional_world',
      'text':
          '${_cap(second.body)} in $secondSign can color feeling. '
          'Together with Sun in $sunSign, intensity meets a need for calm ground.',
      'factRefs': [second.factRef, sun.factRef],
      'themeRefs': <String>[],
    },
  ];

  if (request.scope == YildiznameNarrativeScope.full) {
    for (final asc in request.angles.where((a) => a.kind == 'ascendant')) {
      sections.add({
        'kind': 'practical_reflection',
        'text':
            '${_cap(asc.sign)} rising may shape how presence meets the day. '
            'This angle is offered as reflection, not prediction.',
        'factRefs': [asc.factRef, sun.factRef],
        'themeRefs': <String>[],
      });
      break;
    }
    final personal = request.placements
        .where((p) =>
            {'mercury', 'venus', 'mars', 'jupiter', 'saturn'}.contains(p.body) &&
            p.sign.trim().isNotEmpty)
        .take(2)
        .toList();
    if (personal.length >= 2) {
      sections.add({
        'kind': 'mind_and_expression',
        'text':
            '${_cap(personal[0].body)} in ${_cap(personal[0].sign)} and '
            '${_cap(personal[1].body)} in ${_cap(personal[1].sign)} invite '
            'careful speech and values without guaranteeing outcomes.',
        'factRefs': [personal[0].factRef, personal[1].factRef],
        'themeRefs': <String>[],
      });
    }
    if (request.aspects.isNotEmpty) {
      final a = request.aspects.first;
      sections.add({
        'kind': 'patterns_and_tensions',
        'text':
            'An aspect between ${_cap(a.bodyA)} and ${_cap(a.bodyB)} may '
            'hint at tension or harmony to notice gently, never as fate.',
        'factRefs': [a.factRef],
        'themeRefs': <String>[],
      });
    }
  }

  return {
    'contractVersion': kYildiznameResultContractVersion,
    'languageCode': request.languageCode,
    'scope': request.scope.name,
    'summary': _block(
      'Sun in $sunSign and ${_cap(second.body)} in $secondSign '
      'suggest a quiet tension between steadiness and depth worth reflecting on.',
      facts: [sun.factRef, second.factRef],
    ),
    'sections': sections,
    'reflectionPrompt': 'Where do steadiness and emotional honesty ask for the same care today?',
    'closingMessage': 'This reading stays within the facts you offered and leaves room for your own sense.',
  };
}
