import type { AppLanguage } from './app-language.js';

/**
 * Long-term continuity is evidence about prior Oracly observations, not fresh
 * evidence from the current card/image/palm. Keep those epistemic layers apart.
 */
export function taggedContinuityGrounding(language: AppLanguage): string {
  switch (language) {
    case 'en':
      return (
        'Tagged FACT/OBSERVATION/INTERPRETATION context in this system message may be used only as grounded continuity from prior Oracly data. ' +
        'It is not evidence from the current cards, image, cup, or palm. Never turn it into a newly observed symbol, event, person, date, or certainty. ' +
        'If tagged continuity is absent or does not support a connection, do not claim to remember one.'
      );
    case 'ru':
      return (
        'Контекст с метками FACT/OBSERVATION/INTERPRETATION в этом системном сообщении можно использовать только как подтверждённую связь с прежними данными Oracly. ' +
        'Это не доказательство из текущих карт, изображения, чашки или ладони. Не превращай его в новый символ, событие, человека, дату или уверенный факт. ' +
        'Если помеченной связи нет или она не подтверждает вывод, не утверждай, что помнишь его.'
      );
    default:
      return (
        'Bu sistem mesajındaki FACT/OBSERVATION/INTERPRETATION etiketli bağlamı yalnızca önceki Oracly verilerinden gelen doğrulanmış süreklilik olarak kullan. ' +
        'Bu, mevcut kartın, görselin, fincanın veya avucun kanıtı değildir; onu yeni görülmüş sembole, olaya, kişiye, tarihe ya da kesinliğe dönüştürme. ' +
        'Etiketli süreklilik yoksa veya bağlantıyı desteklemiyorsa geçmişi hatırlıyormuş gibi konuşma.'
      );
  }
}
