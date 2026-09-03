/**
 * LIVE OUTPUT EVALUATION PLAN (authorized smoke only — not run in E1).
 *
 * After explicit user authorization for paid OpenAI calls:
 * 1. Multiple valid coffee cup interiors (clear residue) — TR / EN / RU.
 * 2. Multiple valid open-palm photos with major lines — TR / EN / RU.
 * 3. Invalid / non-target images (landscape, closed fist, dark blur) → invalid_image.
 * 4. Compare specificity across cups/hands (no identical boilerplate paragraphs).
 * 5. Soulmate gpt-image-2 portrait once with OPENAI_IMAGE_QUALITY=low for cost safety.
 * 6. Confirm org verification / model access if 400 unsupported model.
 *
 * Do not enable this suite without authorization.
 */
import { describe, it } from 'vitest';

describe.skip('E1 live provider smoke (requires authorization)', () => {
  it('placeholder — authorized later', () => {
    // Intentionally skipped in Phase E1.
  });
});
