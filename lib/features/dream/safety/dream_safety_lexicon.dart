/// Dream Phase 3 input lexicon — folded TR/EN/RU phrases (lowercase, ı→i,
/// ё→е). Static catalog; mirrored verbatim in
/// `backend/src/ai/dream-safety-lexicon.ts` and proven by the shared corpus.
library;

import 'dream_safety_text.dart';

abstract final class DreamSafetyLexicon {
  DreamSafetyLexicon._();

  /// Present/future first-person intent — never excused by dream framing.
  static final crisis = DreamSafetyText.words([
    r'kendimi (?:öldürmek|öldürmeyi|asmak|asmayi) (?:istiyorum|düşünüyorum|planliyorum)',
    r'kendime zarar (?:vermek|vermeyi) (?:istiyorum|düşünüyorum|planliyorum)',
    r'intihar (?:etmek|etmeyi) (?:istiyorum|düşünüyorum|planliyorum)',
    r'(?:canima kiymak|hayatima son vermek) (?:istiyorum|düşünüyorum)',
    r'(?:kendimi öldüreceğim|kendime zarar vereceğim|intihar edeceğim|canima kiyacağim|hayatima son vereceğim)',
    r'(?:kendimi öldürmem|kendime zarar vermem|intihar etmem) (?:gerek|lazim)',
    r'yaşamak istemiyorum',
    r'ölmek istiyorum',
    r'intihar düşünce(?:lerim|m) var',
    r"i (?:really |just )?want to (?:kill myself|die|end my life|end it all|hurt myself|harm myself|cut myself)",
    r"(?:i'm|i am|im) (?:going|planning) (?:to|on) (?:kill|killing|hurt|hurting|harm|harming|cut|cutting|end|ending) (?:myself|my life)",
    r"i(?: will|'ll) (?:kill|hurt|harm|cut) myself",
    r"i (?:have to|need to|must|should) (?:kill|hurt|harm|cut) myself",
    r"(?:i'm|i am|im|i feel) suicidal",
    r"(?:i'm|i am|i keep|i've been|i have been) thinking (?:about|of) (?:suicide|killing myself|ending my life|hurting myself|harming myself)",
    r"i (?:don't|dont|do not) want to (?:live|be alive) anymore",
    r'хочу (?:покончить с собой|умереть|убить себя|причинить себе вред|навредить себе|порезать себя)',
    r'(?:покончу с собой|убью себя|причиню себе вред|наврежу себе)',
    r'(?:планирую|собираюсь) (?:покончить с собой|убить себя|причинить себе вред|навредить себе)',
    r'не хочу (?:больше )?жить',
    r'(?:думаю|мысли) о (?:самоубийстве|суициде)',
    r'(?:надо|нужно|должен|должна) (?:покончить с собой|убить себя|причинить себе вред)',
  ]);

  /// Stated immediate danger right now.
  static final acute = DreamSafetyText.words([
    r'(?:kendimi )?güvende (?:hissetmiyorum|değilim)',
    r'kontrol(?:ümü|ü) kaybediyorum',
    r'kendimi (?:kontrol edemiyorum|koruyamiyorum|güvende tutamiyorum)',
    r'tehlikedeyim',
    r'(?:acil|hemen) yardima ihtiyacim var',
    r"(?:i'm|i am|im) in (?:immediate |real )?danger",
    r"i (?:can't|cant|cannot) keep myself safe",
    r"i (?:don't|dont|do not) feel safe",
    r"(?:i'm|i am|im) losing control",
    r'i need (?:emergency|urgent|immediate) help',
    r'i need help right now',
    r'я (?:сейчас )?в опасности',
    r'не чувствую себя в безопасности',
    r'я теряю контроль',
    r'не могу (?:себя контролировать|себя обезопасить|обезопасить себя)',
    r'мне (?:срочно нужна|нужна срочная|нужна экстренная) помощь',
  ]);

  static final abuse = DreamSafetyText.words([
    r'cinsel (?:saldiri|istismar|taciz)', r'tecavüz', r'taciz', r'istismar',
    r'ensest', r'sexual(?:ly)? (?:assault|abuse)', r'raped?(?!\p{L})',
    r'molest', r'abused?(?!\p{L})', r'incest', r'изнасил', r'насили',
    r'домогател', r'растлен',
  ]);

  /// The dreamer says it happened in waking life.
  static final reality = DreamSafetyText.words([
    r'gerçekten', r'gerçek hayatta', r'gerçekte(?!\p{L})', r'başima gel',
    r'bana yapil', r'çocukken', r'çocukluğumda', r'yillar önce',
    r'geçmişte', r'really happened', r'actually happened', r'in real life',
    r'as a (?:child|kid)', r'when i was (?:a child|a kid|young|little)',
    r'happened to me', r'i went through', r'years ago', r'на самом деле',
    r'в реальной жизни', r'в детстве', r'со мной (?:было|случилось|произошло)',
    r'было со мной', r'я пережил', r'много лет назад',
  ]);

  static final proof = DreamSafetyText.words([
    r'kanitliyor', r'kanitladi', r'kaniti(?:dir)?(?!\p{L})', r'ispatliyor',
    r'ispatladi', r'doğruluyor', r'doğruladi', r'teyit ediyor',
    r'prove[sd]?(?!\p{L})', r'proof', r'confirm(?:s|ed)?(?!\p{L})',
    r'evidence that', r'доказыва', r'доказал', r'доказательств',
    r'подтвержда', r'подтвердил',
  ]);

  static final agents = DreamSafetyText.words([
    r'devlet', r'polis', r'istihbarat', r'cin(?:ler|lerin|leri|in|i)?(?!\p{L})',
    r'şeytan', r'ruh(?:lar|larin|un)?(?!\p{L})', r'uzayli',
    r'büyü(?:cü|yle|nün)?(?!\p{L})',
    r'beni (?:gerçekten |gizlice )?(?:izl|takip|gözetl|dinl)',
    r'gizli güç', r'sesler', r'government', r'police', r'fbi', r'cia(?!\p{L})',
    r'spirits?(?!\p{L})', r'd?jinn', r'demons?(?!\p{L})', r'aliens?(?!\p{L})',
    r'ghosts?(?!\p{L})', r'(?:watching|following|spying on|monitoring|tracking) me',
    r'being (?:watched|followed|monitored|tracked)', r'voices', r'hidden forces?',
    r'следят', r'следит', r'слежк', r'правительств', r'государств', r'полици',
    r'спецслужб', r'дух(?:и|ов|ам|а)?(?!\p{L})', r'джинн', r'демон',
    r'бес(?:ы|ов)?(?!\p{L})', r'инопланет', r'пришельц', r'голоса',
  ]);

  /// Waking voices giving orders — dream framing may excuse them.
  static final voices = DreamSafetyText.words([
    r'sesler (?:bana )?(?:emir veriyor|ne yapacağimi söylüyor|konuşuyor)',
    r'uyanikken (?:de )?sesler', r'sesler duyuyorum',
    r'voices (?:are )?(?:telling|tell|command|commanding|order|ordering) me',
    r'i (?:hear|keep hearing) voices',
    r'голоса (?:приказывают|говорят мне|велят)', r'слышу голоса',
  ]);

  static final diagnosisTerms = DreamSafetyText.words([
    r'şizofren', r'bipolar', r'psikoz', r'psikotik', r'tssb', r'ptsd',
    r'travma sonrasi stres', r'depresyon', r'akil hastasi', r'ruh hastasi',
    r'otizm', r'dehb', r'adhd', r'kanser', r'demans', r'okb(?!\p{L})',
    r'obsesif', r'kişilik bozukluğu', r'anksiyete bozukluğu',
    r'panik bozukluğu', r'schizophreni', r'psychosis', r'psychotic',
    r'post-?traumatic', r'depress(?:ion|ed)', r'mentally ill',
    r'mental illness', r'autis', r'cancer', r'dementia', r'ocd(?!\p{L})',
    r'personality disorder', r'anxiety disorder', r'panic disorder',
    r'шизофрени', r'биполяр', r'психоз', r'психотич', r'птср',
    r'посттравматическ', r'депресси', r'психически бол', r'аутизм', r'сдвг',
    r'рак(?:а|ом|у)?(?!\p{L})', r'деменци', r'окр(?!\p{L})',
  ]);

  /// Asking the dream to decide: a question particle or a link verb.
  static final diagnosisLinks = DreamSafetyText.words([
    r'm[iuü](?:yim|yum|yüm|sun|sin|dur|dir)?(?!\p{L})', r'gösteriyor', r'kanitl', r'belirti', r'işaret', r'anlamina',
    r'anlayabilir', r'teşhis', r'do i have', r'am i(?!\p{L})',
    r"(?:proves?|shows?|means?|indicates?|suggests?) (?:that )?i(?:'m| am| have)?(?!\p{L})",
    r'diagnos', r'sign (?:of|that)', r'symptom', r'ли я',
    r'значит', r'означает', r'доказыва', r'признак', r'симптом', r'диагноз',
  ]);

  static final dream = DreamSafetyText.words([
    r'rüya(?:m|miz|si|sin)?da(?:ki)?(?!\p{L})', r'düşümde',
    r'kabus(?:um)?(?:da|ta)(?:ki)?(?!\p{L})',
    r'in (?:my|the|this|that|a) (?:dream|nightmare)',
    r'i (?:dreamt|dreamed|dream)(?!\p{L})', r'i had a (?:dream|nightmare)',
    r'i was dreaming', r'во сне', r'(?:снилось|приснилось|приснился|приснилась)',
    r'в (?:моем |этом )?(?:сне|кошмаре)',
  ]);

  static final waking = DreamSafetyText.words([
    r'şimdi', r'şu an(?:da)?(?!\p{L})', r'uyandim', r'uyandiğimda',
    r'uyaninca', r'uyandiktan', r'uyanikken', r'gerçek hayatta',
    r'gerçekte(?!\p{L})', r'bugün', r'artik', r'now(?!\p{L})', r'currently',
    r'today', r'i woke', r'woke up', r'after waking', r'awake',
    r'in real life', r'сейчас', r'теперь', r'сегодня', r'проснул', r'наяву',
    r'в реальной жизни', r'на самом деле',
  ]);

  /// Retrieved memory that must never enrich a provider request.
  static final memory = DreamSafetyText.words([
    r'intihar', r'kendime zarar', r'kendimi öldür', r'kendini öldür',
    r'self-harm', r'suicid', r'kill (?:myself|yourself)', r'самоубий',
    r'суицид', r'покончить с собой', r'şizofren', r'psikoz', r'tssb', r'ptsd',
    r'schizophren', r'psychosis', r'шизофрен', r'психоз', r'птср',
    r'tecavüz', r'taciz', r'istismar', r'raped?(?!\p{L})', r'sexual assault',
    r'molest', r'изнасил', r'насили', r'teşhis', r'diagnos', r'диагноз',
  ]);
}
