/// Static conversational affect cues — not clinical vocabulary.
library;

abstract final class OrEmotionalCues {
  OrEmotionalCues._();

  static const frustration = [
    'bıkt',
    'bikt',
    'sıkıld',
    'sikild',
    'sinir old',
    'yine aynı',
    'yine ayni',
    'again and again',
    'frustrated',
    'fed up',
    'достал',
    'бесит',
  ];

  static const excitement = [
    'heyecan',
    'çok mutlu',
    'cok mutlu',
    'harika haber',
    'cant wait',
    "can't wait",
    'so excited',
    'thrilled',
    'радост',
  ];

  static const uncertainty = [
    'emin değil',
    'emin degil',
    'bilmiyorum',
    'not sure',
    "i don't know",
    'uncertain',
    'не уверен',
  ];

  static const humor = [
    'şaka',
    'saka',
    'espri',
    'lol',
    'haha',
    '😂',
    'just kidding',
    'шутк',
  ];

  static const sadness = [
    'üzgün',
    'uzgun',
    // Avoid "ağl"/"agl" stems — they false-hit "bağla…" / "bagla…".
    'ağlıyor',
    'agliyor',
    'ağlad',
    'aglad',
    'ağlama',
    'aglama',
    'içim dar',
    'icim dar',
    'bunald',
    'canım sık',
    'canim sik',
    'yorgun',
    'i feel sad',
    'feeling sad',
    'so sad',
    'lonely',
    'груст',
  ];

  static const anger = [
    'öfke',
    'ofke',
    'çok kızg',
    'cok kizg',
    'nefret',
    'furious',
    'i hate',
    'angry at',
    'ярост',
  ];

  static const curiosity = [
    'merak',
    'acaba',
    'neden',
    'nasıl oluyor',
    'nasil oluyor',
    'curious',
    'i wonder',
    'how come',
    'интересн',
  ];

  static const indecision = [
    'kararsız',
    'kararsiz',
    'kafam karış',
    'kafam karis',
    'iki arada',
    'undecided',
    'torn between',
    "can't decide",
    'cant decide',
    'не реша',
  ];

  static const diagnosis = [
    'depresyondas',
    'depresyonsun',
    'you have depression',
    'you are bipolar',
    'bipolar bozukluğ',
    'anksiyete bozukluğ',
    'you have anxiety disorder',
    'ptsd',
    'borderline',
    'klinik teşhis',
    'diagnosed with',
    'у тебя депрессия',
  ];
}
