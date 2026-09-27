/// Dream Phase 3 provider-output lexicon — folded TR/EN/RU assertions a
/// reading must never make. Static catalog; mirrored verbatim in
/// `backend/src/ai/dream-safety-lexicon.ts`. Every check is negation-aware.
library;

import 'dream_safety_text.dart';

abstract final class DreamOutputLexicon {
  DreamOutputLexicon._();

  static final selfHarm = DreamSafetyText.words([
    r'kendine zarar ver(?:melisin|men gerek|meyi düşün(?:melisin|(?!\p{L}))|(?!\p{L}))',
    r'kendini öldür(?:melisin|men gerek|(?!\p{L}))',
    r'intihar et(?:melisin|men gerek|meyi düşün(?:melisin|(?!\p{L}))|(?!\p{L}))',
    r'(?:canina kiy|hayatina son ver)(?:malisin|melisin|(?!\p{L}))',
    r'(?:you should|you must|you need to|you have to|go ahead and) (?:hurt|harm|kill|cut) yourself',
    r'(?:hurt|harm|kill|cut) yourself',
    r'(?:end|take) your (?:own )?life',
    r'(?:тебе стоит|тебе нужно|тебе надо|ты должен|ты должна) (?:причинить себе вред|убить себя|покончить с собой|навредить себе)',
    r'(?:убей себя|покончи с собой|причини себе вред|навреди себе)',
  ]);

  static final medical = DreamSafetyText.words([
    r'ila[cç]\p{L}* (?:birak|kes)(?:malisin|(?!\p{L}))',
    r'tedavi\p{L}* (?:birak|kes)(?:malisin|(?!\p{L}))',
    r'(?:doktora|terapiye|psikiyatriste) gitme(?:ne gerek yok|(?!\p{L}))',
    r'(?:doktora|ilaca|ilaçlara|terapiye|tedaviye) ihtiyacin yok',
    r'stop (?:taking )?(?:your )?(?:medication|medicine|meds|pills|treatment)',
    r"(?:don't|do not) need (?:a doctor|medication|medicine|therapy|treatment|meds)",
    r"(?:don't|do not|never) (?:see|go to|visit) (?:a |your )?(?:doctor|therapist|psychiatrist)",
    r'skip (?:your )?(?:medication|meds|therapy|treatment)',
    r'avoid (?:doctors|therapy|treatment)',
    r'(?:брось|бросьте|прекрати|перестань) (?:принимать )?(?:лекарств|таблетк|лечени)',
    r'не ходи к врачу',
    r'не нужен врач',
    r'тебе не нужн[ыо] (?:лекарства|таблетки|лечение)',
  ]);

  static final diagnosis = DreamSafetyText.words([
    r'(?:şizofren|bipolar|psikoz|psikotik|depresyon|akil hastasi|ruh hastasi|tssb|ptsd|travma sonrasi stres)\p{L}* (?:olduğunu|olduğun) (?:gösteriyor|kanitliyor|doğruluyor)',
    r'(?:şizofren|bipolar|psikotik|akil hastasi|ruh hastasi|psikozda|depresyonda)sin(?!\p{L})',
    r'(?:tssb|ptsd|travma sonrasi stres bozukluğu)\S* (?:var|yaşiyorsun)(?!\p{L})',
    r'(?:proves?|shows?|means?|indicates?|confirms?|suggests?) (?:that )?you (?:have|are|suffer from) (?:(?:a|an|some) )?(?:schizophreni|bipolar|psychos|psychotic|ptsd|post-?traumatic|depress|mentally ill|mental illness|adhd|autis|cancer|dementia)',
    r"you(?: have| suffer from|'re| are) (?:(?:a|an) )?(?:schizophreni|bipolar|psychos|psychotic|ptsd|post-?traumatic|mentally ill|mental illness|dementia)",
    r'(?:у тебя|ты страдаешь) (?:шизофрени|биполяр|психоз|птср|депресси|посттравматическ)',
    r'ты психически (?:болен|больна)',
  ]);

  static final delusion = DreamSafetyText.words([
    r'(?:gerçekten|kesinlikle|gerçek hayatta|dış dünyada) (?:seni |sizi |sana )?(?:izliyor|izleniyorsun|takip ediyor|takip ediliyorsun|gözetliyor|mesaj gönderiyor|mesaj yolluyor|iletişim kuruyor)',
    r'(?:seni|sizi) (?:gerçekten|kesinlikle|gizlice) (?:izliyor|takip ediyor|gözetliyor)',
    r'(?:izlediğini|takip ettiğini|izlendiğini|mesaj gönderdiğini|iletişim kurduğunu) (?:kanitliyor|doğruluyor|gösteriyor)',
    r'(?:is|are) (?:really|truly|definitely|actually) (?:watching|following|monitoring|tracking|spying on|communicating with|sending) you',
    r"you(?:'re| are) (?:really |truly |definitely |actually )being (?:watched|followed|monitored|tracked)",
    r'(?:proves?|confirms?) (?:that )?(?:someone|somebody|they|the government|the police|spirits|aliens|jinn|demons|ghosts)',
    r'(?:действительно|на самом деле|точно) (?:следят|следит|наблюдают|общаются|посылают)',
    r'за тобой (?:действительно|на самом деле|точно) следят',
    r'(?:доказывает|подтверждает),? что (?:за тобой|духи|инопланетяне|правительство|джинны)',
  ]);

  static final traumaTerms = DreamSafetyText.words([
    r'istismar', r'taciz', r'tecavüz', r'saldiri', r'şiddet', r'travma',
    r'yaşadiklarin', r'başina gelen', r'abuse', r'assault', r'raped?(?!\p{L})',
    r'molest', r'trauma', r'violence', r'what happened to you', r'насили',
    r'изнасил', r'травм', r'надругател', r'домогател',
  ]);

  static final blame = DreamSafetyText.words([
    r'bir (?:sebeple|nedenle)', r'karma(?:n|nin|nda)?(?!\p{L})', r'karmik',
    r'hak ettin', r'senin suçun', r'sen sebep oldun',
    r'kaderin(?:di|de vardi)?(?!\p{L})', r'bir ders (?:olarak|vermek|almalisin)',
    r'cezasi', r'happened for a reason', r'karmic', r'you deserved',
    r'your fault', r'you caused', r'you brought (?:it|this) on',
    r'punishment', r'meant to happen', r'your destiny', r'a lesson (?:for you|you)',
    r'fated', r'не случайно', r'по какой-то причине', r'карм(?:а|ы|ическ)',
    r'заслужил', r'твоя вина', r'ты виноват', r'наказани', r'судьб', r'суждено',
    r'урок',
  ]);

  static final death = DreamSafetyText.words([
    r'öleceksin', r'ölümün yakin', r'yakinda öle(?:ceksin|cek)', r'biri ölecek',
    r'birini kaybedeceksin', r'kaza geçireceksin',
    r'you (?:will|are going to) die', r"you'll die",
    r'your death is (?:near|coming|close)',
    r'someone (?:close to you )?(?:will|is going to) die',
    r'ты (?:скоро )?умрешь', r'твоя смерть близка', r'кто-то (?:из близких )?умрет',
  ]);
}
