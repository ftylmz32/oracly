import { ruGood, ruNarrative } from './dream-phase2-fixtures.js';
import { golden } from './dream-phase4b-support.js';
import { bad, base, good, type CorpusBase, type CorpusCase } from './dream-phase4b-corpus-types.js';

const fromGolden = (id: string): CorpusBase => {
  const g = golden(id);
  return base(g.language, g.narrative, g.data, g.memorySummary ? { memorySummary: g.memorySummary } : {});
};

const lake = fromGolden('ru-rich-negated-fear');
const station = fromGolden('ru-sparse-station');
const garden = fromGolden('ru-family-supported-memory');
const forest = base('ru', ruNarrative, ruGood);
const stairs = base('ru', 'Во сне за мной по лестнице в подъезде шла чёрная собака, и мне было очень страшно.', {
  summary: 'Сон передаёт страх от чёрной собаки, которая идёт следом по лестнице подъезда.',
  symbols: ['чёрная собака', 'лестница'],
  emotionalTheme: 'Страх, который растёт, пока собака идёт за тобой по лестнице.',
  interpretation:
    'Чёрная собака, идущая следом по лестнице подъезда, придаёт страху форму, которая остаётся рядом, но не нападает; узкое пространство подъезда может делать это преследование особенно тяжёлым.',
  dailyLifeReflection: 'Сегодня можно заметить, что в твоём дне похоже на эту собаку на лестнице — то, что тихо идёт следом.',
  conclusion: 'Что бы ты увидела, если бы обернулась к собаке на лестнице?',
});
const office = base('ru', 'Мне снилось, что я на работе, в офисе погас свет, а коллеги исчезли. Я чувствовала любопытство.', {
  summary: 'Сон превращает привычный офис в тёмное и тихое место, где любопытство сильнее растерянности.',
  symbols: ['офис', 'свет', 'коллеги'],
  emotionalTheme: 'Любопытство в тёмном офисе, где погас свет и исчезли коллеги.',
  interpretation:
    'Погасший свет в офисе и исчезнувшие коллеги оставляют тебя одну на работе, но вместо тревоги появляется любопытство: пустое привычное место вдруг становится пространством, которое можно рассмотреть заново.',
  dailyLifeReflection: 'Сегодня можно заметить, где на твоей работе стало тихо, как в офисе без света.',
  conclusion: 'Что бы ты захотела рассмотреть в этом тёмном офисе первым?',
});

export const ruCorpus: CorpusCase[] = [
  good('ru-g-lake', lake),
  good('ru-g-station-sparse-one-anchor', station),
  good('ru-g-family-present-memory', garden),
  good('ru-g-forest', forest),
  good('ru-g-stated-fear', stairs),
  good('ru-g-work-present', office),
  good('ru-g-fear-absent-theme', lake, { emotionalTheme: 'Страха нет; на ночном озере только спокойствие.' }),
  good('ru-g-what-waited', station, { conclusion: 'Что ждало тебя на пустом вокзале?' }),
  good('ru-g-summary-reuses-window', forest, { summary: 'Светящееся окно в тихом лесу собирает сон вокруг спокойного ожидания.' }),
  good('ru-g-work-address-supported', office, { dailyLifeReflection: 'Сегодня можно спокойно посмотреть на одно дело на твоей работе, как на офис, где погас свет.' }),
  good('ru-g-memory-reflection', garden, { dailyLifeReflection: 'Недавнее чтение о границах и поиске выхода может подсказать один маленький шаг сегодня.' }),
  good('ru-g-kak-question', lake, { conclusion: 'Как бы изменился путь, если бы костёр на берегу погас?' }),
  good('ru-g-observed-emotion', station, { emotionalTheme: 'Спокойное ожидание на пустом вокзале, без спешки.' }, { emotions: ['спокойствие'] }),
  good('ru-g-pochemu-question', forest, { conclusion: 'Почему окно старого дома светилось именно для тебя?' }),
  good('ru-g-three-anchor-interp', lake, {
    interpretation:
      'Лодка скользит по ночному озеру между двумя светами: огромная луна остаётся далеко над водой, а костёр на берегу обещает близкое тепло, и спокойствие держит этот путь ровным.',
  }),
  good('ru-g-anxiety-stated', garden, { emotionalTheme: 'Тревога растёт, пока ты ходишь вдоль забора и ищешь калитку.' }),

  bad('ru-b-thin-theme', station, 'thin_section', { emotionalTheme: 'Тихо и пусто.' }),
  bad('ru-b-question-summary', lake, 'extra_question', { summary: 'Куда плывёт маленькая лодка по ночному озеру к костру на берегу?' }),
  bad('ru-b-question-theme', station, 'extra_question', { emotionalTheme: 'Тихое ожидание на пустом вокзале — или это одиночество?' }),
  bad('ru-b-question-interp', forest, 'extra_question', { interpretation: `${ruGood.interpretation} Может быть, окно ждёт именно тебя?` }),
  bad('ru-b-question-reflection', garden, 'extra_question', { dailyLifeReflection: 'Где сегодня в твоём дне есть такая же калитка в заборе, которую трудно найти?' }),
  bad('ru-b-symbol-dupe', forest, 'symbol_list', { symbols: ['окно', 'Окно', 'лес'] }),
  bad('ru-b-symbol-many', lake, 'symbol_list', {
    symbols: ['маленькой', 'лодке', 'ночному', 'озеру', 'водой', 'огромная', 'луна', 'берегу', 'костёр'],
  }),
  bad('ru-b-recap-lake', lake, 'plot_recap', { summary: 'Ты плыла на маленькой лодке по ночному озеру, над водой висела огромная луна.' }),
  bad('ru-b-recap-garden', garden, 'plot_recap', { summary: 'Мама звала тебя из сада, но ты не могла найти калитку.' }),
  bad('ru-b-fear-affirmed', lake, 'emotion_contradiction', { emotionalTheme: 'Глубокий страх над ночным озером и лодкой.' }),
  bad('ru-b-calm-denied', lake, 'emotion_contradiction', { emotionalTheme: 'Никакого спокойствия: лодка на озере кажется чужой.' }),
  bad('ru-b-fear-denied', stairs, 'emotion_contradiction', { emotionalTheme: 'Страха нет, собака на лестнице просто идёт рядом.' }),
  bad('ru-b-anxiety-denied', garden, 'emotion_contradiction', { emotionalTheme: 'Без тревоги: ходьба вдоль забора остаётся лёгкой.' }),
  bad('ru-b-ungrounded-theme', forest, 'ungrounded_section', { emotionalTheme: 'Общее ощущение перемен и новых возможностей впереди.' }),
  bad('ru-b-ungrounded-summary', stairs, 'ungrounded_section', { summary: 'История о трансформации, завершениях и новых начинаниях.' }),
  bad('ru-b-shallow-lake', lake, 'weak_interpretation', { interpretation: 'Луна — символ интуиции и скрытых чувств, её мягкое сияние может говорить о том, что внутреннее знание уже рядом.' }),
  bad('ru-b-shallow-garden', garden, 'weak_interpretation', { interpretation: 'Образ сада — это образ внутреннего покоя, к которому хочется вернуться, когда вокруг становится слишком шумно.' }),
  bad('ru-b-shallow-office', office, 'weak_interpretation', { interpretation: 'Погасший свет может говорить о паузе, когда привычная ясность ненадолго уходит и нужно подождать.' }),
  bad('ru-b-wellness-only', station, 'generic_reflection', { dailyLifeReflection: 'Сегодня доверься себе и прислушайся к своей интуиции.' }),
  bad('ru-b-wellness-anchored', lake, 'generic_reflection', { dailyLifeReflection: 'У костра на берегу доверься себе и верь в себя.' }),
  bad('ru-b-generic-rest', forest, 'generic_reflection', { dailyLifeReflection: 'Сегодня найди время для себя и просто хорошо отдохни.' }),
  bad('ru-b-work-invented', lake, 'unsupported_personal_fact', { dailyLifeReflection: 'Сегодня на твоей работе может пригодиться то же спокойствие, что в лодке на озере.' }),
  bad('ru-b-relationship-invented', station, 'unsupported_personal_fact', { interpretation: `${station.data.interpretation} Возможно, так ощущаются твои отношения сейчас.` }),
  bad('ru-b-family-invented', forest, 'unsupported_personal_fact', { dailyLifeReflection: 'Сегодня можно вспомнить, как твоя семья светит тебе, словно окно за деревьями.' }),
  bad('ru-b-money-invented', stairs, 'unsupported_personal_fact', { interpretation: `${stairs.data.interpretation} Возможно, так за тобой идут твои долги.` }),
  bad('ru-b-school-invented', garden, 'unsupported_personal_fact', { dailyLifeReflection: 'Сегодня можно поискать калитку в твоей учёбе, где забор кажется высоким.' }),
  bad('ru-b-health-invented', office, 'unsupported_personal_fact', { dailyLifeReflection: 'Сегодня стоит подумать о твоём здоровье, как об офисе, где погас свет.' }),
  bad('ru-b-childhood-invented', station, 'unsupported_personal_fact', { dailyLifeReflection: 'Сегодня пустой вокзал может напомнить о твоём детстве и долгом ожидании.' }),
  bad('ru-b-yes-no-gotova', forest, 'weak_conclusion', { conclusion: 'Ты готова заглянуть в окно старого дома?' }),
  bad('ru-b-yes-no-hochesh', lake, 'weak_conclusion', { conclusion: 'Хочешь ли ты снова оказаться в лодке на озере?' }),
  bad('ru-b-ungrounded-question', stairs, 'weak_conclusion', { conclusion: 'Чего ты на самом деле хочешь от жизни?' }),
  bad('ru-b-two-questions', garden, 'conclusion_not_question', { conclusion: 'Где была калитка? Почему мама звала тебя?' }),
];
