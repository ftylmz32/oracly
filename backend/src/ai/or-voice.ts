export const OR_VOICE_IDS = ['warm', 'calm', 'deep', 'bright'] as const;

export type OrVoiceId = (typeof OR_VOICE_IDS)[number];

const DEFAULT_VOICE: OrVoiceId = 'warm';

const LEGACY: Record<string, OrVoiceId> = {
  female_natural: 'warm',
  male_calm: 'calm',
  male_natural: 'deep',
  female_soft: 'bright',
};

export function parseOrVoiceId(input: unknown): OrVoiceId {
  if (typeof input !== 'string') return DEFAULT_VOICE;
  const value = input.trim().toLowerCase();
  if (OR_VOICE_IDS.includes(value as OrVoiceId)) return value as OrVoiceId;
  return LEGACY[value] ?? DEFAULT_VOICE;
}

export function voiceTimbre(id: OrVoiceId): {
  voice: string;
  hdVoice: string;
  line: string;
} {
  const original =
    'Original voice created for OR. Never imitate a celebrity, actor, ' +
    'or any real public person. Same OR — expression color only. ';
  switch (id) {
    case 'bright':
      return {
        voice: 'marin',
        hdVoice: 'sage',
        line:
          original +
          'Brighter mid register, close and kind across a small table. ' +
          'Clear, never a child, never a whisper, never breathy theatre.',
      };
    case 'deep':
      return {
        voice: 'cedar',
        hdVoice: 'echo',
        line:
          original +
          'Deeper chest color, a friend in the room. Clear, unforced. ' +
          'Not a radio host, not theatrical bass.',
      };
    case 'calm':
      return {
        voice: 'ash',
        hdVoice: 'ash',
        line:
          original +
          'Quieter pace, intimate and measured. Slightly lower. ' +
          'Never a meditation app, never broadcast news.',
      };
    default:
      return {
        voice: 'coral',
        hdVoice: 'coral',
        line:
          original +
          'Warm mid presence in everyday conversation. Confident, clear, ' +
          'unforced. Not a presenter, not a call-center prompt.',
      };
  }
}
