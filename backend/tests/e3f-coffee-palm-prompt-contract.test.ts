import { describe, expect, it } from 'vitest';
import { coffeeSystem, coffeeUserLead } from '../src/ai/coffee-style.js';
import { palmSystem, palmUserLead } from '../src/ai/palm-style.js';

describe('E3F coffee prompt contract', () => {
  it('requires interior grounds and rejects foam-only / exterior primacy', () => {
    const en = coffeeSystem('en') + String.fromCharCode(10) + coffeeUserLead('en');
    const tr = coffeeSystem('tr') + String.fromCharCode(10) + coffeeUserLead('tr');
    const ru = coffeeSystem('ru') + String.fromCharCode(10) + coffeeUserLead('ru');
    expect(en.includes('usable:false')).toBe(true);
    expect(en.includes('cup interior')).toBe(true);
    expect(en.includes('milk/foam-only')).toBe(true);
    expect(en.toLowerCase().includes('overturned exterior')).toBe(false);
    expect(tr.includes('usable:false')).toBe(true);
    expect(ru.includes('usable:false')).toBe(true);
  });

  it('keeps AI disclosure ban', () => {
    expect(coffeeSystem('tr').toLowerCase().includes('yapay zeka olarak')).toBe(true);
    expect(coffeeSystem('tr').includes('hamilelik')).toBe(true);
  });
});

describe('E3F palm prompt contract', () => {
  it('requires one open palm and rejects dorsal/overlap', () => {
    const en = palmSystem('en') + String.fromCharCode(10) + palmUserLead('en');
    expect(en.includes('one clear open palm')).toBe(true);
    expect(en.includes('Dorsal/back-of-hand')).toBe(true);
    expect(en.includes('overlapping hands')).toBe(true);
    expect(en.toLowerCase().includes('second hand in the back')).toBe(false);
    expect(palmSystem('tr').includes('usable:false')).toBe(true);
    expect(palmSystem('ru').includes('usable:false')).toBe(true);
  });

  it('keeps biometric ban', () => {
    expect(palmSystem('tr').includes('Biyometrik kimlik')).toBe(true);
  });
});
