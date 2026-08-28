import type { OpenAiMessage } from '../types.js';
import { palmSystem, palmUserLead } from './palm-style.js';
import { sanitizeText } from './sanitize.js';
import {
  responseLanguageDirective,
  type AppLanguage,
} from './app-language.js';

export function palmMessages(
  mimeType: string,
  base64: string,
  hand?: string,
  language: AppLanguage = 'tr',
): OpenAiMessage[] {
  const which = sanitizeText(hand ?? '', 16);
  const handLine = handNote(which, language);
  return [
    { role: 'system', content: `${palmSystem(language)} ${responseLanguageDirective(language)}` },
    {
      role: 'user',
      content: [
        {
          type: 'text',
          text: `${handLine} ${palmUserLead(language)}`,
        },
        {
          type: 'image_url',
          image_url: { url: `data:${mimeType};base64,${base64}` },
        },
      ],
    },
  ];
}

function handNote(which: string, language: AppLanguage): string {
  const left = which === 'left' || which === 'sol';
  const right = which === 'right' || which === 'sağ' || which === 'sag';
  switch (language) {
    case 'en':
      if (left) return 'The photo is marked as the left hand.';
      if (right) return 'The photo is marked as the right hand.';
      return 'The side of the hand was not specified.';
    case 'ru':
      if (left) return 'Фото отмечено как левая рука.';
      if (right) return 'Фото отмечено как правая рука.';
      return 'Сторона руки не указана.';
    default:
      if (left) return 'Fotoğraf sol el olarak işaretlendi.';
      if (right) return 'Fotoğraf sağ el olarak işaretlendi.';
      return 'El tarafı belirtilmedi.';
  }
}
