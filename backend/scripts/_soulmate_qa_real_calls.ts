/**
 * ONE-OFF QA script — real paid Soulmate portrait generations for visual
 * review. Max 4 calls, matching the exact production call shape
 * (ai/openai-transport.ts's generateImage): POST {base}/images/generations,
 * model="gpt-image-2", size="1024x1536", quality="high", n=1.
 *
 * Never logs the API key. Reads it from process.env.OPENAI_API_KEY only.
 */
import { writeFileSync } from 'node:fs';
import { buildSoulmateImagePrompt } from '../src/ai/soulmate-prompt.js';
import { visualProfileSignature } from '../src/ai/soulmate-visual-profile.js';

const OUT_DIR = process.argv[2];
if (!OUT_DIR) {
  console.error('usage: tsx _soulmate_qa_real_calls.ts <output-dir>');
  process.exit(1);
}

const apiKey = process.env.OPENAI_API_KEY;
if (!apiKey) {
  console.error('OPENAI_API_KEY not set in environment');
  process.exit(1);
}

const FIXTURES = [
  { label: 'A', accountKey: 'qa-soulmate-fixture-A-6', gender: 'masculine' as const, name: 'QA Fixture A' },
  { label: 'B', accountKey: 'qa-soulmate-fixture-B-5', gender: 'masculine' as const, name: 'QA Fixture B' },
  { label: 'C', accountKey: 'qa-soulmate-fixture-C-7', gender: 'feminine' as const, name: 'QA Fixture C' },
  { label: 'D', accountKey: 'qa-soulmate-fixture-D-12', gender: 'feminine' as const, name: 'QA Fixture D' },
];

async function main() {
  const results: Record<string, unknown> = {};
  for (const fixture of FIXTURES) {
    const built = buildSoulmateImagePrompt({
      name: fixture.name,
      birthDate: '1996-06-15',
      gender: fixture.gender,
      accountKey: fixture.accountKey,
    });
    const signature = visualProfileSignature(built.core);
    console.log(`=== QA ${fixture.label} === signature=${signature}`);
    console.log(JSON.stringify(built.core));

    const response = await fetch('https://api.openai.com/v1/images/generations', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-image-2',
        prompt: built.prompt,
        n: 1,
        size: '1024x1536',
        quality: 'high',
      }),
    });
    if (!response.ok) {
      const text = await response.text();
      console.error(`QA ${fixture.label} FAILED: HTTP ${response.status} ${text.slice(0, 500)}`);
      results[fixture.label] = { error: `http_${response.status}`, signature, core: built.core };
      continue;
    }
    const body = (await response.json()) as { data: { b64_json: string }[] };
    const b64 = body.data[0]?.b64_json;
    if (!b64) {
      console.error(`QA ${fixture.label} FAILED: no b64_json in response`);
      results[fixture.label] = { error: 'no_b64_json', signature, core: built.core };
      continue;
    }
    const outPath = `${OUT_DIR}/soulmate_qa_${fixture.label}.png`;
    writeFileSync(outPath, Buffer.from(b64, 'base64'));
    console.log(`QA ${fixture.label} saved -> ${outPath}`);
    results[fixture.label] = { signature, core: built.core, path: outPath };
  }
  writeFileSync(`${OUT_DIR}/soulmate_qa_manifest.json`, JSON.stringify(results, null, 2));
  console.log('Done.');
}

main().catch((err) => {
  console.error('QA script failed:', err instanceof Error ? err.message : err);
  process.exit(1);
});
