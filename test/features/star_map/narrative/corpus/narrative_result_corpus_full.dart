/// Full-scope positive corpus TR/EN/RU.
library;

import 'narrative_full_map.dart';

abstract final class NarrativeFullCorpus {
  NarrativeFullCorpus._();

  static Map<String, dynamic> en() => narrativeFullMap(
        language: 'en',
        summary:
            'Sun in Taurus, Moon in Scorpio, and Virgo rising form a calm frame: '
            'steadiness, emotional depth, and careful presentation. Observation, '
            'not prophecy.',
        core:
            'Sun in Taurus may strengthen a need for solid ground. Mercury in '
            'Aries can quicken speech without erasing that steadiness.',
        emotion:
            'Moon in Scorpio in the 4 house hints at intense inner weather. '
            'The Sun–Moon opposition may feel like a pull between outer calm '
            'and private depth.',
        angles:
            'Virgo rising and the Sun linked with house 10 join presentation '
            'with responsibility. Venus in the 11 house softens friendship circles.',
        patterns:
            'A Venus–Mars sextile may ease friction. Jupiter and Saturn add '
            'social and structural tone without locking fate.',
        closing:
            'Let this reading remain a quiet companion, never a verdict.',
        reflect: 'Which habit helps you hold both steadiness and depth?',
        close: 'This reading rests on evidence and does not lock a future.',
      );

  static Map<String, dynamic> tr() => narrativeFullMap(
        language: 'tr',
        summary:
            'Güneş Boğa\'da, Ay Akrep\'te ve Başak yükseleni sakin bir çerçeve '
            'kurar: istikrar, duygusal derinlik ve dikkatli sunum. Bu bir gözlem; '
            'kehanet değil.',
        core:
            'Boğa Güneşi somut güven arayışını güçlendirebilir. Koç Merkür ise '
            'sözü hızlandırabilir; bu istikrarı iptal etmez.',
        emotion:
            'Akrep Ayı 4. evde iç dünyanın yoğunluğuna işaret edebilir. '
            'Güneş–Ay karşıtı, dış sakinlik ile özel derinlik arasında bir '
            'gerilim gibi hissedilebilir.',
        angles:
            'Başak yükseleni ve 10. evle bağlanan Güneş, sunumu sorumlulukla '
            'birleştirebilir. Venüs 11. evde dostluklara yumuşaklık katabilir.',
        patterns:
            'Venüs–Mars sekstili sürtünmeyi yumuşatabilir. Jüpiter ile Satürn '
            'toplumsal ve yapısal bir ton ekler; kadercilik yok.',
        closing: 'Bu okuma sessiz bir yol arkadaşı kalsın; hüküm olmasın.',
        reflect:
            'Hangi somut alışkanlık duygusal derinliğini taşımana yardım eder?',
        close: 'Bu okuma kanıtlara yaslanır; geleceği kilitlemez.',
      );

  static Map<String, dynamic> ru() => narrativeFullMap(
        language: 'ru',
        summary:
            'Солнце в Тельце, Луна в Скорпионе и асцендент в Деве образуют '
            'спокойный каркас: устойчивость, глубина чувств и внимательность '
            'к деталям. Это наблюдение по фактам, не предсказание.',
        core:
            'Солнце в Тельце может усиливать потребность в опоре. Вместе с '
            'Меркурием в Овне мысль иногда ускоряется, не отменяя спокойствия.',
        emotion:
            'Луна в Скорпионе в 4 доме намекает на интенсивность внутреннего '
            'мира. Оппозиция Солнце–Луна может ощущаться как напряжение между '
            'внешней стабильностью и глубиной чувств.',
        angles:
            'Асцендент в Деве и дом 10 с Солнцем связывают самопрезентацию с '
            'чувством ответственности. Венера в 11 доме поддерживает мягкость '
            'в круге общения.',
        patterns:
            'Секстиль Венеры и Марса может смягчать напряжение. Юпитер и Сатурн '
            'добавляют социальный и структурный фон без фатализма.',
        closing: 'Пусть это чтение останется тихой опорой, а не приговором.',
        reflect:
            'Какая привычка помогает держать и устойчивость, и глубину?',
        close: 'Это чтение опирается на факты и не запирает будущее.',
      );
}
