export const OR_SPEECH_SPEEDS = ['slow', 'normal', 'fast'] as const;

export type OrSpeechSpeed = (typeof OR_SPEECH_SPEEDS)[number];

const DEFAULT_SPEED: OrSpeechSpeed = 'normal';

const MUL: Record<OrSpeechSpeed, number> = {
  slow: 0.9,
  normal: 1,
  fast: 1.12,
};

export function parseOrSpeechSpeed(input: unknown): OrSpeechSpeed {
  if (typeof input !== 'string') return DEFAULT_SPEED;
  const value = input.trim().toLowerCase();
  return OR_SPEECH_SPEEDS.includes(value as OrSpeechSpeed)
    ? (value as OrSpeechSpeed)
    : DEFAULT_SPEED;
}

/** Keep fast intelligible — natural band only. */
export function applySpeechSpeed(base: number, speed: OrSpeechSpeed): number {
  const next = base * MUL[speed];
  return Math.min(1.15, Math.max(0.85, next));
}
