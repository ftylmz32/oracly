/**
 * Palm guardrails calibrated on real provider output. Fixtures and their
 * human verdicts are frozen evidence: read here, never edited.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { evaluatePalmQuality, foldTr, type PalmQualityInput } from '../src/ai/human-quality.js';
import {
  coachingVoice,
  conceptEcho,
  dictionaryVoice,
  inventsOtherPerson,
  personSwitch,
  presumesUserState,
} from '../src/ai/palm-quality-guards.js';

type Sections = Record<string, unknown>;

const text = (v: unknown) => (typeof v === 'string' ? v : ((v as { text?: string })?.text ?? ''));
const json = (path: string) => JSON.parse(readFileSync(path, 'utf8'));

function palmInput(s: Sections, themes?: string[]): PalmQualityInput {
  return {
    visualObservation: text(s.visualObservation),
    overall: text(s.overall),
    lifeLine: text(s.lifeLine),
    headLine: text(s.headLine),
    heartLine: text(s.heartLine),
    fateLine: text(s.fateLine),
    takeaway: text(s.takeaway),
    language: 'tr',
    trustedHandSide: true,
    relevantThemes: themes,
  };
}

const real = (name: string) => json(`../test/features/palm/fixtures/real/${name}.json`);
const b3a4 = real('palm_real_batch3a4');
const e3h1 = real('palm_real_e3h1');
const b3a2 = json('./tests/fixtures/batch3a/palm_live_3a2.json');

const CORPUS: Array<{ id: string; human: string; input: PalmQualityInput }> = [
  { id: 'E3H.1', human: e3h1.humanVerdict, input: palmInput(e3h1.backend) },
  { id: '3A.4', human: b3a4.humanVerdict, input: palmInput(b3a4.backend) },
  { id: '3A.2', human: 'FAIL', input: palmInput(b3a2.narrative, b3a2.personalization.relevantThemes) },
  { id: 'E3H', human: 'FAIL', input: palmInput(json('./tests/fixtures/e3h1/e3h_palm_live_negative.json')) },
  { id: 'E3F', human: 'FAIL', input: palmInput(json('./tests/fixtures/e3g/e3f_palm_negative.json')) },
];

function lanes(i: PalmQualityInput) {
  return {
    overall: foldTr(i.overall),
    lifeLine: foldTr(i.lifeLine),
    headLine: foldTr(i.headLine),
    heartLine: foldTr(i.heartLine),
    fateLine: foldTr(i.fateLine),
    takeaway: foldTr(i.takeaway),
  };
}

describe('Palm guardrails — real corpus calibration', () => {
  it('frozen human verdicts are the ones this calibration targets', () => {
    expect(e3h1.humanVerdict).toBe('WEAK');
    expect(b3a4.humanVerdict).toBe('FAIL');
  });

  it.each(CORPUS)('$id (human $human) never passes the gate', ({ input }) => {
    expect(evaluatePalmQuality(input)).not.toBeNull();
  });

  it('3A.4 — previously a gate PASS — is now rejected', () => {
    expect(evaluatePalmQuality(CORPUS[1].input)).toBe('unsupported_other_person');
  });

  it('3A.4 trips every voice defect the human audit named, each independently', () => {
    const l = lanes(CORPUS[1].input);
    const read = Object.values(l).filter(Boolean);
    expect(read.some(dictionaryVoice)).toBe(true);
    expect(read.some(inventsOtherPerson)).toBe(true);
    expect(read.some(presumesUserState)).toBe(true);
    expect(read.some(coachingVoice)).toBe(true);
    expect(personSwitch(read)).toBe(true);
    expect(conceptEcho(l)).toBe(true);
  });

  it('E3H.1 is rejected for repetition and its textbook voice is detected', () => {
    const l = lanes(CORPUS[0].input);
    expect(evaluatePalmQuality(CORPUS[0].input)).toBe('section_redundancy');
    expect(Object.values(l).some(dictionaryVoice)).toBe(true);
    expect(conceptEcho(l)).toBe(true);
    expect(personSwitch(Object.values(l))).toBe(false);
  });

  it('E3H coaching takeaway is detected even behind its earlier disclaimer verdict', () => {
    expect(coachingVoice(foldTr(CORPUS[3].input.takeaway))).toBe(true);
  });

  it('3A.2 keeps its stock-advice rejection', () => {
    expect(evaluatePalmQuality(CORPUS[2].input)).toBe('stock_advice');
  });
});
