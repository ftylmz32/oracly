import type { ChatPersonality } from './chat-style.js';
import { parseOrVoiceId, voiceTimbre, type OrVoiceId } from './or-voice.js';
import {
  applySpeechSpeed,
  parseOrSpeechSpeed,
} from './or-speech-speed.js';

export type TtsRequest = {
  voice: string;
  speed: number;
  instructions: string;
  hdVoice: string;
  hdSpeed: number;
};

const OR =
  'You are Or — one presence. Voice options change expression only, ' +
  'never character. Thinking aloud to a friend — not reading a document. ' +
  'Connect words. Turkish linking (ulama) is required. Never isolate ' +
  'syllables or give each word equal time. Function words are quick; ' +
  'a word that carries feeling gets a little weight, never a shout. ' +
  'A comma is a slight breath, not a stop. An ellipsis is one short ' +
  'think — never three stops — then you continue on the same thought. ' +
  'A greeting plus a question stays one phrase and rises at the end. ' +
  'Questions rise; nasılsın, ne yapardın, -mi / -mı / değil mi must ' +
  'not sound like statements. A period closes a thought, then you continue. ' +
  'Vary how sentences end: some land softly, some stay open. ' +
  'Never theatre. Never a metronome. Never the same falling cadence ' +
  'twice in a row. Never name punctuation. ' +
  'Do not sound like phone TTS, GPS, or IVR.';

export function ttsStyle(
  personality: ChatPersonality | undefined,
  language: string,
  voiceId?: string,
  speechSpeed?: string,
): TtsRequest {
  const identity = parseOrVoiceId(voiceId);
  const tempo = parseOrSpeechSpeed(speechSpeed);
  const timbre = voiceTimbre(identity);
  const spoken = languageName(language);
  const lang =
    `The text is ${spoken}. Pronounce it as a native in private conversation. ` +
    `Vowels stay ${spoken}. Stress meaning, not every syllable.`;
  const delivery = deliveryOf(personality, identity);
  const speed = applySpeechSpeed(delivery.speed, tempo);
  return {
    voice: timbre.voice,
    speed,
    hdVoice: timbre.hdVoice,
    hdSpeed: speed,
    instructions: `${OR} ${lang} ${timbre.line} ${delivery.line}`,
  };
}

function deliveryOf(
  personality: ChatPersonality | undefined,
  identity: OrVoiceId,
): { speed: number; line: string } {
  const soft = identity === 'calm' || identity === 'bright';
  switch (personality) {
    case 'gentle':
      return {
        speed: soft ? 0.98 : 0.99,
        line: 'Softer, unhurried, still conversational. One thought at a time.',
      };
    case 'poetic':
      return {
        speed: 1.0,
        line: 'Warmer chat rhythm, like thinking with a friend.',
      };
    case 'direct':
      return {
        speed: 1.02,
        line: 'Shorter thoughts, decisive. Still a person, not a prompt.',
      };
    default:
      return {
        speed: soft ? 0.99 : 1.0,
        line: 'Quiet curiosity in the room. Never a mystic performance.',
      };
  }
}

function languageName(language: string): string {
  const code = language.toLowerCase();
  if (code.startsWith('en')) return 'English';
  if (code.startsWith('ru')) return 'Russian';
  return 'Turkish';
}
