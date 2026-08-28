export type AppLanguage = 'tr' | 'en' | 'ru';

export function parseAppLanguage(raw: unknown): AppLanguage {
  const v = typeof raw === 'string' ? raw.trim().toLowerCase() : '';
  if (v.startsWith('en')) return 'en';
  if (v.startsWith('ru')) return 'ru';
  return 'tr';
}

export function responseLanguageDirective(language: AppLanguage): string {
  switch (language) {
    case 'en':
      return (
        'Respond entirely in English. Every user-facing sentence and every JSON string value must be English. Keep JSON keys unchanged. Do not mix languages.'
      );
    case 'ru':
      return (
        'Отвечай полностью на русском языке. Каждое предложение и каждое строковое значение JSON должны быть на русском. Ключи JSON не меняй. Не смешивай языки.'
      );
    default:
      return (
        'Yanıtı tamamen Türkçe yaz. Kullanıcıya görünen her cümle ve JSON içindeki her metin alanı Türkçe olsun. JSON anahtarlarını değiştirme. Dil karıştırma.'
      );
  }
}
