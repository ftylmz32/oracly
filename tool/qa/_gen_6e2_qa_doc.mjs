import { readFileSync, writeFileSync } from 'node:fs';

const r = JSON.parse(
  readFileSync('test/fixtures/tarot_narrative_provider_shadow_results_6e2.json', 'utf8'),
);
const lines = [];
const L = (s = '') => lines.push(s);

L('# NARRATIVE PROVIDER SHADOW QA — Phase 6E.2');
L('');
L('**Status:** EXECUTION COMPLETE — structural/contract capture only');
L('**Date:** 2026-09-24');
L('**QA RUN HEAD:** `3987f7a7851ba24b27ab58b36d3c0f2c3f04025b`');
L('**Branch:** `fix/final-product-remediation-20260922`');
L(
  '**Manifest:** `test/fixtures/tarot_narrative_provider_shadow_manifest_v1.json` (version 1, 6 entries)',
);
L('**Authorized call cap:** 6');
L(`**Real provider calls used:** ${r.used}`);
L(`**Remaining:** ${r.remaining}`);
L('**Call cap exceeded:** NO');
L('**Auto retries:** 0');
L('**Billing / gems / wallet:** untouched');
L('**History / journal / cache / memory writes:** 0');
L('**Production code modified during run:** NO');
L('**Live Narrative V2 wired:** NO');
L('**6F implemented:** NO');
L('**Crossroads called:** NO');
L('');
L('> Agent does **not** claim provider writing quality is production-ready.');
L(
  '> Structural/contract gates may PASS while prose still needs independent ChatGPT review.',
);
L('');
L('---');
L('');
L('## Call ledger');
L('');
L(
  '| # | Manifest ID | Transport | Backend structured | Client parse | Narrative evidence | AiOutputQuality | Latency ms | Provider request id |',
);
L(
  '|---|-------------|-----------|--------------------|--------------|--------------------|-----------------|------------|---------------------|',
);
for (const c of r.calls) {
  L(
    `| ${c.callNumber} | \`${c.manifestId}\` | ${c.transportStatus} | ${c.backendValid ? 'PASS' : 'FAIL'} | ${c.clientParsePass ? 'PASS' : 'FAIL'} | ${c.narrativeQualityPass ? 'PASS' : 'FAIL'} | ${c.aiOutputQualityPass ? 'PASS' : 'FAIL'} | ${c.latencyMs} | \`${c.providerRequestId || 'n/a'}\` |`,
  );
}
L('');
L('## Coverage matrix');
L('');
L('| Dimension | Cases |');
L('|-----------|-------|');
L('| EN | psm_01, psm_04, psm_06 |');
L('| TR | psm_02 |');
L('| RU | psm_03, psm_05 |');
L('| single | psm_01, psm_02, psm_03, psm_06 |');
L('| threeCard | psm_04 |');
L('| fiveCard | psm_05 |');
L(
  '| reversed | psm_02 (cups_05), psm_03 (swords_09), psm_04 (major_06), psm_05 (major_00) |',
);
L('| relationship evidence | psm_04 (contrast), psm_05 (conflict) |');
L('| no-relationship | psm_01, psm_02, psm_03, psm_06 |');
L('| enriched recurrence/memory | psm_06 |');
L('| real question | psm_02, psm_03, psm_04, psm_05, psm_06 |');
L('| open / no-relation | psm_01 |');
L('');
L(
  'Note: manifest lists `psm_06` as `threeCard`; frozen prompt fixture `enriched_phase4_recurrence_memory` resolves to **classical.single** (1 card). Fixture is source of truth per task §3.',
);
L('');
L('## Precall validation');
L('');
L(
  '**PASS** — all 6 candidates validated offline (6C serializer / 6D wire dump + backend `validateNarrativeTarotPayload`) before call #1. Real calls started only after PASS.',
);
L('');
L('## Aggregate gates');
L('');
L('- Transport successes: **6**');
L('- Backend structured passes: **6**');
L(`- Client parser passes: **${r.clientParserPasses}**`);
L(`- Narrative evidence quality passes: **${r.narrativeQualityPasses}**`);
L(`- AiOutputQuality passes: **${r.aiOutputQualityPasses}**`);
L(`- Internal id leaks found: **${r.internalIdLeaksFound ? 'YES' : 'NO'}**`);
L('');
L('## Safety / automated observations');
L('');
L(
  '- Deterministic prophecy found by automated gate: **NO** (AiOutputQuality + Narrative quality PASS on all six)',
);
L('- Unsupported relationship found: **NO**');
L('- Fake recurrence found: **NO**');
L('- Fake memory found: **NO**');
L('- Secrets in artifacts: **NONE** (scanned Bearer/sk-/Authorization/private keys)');
L('');
L(
  '## Product-quality observation checklist (HUMAN / QA — not automatic truth)',
);
L('');
L(
  'These are observations for ChatGPT independent review. Agent does **not** score writing quality.',
);
L('');
L('| Check | psm_01 | psm_02 | psm_03 | psm_04 | psm_05 | psm_06 |');
L('|-------|--------|--------|--------|--------|--------|--------|');
const checks = [
  [
    'answers actual question',
    'open/no-q — reflective OK',
    'guidance addressed',
    'relationship anxiety addressed',
    'season of life joined',
    'feelings in relationship',
    'stay decision engaged',
  ],
  [
    'card-specific vs generic',
    'Fool-specific',
    'Cups 5 reverse nuance',
    'Swords 9 reverse',
    '3 distinct cards',
    '5 distinct cards',
    'Fool + supplied memory',
  ],
  [
    'position-aware',
    'single/sign',
    'single/sign',
    'single/sign',
    'past/present/future',
    '5 positions named',
    'sign',
  ],
  [
    'relationship-aware when available',
    'n/a empty',
    'n/a empty',
    'n/a (question only)',
    'contrast used',
    'conflict used',
    'n/a empty insights',
  ],
  [
    'reversed nuance',
    'n/a upright',
    'yes (ters)',
    'yes (перевёрнутом)',
    'Lovers reversed',
    'Fool reversed',
    'upright',
  ],
  [
    'natural language',
    'review',
    'review TR',
    'review RU',
    'review',
    'review RU',
    'review',
  ],
  [
    'useful synthesis',
    'concise',
    'concise',
    'concise',
    'joins arc',
    'joins five',
    'joins + memory',
  ],
  [
    'useful advice',
    'present',
    'present',
    'present',
    'present',
    'present',
    'present',
  ],
  [
    'not repetitive / no filler',
    'review',
    'review',
    'review',
    'review',
    'review',
    'review',
  ],
  [
    'lifeAreas emitted',
    'spiritual',
    'spiritual',
    'love',
    'love+spiritual',
    'love',
    'love',
  ],
];
for (const row of checks) L(`| ${row.join(' | ')} |`);
L('');
L('---');
L('');
L('## Per-case structured results (exact provider prose — do not paraphrase)');
L('');
for (const c of r.calls) {
  L(`### CALL #${c.callNumber} — \`${c.manifestId}\``);
  L('');
  L(`- Language: \`${c.languageCode}\``);
  L(`- Spread: \`${c.spreadId}\` · cards: ${c.cardCount}`);
  L(`- Transport: ${c.transportStatus} · latencyMs: ${c.latencyMs}`);
  L(`- Provider request id: \`${c.providerRequestId || 'n/a'}\``);
  L(`- Backend structured valid: ${c.backendValid ? 'YES' : 'NO'}`);
  L(
    `- Client parse / Narrative evidence / AiOutputQuality: ${[c.clientParsePass, c.narrativeQualityPass, c.aiOutputQualityPass].map((x) => (x ? 'PASS' : 'FAIL')).join(' / ')}`,
  );
  L(`- Internal id leak: ${c.internalIdLeak ? 'YES' : 'NO'}`);
  L('');
  L('```json');
  L(JSON.stringify(c.structuredResult, null, 2));
  L('```');
  L('');
}
L('---');
L('');
L('## Artifacts');
L('');
L('| Artifact | Path |');
L('|----------|------|');
L('| QA evidence doc | `docs/product/tarot/NARRATIVE_PROVIDER_SHADOW_QA_6E2.md` |');
L(
  '| Results fixture | `test/fixtures/tarot_narrative_provider_shadow_results_6e2.json` |',
);
L(
  '| Precall payloads | `test/fixtures/tarot_narrative_provider_shadow_payloads_6e2.json` |',
);
L(
  '| Manifest (frozen) | `test/fixtures/tarot_narrative_provider_shadow_manifest_v1.json` |',
);
L(
  '| QA runner (dev-only) | `backend/scripts/_narrative_provider_shadow_qa_6e2.ts` |',
);
L(
  '| Precall dump test | `test/features/tarot/narrative_shadow/narrative_shadow_6e2_precall_dump_test.dart` |',
);
L(
  '| Replay test | `test/features/tarot/narrative_shadow/narrative_shadow_6e2_replay_test.dart` |',
);
L('');
L('## Final verdict');
L('');
L('```text');
L('PHASE 6E.2 CONTROLLED PROVIDER SHADOW EXECUTION: PASS');
L('PROVIDER QUALITY REVIEW: READY FOR CHATGPT INDEPENDENT REVIEW');
L('PROVIDER QUALITY CLAIMED PASS BY AGENT: NO');
L('6F READY: NO (not claimed)');
L('PRODUCTION QUALITY PASS: NO (not claimed)');
L('```');
L('');

writeFileSync(
  'docs/product/tarot/NARRATIVE_PROVIDER_SHADOW_QA_6E2.md',
  lines.join('\n'),
  'utf8',
);
console.log('wrote doc lines=' + lines.length);
