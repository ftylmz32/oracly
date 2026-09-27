import type { DreamData } from '../src/ai/parse-provider.js';

/** Synthetic Dream fixtures — no real user content, no provider prose. */
export const trNarrative = 'Ruyamda uzun bir yilan evden gecti ve sessizce gitti.';

export const trGood: DreamData = {
  summary: 'Ruya, evden sessizce gecen bir yilanla sakin bir gecis hissi tasiyor.',
  symbols: ['yilan'],
  emotionalTheme: 'Yilanin sessizce gidisinde belirsizlik ile sakinlik ayni anda duruyor.',
  interpretation:
    'Yilanin evden sessizce gecip gitmesi, tanidik bir alandan bir seyin gurultusuz ayrildigini dusunduruyor; burada tehdit degil, fark edilmeden olan bir gecis var.',
  dailyLifeReflection: 'Bugun acele etmeden, sessizce uzaklasan bir seyi fark etmek iyi gelebilir.',
  conclusion: 'Senin hayatinda sessizce gecip giden sey ne olabilir?',
};

export const trUnrelated: DreamData = {
  summary: 'Deniz kiyisinda parlayan bir fener huzurlu bir bekleyis anlatiyor.',
  symbols: [],
  emotionalTheme: 'Umutla karisik bir bekleyis tonu.',
  interpretation:
    'Fenerin karanlik denize isik tutmasi, uzaklardaki bir gemiyi karsilama istegini ve dalgalarin arasinda yol bulma cabasini birlikte tasiyor.',
  dailyLifeReflection: 'Bugun kiyida bekleyen bir fener gibi sabirli kalmak iyi gelebilir.',
  conclusion: 'Hangi limana dogru isik tutmak isterdin?',
};

export const enNarrative =
  'I was walking along a quiet beach at night and a red door stood in the sand; I felt calm, not afraid.';

export const enGood: DreamData = {
  summary: 'The dream holds a calm night walk where a red door appears on the quiet beach.',
  symbols: ['red door', 'beach'],
  emotionalTheme: 'Calm curiosity, with fear explicitly absent.',
  interpretation:
    'The red door standing in the sand turns the open beach into a threshold: the walk was quiet until something framed a choice, and your calm suggests you can look at that choice without rushing.',
  dailyLifeReflection:
    'Today you might notice one quiet place in your day that feels like a door you have not opened yet.',
  conclusion: 'What would you want to find if you opened that red door calmly?',
};

export const enUnrelated: DreamData = {
  summary: 'A lighthouse over a harbour keeps watch for a returning ship.',
  symbols: [],
  emotionalTheme: 'Hope mixed with patient waiting.',
  interpretation:
    'The lighthouse guiding a vessel across dark water joins longing and patience, suggesting a wish to welcome someone home after a long voyage over rough waves.',
  dailyLifeReflection: 'Today you could practise patience, like a lighthouse keeper on a long shift.',
  conclusion: 'Which harbour would you want to reach next?',
};

export const ruNarrative =
  'Мне снилось, что я шла по тихому лесу, а за деревьями светилось окно старого дома. Мне было спокойно.';

export const ruGood: DreamData = {
  summary: 'Во сне тихий лес ведёт к светящемуся окну старого дома, и это ощущается спокойно.',
  symbols: ['окно', 'лес'],
  emotionalTheme: 'Спокойствие и лёгкое любопытство.',
  interpretation:
    'Светящееся окно за деревьями превращает тихий лес в путь к чему-то знакомому: дом не зовёт тревожно, а мягко показывает, что тепло может ждать за тем, что пока скрыто.',
  dailyLifeReflection:
    'Сегодня можно заметить, где в твоём дне есть такое же тихое окно, куда хочется заглянуть.',
  conclusion: 'Что ты хотела бы увидеть в окне этого старого дома?',
};

export const ruUnrelated: DreamData = {
  summary: 'Маяк на берегу моря освещает путь далёкому кораблю.',
  symbols: [],
  emotionalTheme: 'Ожидание, смешанное с надеждой.',
  interpretation:
    'Маяк, стоящий над волнами, соединяет ожидание корабля и желание найти берег, поэтому образ говорит о терпении среди неспокойной воды.',
  dailyLifeReflection: 'Сегодня можно побыть терпеливым, как маяк, который ждёт корабль у берега.',
  conclusion: 'Какой берег ты хотела бы увидеть впереди?',
};
