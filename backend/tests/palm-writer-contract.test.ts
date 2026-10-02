/**
 * Palm writer and repair prompt contract: meaning-first lines, one natural
 * second-person voice, no invented life story, a descriptive takeaway.
 */

import { describe, expect, it } from 'vitest';
import { palmWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';

const palm = palmWriterSystem('tr');
const repair = repairWriterSystem('palm');

describe('Palm writer contract', () => {
  it('no longer asks each line to own its geometric description', () => {
    expect(palm).not.toContain('owns its own geometric description');
    expect(palm).not.toContain('practical reflection');
  });

  it('makes line sections meaning-first with geometry as supporting evidence only', () => {
    expect(palm).toContain('meaning first');
    expect(palm).toContain('geometry is supporting evidence only');
    expect(palm).toContain('Never write a standalone geometry sentence');
    expect(palm).toContain('never list length, direction, depth, curve, and continuity');
    expect(palm).toContain("Stay within that line's own evidence");
    expect(palm).toContain('Never fabricate fateLine');
  });

  it('frames any example as structure only', () => {
    expect(palm).toContain('Structure only, never wording to copy');
  });

  it('requires one warm second-person voice and bans the textbook, coach, and profile voices', () => {
    expect(palm).toContain('natural second-person palm reading');
    expect(palm).toContain('Not a reference book, therapist, coach, visual report, or third-person profile');
    expect(palm).toContain('Keep the same second person in every section');
    for (const phrase of ['ilişkilendirilir', 'bağdaştırılır', 'karşılık gelir', 'olarak okunur/yorumlanır']) {
      expect(palm).toContain(phrase);
    }
    expect(palm).toContain('never mechanical');
  });

  it('forbids an invented life story unless personalization states it', () => {
    expect(palm).toContain('NO INVENTED LIFE STORY');
    for (const item of [
      'any other specific person',
      'what someone else sees, thinks, feels, or intends',
      'a current conflict or decision',
      'a waiting period',
      'a past or ongoing attachment',
      'a plan',
      'unless personalization literally states it',
    ]) {
      expect(palm).toContain(item);
    }
  });

  it('defines an additive, descriptive, evidence-bound takeaway without advice', () => {
    expect(palm).toContain('one new descriptive synthesis');
    expect(palm).toContain('grounded in the cited evidence');
    for (const banned of ['restate geometry', 'repeat overall', 'introduce another person', 'invent a situation', 'commands, advice, or homework']) {
      expect(palm).toContain(banned);
    }
    expect(palm).toContain('A shorter honest takeaway beats padding');
  });

  it('allows a shared theme but forbids restating one trait family across lanes', () => {
    expect(palm).toContain('A shared central theme is fine; repetition is not');
  });

  it('keeps medical and certain-future claims out and overrides the shared next-step guidance', () => {
    expect(palm).toContain('any diagnosis');
    expect(palm).toContain('never state the future as certain');
    expect(palm).toContain('PALM PRECEDENCE');
  });
});

describe('Palm repair contract', () => {
  it.each([
    'dictionary_voice',
    'unsupported_other_person',
    'presumed_user_state',
    'coaching_voice',
    'person_switch',
    'prohibited_claim or unsupported_certainty',
    'section_redundancy (palm)',
  ])('guides repair for %s', (code) => {
    expect(repair).toContain(`If ${code}`);
  });

  it('removes medical and certainty claims instead of softening them', () => {
    expect(repair).toContain('remove the medical, lifespan, or certain-future statement completely');
  });

  it('Coffee repair receives none of the palm-only guidance', () => {
    const coffee = repairWriterSystem('coffee');
    expect(coffee).not.toContain('If dictionary_voice');
    expect(coffee).not.toContain('If person_switch');
    expect(coffee).not.toContain('(palm)');
  });
});
