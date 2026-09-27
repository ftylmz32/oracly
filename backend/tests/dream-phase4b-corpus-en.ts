import { enGood, enNarrative } from './dream-phase2-fixtures.js';
import { golden } from './dream-phase4b-support.js';
import { bad, base, good, type CorpusBase, type CorpusCase } from './dream-phase4b-corpus-types.js';

const fromGolden = (id: string): CorpusBase => {
  const g = golden(id);
  return base(g.language, g.narrative, g.data, g.memorySummary ? { memorySummary: g.memorySummary } : {});
};

const beach = base('en', enNarrative, enGood);
const lighthouse = fromGolden('en-rich-negated-fear');
const horse = fromGolden('en-sparse-horse');
const packing = fromGolden('en-partner-supported-memory');
const office = base('en', 'I was at my work desk in a glass office, and my keyboard kept turning into warm sand. I felt anxious but curious.', {
  summary: 'The dream turns a familiar work desk into shifting sand, holding anxiety and curiosity together.',
  symbols: ['keyboard', 'sand', 'glass office'],
  emotionalTheme: 'Anxious, yet curious enough to keep watching the keyboard change.',
  interpretation:
    'A keyboard is a tool for shaping things, yet here it keeps turning into warm sand inside the glass office; the desk stays in place while the tool slips, which may be where the anxiety and the curiosity meet.',
  dailyLifeReflection: 'Today you might notice one task at your work desk that feels like sand slipping through a keyboard, and simply name it.',
  conclusion: 'What might the warm sand be making room for on that desk?',
});
const hallway = base('en', 'A black dog followed me down a long hallway at school and I was afraid the whole time.', {
  summary: 'The dream holds a long walk down a school hallway with a black dog close behind.',
  symbols: ['black dog', 'hallway'],
  emotionalTheme: 'Fear runs through the whole walk as the black dog keeps following.',
  interpretation:
    'The black dog following you down the long hallway at school gives the fear a shape that stays close without attacking; the length of the hallway may be what makes the following feel so heavy.',
  dailyLifeReflection: 'Today you might notice one thing that feels like that black dog, following quietly, and look at it for a moment.',
  conclusion: 'What would happen if you turned around in that hallway and looked at the dog?',
});

export const enCorpus: CorpusCase[] = [
  good('en-g-beach', beach),
  good('en-g-lighthouse', lighthouse),
  good('en-g-horse-sparse-one-anchor', horse),
  good('en-g-partner-present', packing),
  good('en-g-work-present', office),
  good('en-g-stated-fear', hallway),
  good('en-g-fear-absent-theme', beach, { emotionalTheme: 'Calm curiosity, with fear absent.' }),
  good('en-g-spec-summary', beach, { summary: 'A calm night walk is interrupted by an unexpected threshold on an otherwise open beach.' }),
  good('en-g-summary-reuses-red-door', beach, { summary: 'The red door on the quiet beach frames the whole calm night walk.' }),
  good('en-g-spec-reflection', beach, { dailyLifeReflection: 'Today you might notice where something feels like that unopened door.' }),
  good('en-g-behind-door', beach, { conclusion: 'What was behind the door?' }),
  good('en-g-how-question', beach, { conclusion: 'How might the red door feel if you stood beside it a little longer?' }),
  good('en-g-memory-reflection', packing, { dailyLifeReflection: 'Your recent context mentioned making space for something new; one small space could be enough today.' }),
  good('en-g-observed-emotion', horse, { emotionalTheme: 'Calm stillness around the white horse, quiet and unhurried.' }, { emotions: ['calm'] }),
  good('en-g-school-supported', hallway, { dailyLifeReflection: 'Today you might notice whether anything at your school feels like that long hallway.' }),
  good('en-g-symbolic-door', beach, { interpretation: 'The red door in the sand works like a threshold on the open beach: the quiet walk meets a frame for something not yet chosen, and your calm keeps that choice gentle.' }),

  bad('en-b-thin-summary', beach, 'thin_section', { summary: 'A red door, sand.' }),
  bad('en-b-question-summary', lighthouse, 'extra_question', { summary: 'Why does the lamp at the top of the lighthouse stay dark tonight?' }),
  bad('en-b-question-theme', beach, 'extra_question', { emotionalTheme: 'Calm on the beach, but is it really calm under the red door?' }),
  bad('en-b-question-interp', horse, 'extra_question', { interpretation: `${horse.data.interpretation} Could the white horse be waiting for you?` }),
  bad('en-b-question-reflection', packing, 'extra_question', { dailyLifeReflection: 'Which of the boxes in your empty apartment would you close first today?' }),
  bad('en-b-symbol-dupe', beach, 'symbol_list', { symbols: ['red door', 'Red  Door', 'beach'] }),
  bad('en-b-symbol-many', lighthouse, 'symbol_list', { symbols: ['lighthouse', 'lamp', 'waves', 'rocks', 'staircase', 'spiral', 'top', 'climbing', 'tired'] }),
  bad('en-b-recap-copy', lighthouse, 'plot_recap', {
    summary: 'You were climbing a spiral staircase inside a lighthouse, and the lamp at the top was dark.',
    interpretation:
      'Effort and purpose pull apart here: the climbing goes on while the signal above has gone out, and the tiredness gathers between that effort and the dark lamp, as if the waves below keep the rhythm.',
  }),
  bad('en-b-recap-beach', beach, 'plot_recap', { summary: 'You were walking along a quiet beach at night and a red door stood in the sand.' }),
  bad('en-b-fear-affirmed', beach, 'emotion_contradiction', { emotionalTheme: 'A creeping fear settles over the red door on the beach.' }),
  bad('en-b-scared-summary', lighthouse, 'emotion_contradiction', { summary: 'The dream carries a scared climb toward a lamp that has gone dark.' }),
  bad('en-b-sadness-denied', packing, 'emotion_contradiction', { emotionalTheme: 'No sadness at all, only a practical packing mood in the empty apartment.' }),
  bad('en-b-fear-denied', hallway, 'emotion_contradiction', { emotionalTheme: 'Without fear, the long hallway walk with the dog feels easy.' }),
  bad('en-b-invented-snake', beach, 'invented_image', { interpretation: `${beach.data.interpretation} A snake coiled by the red door adds a warning.` }),
  bad('en-b-invented-rain', horse, 'invented_image', { dailyLifeReflection: 'Today you might stand still like the white horse in the rain and wait.' }),
  bad('en-b-ungrounded-theme', beach, 'ungrounded_section', { emotionalTheme: 'A general sense of change and possibility opening up.' }),
  bad('en-b-ungrounded-summary', packing, 'ungrounded_section', { summary: 'A story of transformation, endings and beginnings unfolding slowly.' }),
  bad('en-b-shallow-lighthouse', lighthouse, 'weak_interpretation', { interpretation: 'The lamp suggests guidance that has paused for a while, a signal waiting quietly for its moment to return.' }),
  bad('en-b-shallow-beach', beach, 'weak_interpretation', { interpretation: 'The red door is a threshold that invites a choice, a frame for something unknown that has not yet been named or opened.' }),
  bad('en-b-shallow-office', office, 'weak_interpretation', { interpretation: 'A keyboard is a tool for shaping things, and one that changes shape may point to a tool that no longer fits the hand holding it.' }),
  bad('en-b-wellness-only', beach, 'generic_reflection', { dailyLifeReflection: 'Today, trust yourself and listen to your intuition as you move forward.' }),
  bad('en-b-wellness-anchored', beach, 'generic_reflection', { dailyLifeReflection: 'Near that red door, trust yourself and follow your heart today.' }),
  bad('en-b-generic-rest', lighthouse, 'generic_reflection', { dailyLifeReflection: 'Take some time for yourself today and remember to breathe deeply.' }),
  bad('en-b-work-invented', beach, 'unsupported_personal_fact', { dailyLifeReflection: 'Today your job may need the same calm you felt beside the red door.' }),
  bad('en-b-relationship-invented', lighthouse, 'unsupported_personal_fact', { dailyLifeReflection: 'Today your relationship might feel like that climb toward the dark lamp.' }),
  bad('en-b-family-invented', horse, 'unsupported_personal_fact', { interpretation: `${horse.data.interpretation} It may echo your family waiting for you to move.` }),
  bad('en-b-money-invented', beach, 'unsupported_personal_fact', { interpretation: `${beach.data.interpretation} Perhaps your money worries sit behind that red door.` }),
  bad('en-b-childhood-invented', packing, 'unsupported_personal_fact', { interpretation: `${packing.data.interpretation} The empty apartment may recall your childhood home.` }),
  bad('en-b-health-invented', office, 'unsupported_personal_fact', { dailyLifeReflection: 'Today your health may feel like warm sand on that desk, so slow down.' }),
  bad('en-b-yes-no-are', beach, 'weak_conclusion', { conclusion: 'Would the red door open if you knocked gently on it?' }),
  bad('en-b-yes-no-do', lighthouse, 'weak_conclusion', { conclusion: 'Do you think the lamp at the top will light up again?' }),
  bad('en-b-ungrounded-question', horse, 'weak_conclusion', { conclusion: 'What do you really want from life right now?' }),
  bad('en-b-statement-question', packing, 'weak_conclusion', { conclusion: 'The boxes in the apartment will stay closed one day?' }),
  bad('en-b-two-questions', beach, 'conclusion_not_question', { conclusion: 'What is behind the red door? What would you do there?' }),
];
