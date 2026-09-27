import type { AppLanguage } from './app-language.js';

/**
 * Phase 4B field roles — every Dream JSON field has one job. Appended to
 * the system message after the Phase 3 safety and Phase 4A history clauses
 * (both unchanged) and before the single language directive.
 */
export const DREAM_FIELD_ROLES: Record<AppLanguage, string> = {
  tr:
    'Premium sözleşme — her alanın kendi görevi var. ' +
    'summary rüyayı kendi sözlerinle hissedilen özüne indirger; olay örgüsünü cümle cümle yeniden anlatma. ' +
    'emotionalTheme anlatılan duyguya, olumsuzlanmış olanlar dahil, sadık kalır: "korkmadım" dendiyse korkuyu varmış gibi yazma. ' +
    'interpretation ayrıntılı bir rüyada en az iki farklı ayrıntı arasında ilişki kurar (az ayrıntılı bir rüya tek imgeyle kalabilir); tek bir imgede takılıp kalma. ' +
    'dailyLifeReflection bu rüyaya (ya da verilen ilgili geçmiş bağlama) aittir: rüyaya özgü, nazik bir fark ediş; "kendine güven", "kendine zaman ayır" gibi genel iyi oluş tavsiyesi değil. ' +
    'Rüya ya da verilen bağlam söylemedikçe "işin", "ilişkin", "ailen", "paran", "okulun", "sağlığın" ya da "çocukluğun" diye yazma; sembolik dil serbesttir. ' +
    'conclusion yanıttaki tek sorudur: bu rüyanın bir ayrıntısına dayanan tek açık soru (ne / nasıl / hangi / nerede…); evet/hayır sorusu sorma ve başka hiçbir alanda soru işareti kullanma.',
  en:
    'Premium contract — every field has its own job. ' +
    'summary compresses the dream into its felt essence in your own words; never retell the plot sentence by sentence. ' +
    'emotionalTheme honours the feelings the dreamer stated, including negated ones: if they said they were not afraid, never describe fear as present. ' +
    'interpretation builds a relational bridge between at least two different details of a detailed dream (a sparse dream may stay with one image); never dwell on a single image. ' +
    'dailyLifeReflection belongs to this dream (or to the given related past context): a gentle, dream-specific noticing, not generic wellness advice such as "trust yourself" or "take time for yourself". ' +
    'Never write "your work", "your relationship", "your family", "your money", "your school", "your health" or "your childhood" unless the dream or the given context names it; symbolic language is fine. ' +
    'conclusion is the only question anywhere: one open question (what / how / which / where…) grounded in a detail of this dream; never a yes/no question, and never a question mark in any other field.',
  ru:
    'Премиальный договор — у каждого поля своя задача. ' +
    'summary сжимает сон до его прочувствованной сути своими словами; не пересказывай сюжет предложение за предложением. ' +
    'emotionalTheme верно передаёт названные чувства, включая отрицаемые: если человек сказал, что ему не было страшно, не описывай страх как присутствующий. ' +
    'interpretation в подробном сне связывает минимум две разные детали (скупой сон может остаться с одним образом); не застревай на одном образе. ' +
    'dailyLifeReflection принадлежит этому сну (или данному связанному прошлому контексту): бережное наблюдение именно об этом сне, а не общий совет о благополучии вроде «доверься себе» или «удели время себе». ' +
    'Не пиши «твоя работа», «твои отношения», «твоя семья», «твои деньги», «твоя учёба», «твоё здоровье» или «твоё детство», если сон или данный контекст этого не называет; символический язык допустим. ' +
    'conclusion — единственный вопрос во всём ответе: один открытый вопрос (что / как / какой / где…), опирающийся на деталь этого сна; никаких вопросов «да/нет» и никаких вопросительных знаков в других полях.',
};
