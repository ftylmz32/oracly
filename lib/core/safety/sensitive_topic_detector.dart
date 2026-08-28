/// Detects user turns that need safety routing — not diagnosis or prophecy.

library;



import 'sensitive_topic_kind.dart';



abstract final class SensitiveTopicDetector {

  SensitiveTopicDetector._();



  static SensitiveTopicKind? detect(String text) {

    final t = text.trim().toLowerCase();

    if (t.isEmpty) return null;

    if (_crisis(t)) return SensitiveTopicKind.crisis;

    if (_health(t)) return SensitiveTopicKind.health;

    if (_financial(t)) return SensitiveTopicKind.financial;

    if (_legal(t)) return SensitiveTopicKind.legal;

    if (_relationship(t)) return SensitiveTopicKind.relationship;

    if (_fear(t)) return SensitiveTopicKind.fear;

    return null;

  }



  static bool _crisis(String t) {

    const hits = [

      'intihar',

      'kendimi öldür',

      'kendime zarar',

      'yaşamak istemiyorum',

      'ölmek istiyorum',

      'canıma kıy',

      'kill myself',

      'suicide',

      'self-harm',

      'end my life',

      'want to die',

      'самоубий',

      'покончить с собой',

      'не хочу жить',

    ];

    return hits.any(t.contains);

  }



  static bool _health(String t) {

    if (RegExp(r'hastalı[kg]').hasMatch(t) ||

        t.contains('teşhis') ||

        t.contains('semptom') ||

        t.contains('kanser') ||

        t.contains('tedavi') ||

        t.contains('doktor') && t.contains('fal') ||

        t.contains('medical') ||

        t.contains('diagnos') ||

        t.contains('болезн') ||

        t.contains('диагноз') ||

        _medicationDirectiveAsk(t)) {

      return true;

    }

    return RegExp(

      r'(fal|tarot|kahve|burç|astroloji).{0,40}(hastalı|hastalığım|sağlık)',

    ).hasMatch(t);

  }

  static bool _medicationDirectiveAsk(String t) {
    final med = t.contains('ilaç') ||
        t.contains('ilac') ||
        t.contains('medication') ||
        t.contains('medicine');
    if (!med) return false;
    return t.contains('bırak') ||
        t.contains('birak') ||
        t.contains('kesmeli') ||
        t.contains('stop taking') ||
        t.contains('quit taking');
  }



  static bool _financial(String t) {

    const hits = [

      'garanti kazan',

      'kesin kazan',

      'garanti getiri',

      'guaranteed return',

      'guaranteed profit',

      'yatırım garanti',

      'hisse almalı mıyım kesin',

      'гарантирован',

    ];

    if (hits.any(t.contains)) return true;

    return RegExp(r'(fal|tarot|burç).{0,30}(yatırım|hisse|borsa|kripto)')

        .hasMatch(t);

  }



  static bool _legal(String t) {

    const hits = [

      'hukuki tavsiye',

      'yasal tavsiye',

      'dava kazan',

      'mahkeme kesin',

      'legal advice',

      'lawsuit',

      'суд выигра',

    ];

    if (hits.any(t.contains)) return true;

    return RegExp(r'(fal|tarot|burç).{0,30}(dava|mahkeme|hukuk|yasal)')

        .hasMatch(t);

  }



  static bool _relationship(String t) {

    const hits = [

      'kesin beni seviyor',

      'kesin seviyor mu',

      'definitely loves me',

      'definitely love me',

      'точно любит меня',

    ];

    if (hits.any(t.contains)) return true;

    return RegExp(r'(fal|tarot|burç).{0,30}(seviyor mu|aşık mı)').hasMatch(t);

  }



  static bool _fear(String t) {

    const hits = [

      'ne zaman öleceğim',

      'ölüm tarihim',

      'felaket olacak mı',

      'when will i die',

      'death date',

      'disaster will happen',

      'когда умру',

      'катастроф',

    ];

    return hits.any(t.contains) ||

        RegExp(r'(fal|tarot).{0,24}(ölüm|felaket|tehlike)').hasMatch(t);

  }

}


