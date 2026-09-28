import type { AppLanguage } from './app-language.js';

/**
 * Dream field rules (Phase 4B, tightened in 4C.1) — the single place each
 * JSON field's job is stated. Appended to the system message after the
 * Phase 3 safety and Phase 4A history clauses (both unchanged) and before
 * the single language directive. The persona and the user lead no longer
 * repeat these rules.
 */
export const DREAM_FIELD_ROLES: Record<AppLanguage, string> = {
  tr:
    'Alan kuralları — her alanın tek bir görevi var. ' +
    'summary: rüyayı kendi sözlerinle hissedilen özüne indiren tek ve kısa bir cümle; olayları sırayla anlatma, olay örgüsünü yeniden anlatma. ' +
    'symbols: yalnızca rüyacının yazdığı somut isim öbekleri, aynı sözcüklerle ("tren istasyonu", "eski arkadaş"); sözcüğü soyut bir isme çevirme (sessizce → sessizlik, ağladım → ağlama, karanlık → karanlığın kendisi); duyguyu sembol olarak yazma; emin olmadığını çıkar, boş liste olabilir. ' +
    'emotionalTheme: belirtilen duygulara, olumsuzlanmış olanlar dahil, sadık kal: "korkmadım" dendiyse korkuyu varmış gibi yazma; karışık duyguları ve bir duygunun yokluğunu söylendiği gibi koru; anlatı cümlelerini olduğu gibi tekrarlama; duyguyu rüyadaki tek bir somut ayrıntıya bağla; anlatılmayan duygu uydurma. ' +
    'interpretation: bir sembolü bir anlama eşleme ("X, Y\'yi temsil eder / simgeler / demektir" yok); ilişkisel bir köprü kur: bir somut ayrıntının diğerini nasıl değiştirdiğini, onunla nasıl karşıtlık kurduğunu, onu nasıl böldüğünü, yumuşattığını ya da çerçevelediğini göster; iki ayrıntıyı yalnızca yan yana anmak yetmez; anlatılan duygusal ipuçlarını yoruma katıştır; ayrıntılı bir rüyada en az iki somut ayrıntı kullan (az ayrıntılı bir rüya tek imgeyle kalabilir); kapı = seçim, su = duygular, dağ = zorluk, ışık = içgörü, anahtar = fırsat gibi otomatik okumalar yapma. ' +
    'dailyLifeReflection: bu rüyanın bir somut ayrıntısını (ya da verilen ilgili geçmiş bağlamı) taşı; "kendine güven", "iç sesini dinle", "kendine zaman ayır", "değişimi kucakla", "yeni deneyimlere açık ol" gibi genel tavsiye verme; soru işareti kullanma; uyanık hayata dair bir sorun uydurma. ' +
    'Rüya ya da verilen bağlam söylemedikçe "işin", "ilişkin", "ailen", "paran", "okulun", "sağlığın" ya da "çocukluğun" diye yazma; sembolik dil serbesttir. ' +
    'conclusion: yanıttaki tek soru — bu rüyanın somut bir ayrıntısını anan tek açık soru (ne / nasıl / hangi / nerede…); evet/hayır sorusu sorma ve başka hiçbir alanda soru işareti kullanma.',
  en:
    'Field rules — every field has one job. ' +
    'summary: one concise sentence that compresses the dream into its felt essence in your own words; never narrate the sequence or retell the plot. ' +
    'symbols: only exact noun phrases the dreamer wrote, in the same words ("train station", "old friend"); never turn a word into an abstraction (dark → darkness, cried → crying, quiet → silence); never list a feeling as a symbol; omit anything uncertain — an empty list is fine. ' +
    'emotionalTheme: honour the feelings the dreamer stated, including negated ones — if they said they were not afraid, never describe fear as present; keep mixtures and absences as told; never repeat narrative sentences verbatim; tie the feeling to one concrete detail of the dream; never invent a feeling. ' +
    'interpretation: never map a symbol to a meaning ("X represents / symbolizes / means Y"); build a relational bridge instead: show how one concrete detail changes, contrasts with, interrupts, softens or frames another; merely mentioning two details side by side is not enough; weave the stated emotional cues into it; a detailed dream needs at least two concrete details (a sparse dream may stay with one image); no automatic readings such as door = choice, water = emotions, mountain = challenge, light = insight or key = opportunity. ' +
    'dailyLifeReflection: carry one concrete detail of this dream (or the given related past context); no generic advice such as "trust yourself", "listen to your inner guide", "take time for yourself", "embrace change", "be open to new experiences" or "give yourself time"; no question mark; never invent a waking-life problem. ' +
    'Never write "your work", "your relationship", "your family", "your money", "your school", "your health" or "your childhood" unless the dream or the given context names it; symbolic language is fine. ' +
    'conclusion: the only question anywhere — exactly one open question (what / how / which / where…) that names a concrete detail of this dream; never a yes/no question, and never a question mark in any other field.',
  ru:
    'Правила полей — у каждого поля одна задача. ' +
    'summary: одно короткое предложение, которое своими словами сжимает сон до его прочувствованной сути; не пересказывай события по порядку и не пересказывай сюжет. ' +
    'symbols: только точные словосочетания, которые написал человек, теми же словами («вокзал», «старый друг»); не превращай слово в абстракцию (тёмный → темнота, плакала → плач, тихо → тишина); не записывай чувство как символ; всё сомнительное пропусти — пустой список допустим. ' +
    'emotionalTheme: верно передай названные чувства, включая отрицаемые: если человек сказал, что ему не было страшно, не описывай страх как присутствующий; сохраняй смешанные чувства и отсутствие чувства так, как сказано; не повторяй фразы рассказа дословно; свяжи чувство с одной конкретной деталью сна; не выдумывай чувств. ' +
    'interpretation: не сопоставляй символ со значением (никаких «X означает / символизирует / олицетворяет Y»); построй связь: покажи, как одна конкретная деталь меняет другую, контрастирует с ней, прерывает, смягчает или обрамляет её; просто упомянуть две детали рядом недостаточно; вплетай названные эмоциональные подсказки; в подробном сне нужны минимум две конкретные детали (скупой сон может остаться с одним образом); никаких автоматических прочтений вроде дверь = выбор, вода = эмоции, гора = испытание, свет = прозрение, ключ = возможность. ' +
    'dailyLifeReflection: сохрани одну конкретную деталь этого сна (или данного связанного прошлого контекста); никаких общих советов вроде «доверься себе», «прислушайся к внутреннему голосу», «удели время себе», «прими перемены», «будь открыт новому» или «дай себе время»; без вопросительного знака; не выдумывай проблему из жизни наяву. ' +
    'Не пиши «твоя работа», «твои отношения», «твоя семья», «твои деньги», «твоя учёба», «твоё здоровье» или «твоё детство», если сон или данный контекст этого не называет; символический язык допустим. ' +
    'conclusion: единственный вопрос во всём ответе — ровно один открытый вопрос (что / как / какой / где…), называющий конкретную деталь этого сна; никаких вопросов «да/нет» и никаких вопросительных знаков в других полях.',
};
