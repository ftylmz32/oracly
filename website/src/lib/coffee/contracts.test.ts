import { describe, expect, it } from 'vitest';
import { buildCoffeeV3CreateBody, sanitizeCoffeeIntention, WEB_SLOT_TO_SERVER_SLOT } from './contracts';

describe('Coffee V3 web contract', () => {
  it('maps the three web inputs to canonical V3 slots', () => {
    expect(WEB_SLOT_TO_SERVER_SLOT).toEqual({
      'cup-primary': 'v3_cup_view_a',
      'cup-secondary': 'v3_cup_view_b',
      saucer: 'v3_saucer_view',
    });
  });
  it('builds the exact Turkish trusted-intention create body', () => {
    expect(buildCoffeeV3CreateBody('web_request_1234', '  Aşk ve ilişkilerim hakkında  ')).toEqual({
      readingType: 'coffee', sourceRequestId: 'web_request_1234', language: 'tr',
      intention: 'Aşk ve ilişkilerim hakkında', coffeeInputContract: 'trusted_intention_v1',
      coffeeCaptureContract: 'three_view_v3',
    });
  });
  it('rejects empty, markup, control characters and overlong intentions', () => {
    expect(sanitizeCoffeeIntention('')).toBeNull();
    expect(sanitizeCoffeeIntention('<b>gelecek</b>')).toBeNull();
    expect(sanitizeCoffeeIntention('gelecek\u0000')).toBeNull();
    expect(sanitizeCoffeeIntention('a'.repeat(201))).toBeNull();
  });
});
