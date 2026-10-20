import { describe, expect, it } from 'vitest';
import { dreamMessages } from '../src/ai/dream-prompts.js';
import { buildDreamCompleteOptions, DREAM_OUTPUT_TOKEN_CEILING } from '../src/ai/dream-writer-model.js';
import { buildChatCompletionBody } from '../src/ai/openai-transport.js';
import { quoteChat } from '../src/ai/spend-quote.js';
import { phase4cConfig } from '../scripts/dream-phase4c/production-config.js';

const CAP = 5_000_000;

describe('dream spend ceiling', () => {
  it('reserves the sent completion budget, which fits the provisional day cap', () => {
    const messages = dreamMessages({ narrative: 'çekirge'.repeat(1600) }, 'tr');
    const open = quoteChat('gpt-6-astra', messages);
    const capped = quoteChat('gpt-6-astra', messages, DREAM_OUTPUT_TOKEN_CEILING);
    expect('ceilingMicros' in open && open.ceilingMicros > CAP).toBe(true);
    expect('ceilingMicros' in capped && capped.ceilingMicros < CAP).toBe(true);
    const body = buildChatCompletionBody(
      buildDreamCompleteOptions(phase4cConfig('test-key'), messages),
    );
    expect(body.max_completion_tokens).toBe(DREAM_OUTPUT_TOKEN_CEILING);
  });

  it('fails closed when the completion budget is above the published maximum', () => {
    expect(quoteChat('gpt-6-astra', [{ role: 'user', content: 'x' }], 128_001)).toEqual({
      unpriced: 'unpriced_output',
    });
  });
});
