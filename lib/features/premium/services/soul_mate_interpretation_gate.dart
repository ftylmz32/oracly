/// Client acceptance gate for Soulmate text. Never treats a local template as success.
library;

enum SoulMateInterpretationReject {
  tooShort,
  genericCliche,
  repetitive,
  deterministic,
  fakeMemory,
  contradiction,
  rawSchema,
  restatingInputs,
  adjectiveList,
}

class SoulMateInterpretationDraft {
  const SoulMateInterpretationDraft({
    required this.personality,
    required this.dynamic,
    required this.attraction,
    required this.challenge,
    required this.meeting,
    required this.feeling,
  });

  final String personality;
  final String dynamic;
  final String attraction;
  final String challenge;
  final String meeting;
  final String feeling;

  List<String> get values =>
      [personality, dynamic, attraction, challenge, meeting, feeling];
}

abstract final class SoulMateInterpretationGate {
  SoulMateInterpretationGate._();

  static const maxRepairAttempts = 1;

  static SoulMateInterpretationReject? assess(
    SoulMateInterpretationDraft draft, {
    String? name,
    String? presence,
  }) {
    final values = draft.values;
    final joined = values.map(_fold).join('\n');
    if (values.any((v) => v.trim().length < 48) || joined.length < 320) {
      return SoulMateInterpretationReject.tooShort;
    }
    if (_cliche.any(joined.contains)) {
      return SoulMateInterpretationReject.genericCliche;
    }
    if (_certain.any(joined.contains) || _date.hasMatch(joined)) {
      return SoulMateInterpretationReject.deterministic;
    }
    if (_memory.any(joined.contains)) {
      return SoulMateInterpretationReject.fakeMemory;
    }
    if (joined.contains('{') ||
        joined.contains('soulmate_') ||
        joined.contains('imagebase64') ||
        joined.contains('provider_error')) {
      return SoulMateInterpretationReject.rawSchema;
    }
    if (_startsRepeat(values) || _buKisiStarts(values)) {
      return SoulMateInterpretationReject.repetitive;
    }
    if (values.where(_adjectiveList).length >= 2) {
      return SoulMateInterpretationReject.adjectiveList;
    }
    if (_restates(values, name)) {
      return SoulMateInterpretationReject.restatingInputs;
    }
    if (_contradicts(joined, presence)) {
      return SoulMateInterpretationReject.contradiction;
    }
    return null;
  }

  static const _cliche = [
    'ruh esin kesinlikle',
    'ruh esin seni bekliyor',
    'yildizlar seni',
    'evrenin plani',
    'sonsuz ask',
    'ikiz alev',
    'kalbinin ritmi',
    'meant to be',
    'twin flame',
  ];

  static const _certain = [
    'kesinlikle',
    'su tarihte',
    'karsilasacaksin',
    'bu kisi kesin',
    'you will definitely meet',
    'you will meet on',
  ];

  static const _memory = [
    'hatirliyorum',
    'gecen yil',
    'eski sevgilin',
    'daha once seninle',
    'eski iliskin',
    'i remember when you',
    'your previous relationship',
  ];

  static final _date = RegExp(r'\b\d{1,2}[./]\d{1,2}([./]\d{2,4})?\b');

  static String _fold(String value) {
    return value
        .toLowerCase()
        .replaceAll('\u015f', 's')
        .replaceAll('\u0131', 'i')
        .replaceAll('\u011f', 'g')
        .replaceAll('\u00fc', 'u')
        .replaceAll('\u00f6', 'o')
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u00e2', 'a')
        .replaceAll('\u00ee', 'i');
  }

  static bool _startsRepeat(List<String> values) {
    final starts = [
      for (final value in values)
        _fold(value).trim().split(RegExp(r'\s+')).take(3).join(' '),
    ];
    return starts.any(
      (start) => start.isNotEmpty && starts.where((s) => s == start).length >= 3,
    );
  }

  static bool _buKisiStarts(List<String> values) {
    final n = values
        .where((v) => RegExp(r'^(bu kisi|this person)\b').hasMatch(_fold(v).trim()))
        .length;
    return n >= 3;
  }

  static bool _adjectiveList(String value) {
    final commas = ','.allMatches(value).length;
    return commas >= 3 &&
        !RegExp(r'\b(olabilir|hissed|durabilir|might|feel)\b').hasMatch(_fold(value));
  }

  static bool _restates(List<String> values, String? name) {
    final who = _fold(name ?? '').trim();
    if (who.length < 2) return false;
    final hits = values.where((value) {
      final text = _fold(value);
      final count = who.allMatches(text).length;
      return count >= 2 && value.trim().length < 90;
    }).length;
    return hits >= 3;
  }

  static bool _contradicts(String joined, String? presence) {
    if (presence == null || presence.isEmpty) return false;
    if (presence.startsWith('masculine') &&
        RegExp(r'\b(kadinsi|she is a woman|feminine-presenting)\b').hasMatch(joined)) {
      return true;
    }
    if (presence.startsWith('feminine') &&
        RegExp(r'\b(erkeksi|he is a man|masculine-presenting)\b').hasMatch(joined)) {
      return true;
    }
    return false;
  }
}
