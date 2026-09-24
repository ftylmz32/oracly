import { readFileSync, writeFileSync } from 'node:fs';

const r = JSON.parse(
  readFileSync(
    'test/fixtures/tarot_narrative_provider_shadow_results_6e42_v2.json',
    'utf8',
  ),
);
const L = [];
const p = (s = '') => L.push(s);

p('# NARRATIVE PROVIDER SHADOW QA — Phase 6E.4.2 (Manifest V2 / Result Contract V2)');
p('');
p(
  '**Status:** EXECUTION COMPLETE — structural/contract capture for independent writing-quality review',
);
p('**Date:** 2026-09-24');
p('**QA RUN HEAD:** `2799e9bf518b2e1db6e9ce338643bffef8c4e632`');
p('**Branch:** `fix/final-product-remediation-20260922`');
p(
  '**Manifest:** `test/fixtures/tarot_narrative_provider_shadow_manifest_v2.json` (version 2, 6 entries · unchanged)',
);
p('**Result contract:** **2** · schema `oracly_tarot_narrative_v2`');
p('**Request contract:** mode=`narrative_v2` · contractVersion=**1**');
p('**Authorized call cap:** 6');
p(`**Real provider calls used:** ${r.usedCalls}`);
p(`**Remaining:** ${r.remaining}`);
p('**Call cap exceeded:** NO');
p('**Auto retries:** 0');
p('**Schema compatibility precall:** PASS · uniqueItems absent');
p('**Six outbound bodies offline:** 6/6 PASS');
p('**Billing / gems / wallet:** untouched');
p('**History / journal / cache / memory writes:** 0');
p('**Production code modified during run:** NO');
p('**Live Narrative V2 wired:** NO');
p('**6F implemented:** NO');
p('**Crossroads called:** NO');
p('**Historical 6E.4 artifacts:** unchanged');
p('');
p('> Agent does **not** claim provider writing quality is production-ready.');
p(
  '> Structural/contract gates may PASS while prose still needs independent ChatGPT review.',
);
p('');
p('---');
p('');
p('## Call ledger');
p('');
p(
  '| # | Manifest ID | Transport | Backend | Client | Narrative | AiOutputQuality | Latency ms | Provider request id |',
);
p(
  '|---|-------------|-----------|---------|--------|-----------|-----------------|------------|---------------------|',
);
for (const c of r.calls) {
  p(
    `| ${c.callNumber} | \`${c.manifestId}\` | ${c.transportStatus} | ${
      c.backendValid ? 'PASS' : 'FAIL'
    } | ${c.clientParsePass ? 'PASS' : 'FAIL'} | ${
      c.narrativeQualityPass ? 'PASS' : 'FAIL'
    } | ${c.aiOutputQualityPass ? 'PASS' : 'FAIL'} | ${c.latencyMs} | \`${
      c.providerRequestId || 'n/a'
    }\` |`,
  );
}
p('');
p('## Aggregate gates');
p('');
p(`- Transport successes: **${r.transportSuccesses}**`);
p(`- Backend structured passes: **${r.backendStructuredPasses}**`);
p(`- Backend quality rejections: **${r.backendQualityRejections}**`);
p(`- Client parser passes: **${r.clientParserPasses}**`);
p(`- Narrative evidence quality passes: **${r.narrativeQualityPasses}**`);
p(`- AiOutputQuality passes: **${r.aiOutputQualityPasses}**`);
p(
  `- Internal id leaks found: **${r.internalIdLeaksFound ? 'YES' : 'NO'}**`,
);
p(
  `- Deterministic-future automated hits: **${
    r.calls.filter((c) => c.deterministicFutureFound).length
  }**`,
);
p('');
p('## Quality observations (agent notes — NOT a production pass claim)');
p('');
p(
  '| # | Repetition | Mind-reading | Objective relationship | Deterministic future | Memory indices |',
);
p(
  '|---|------------|--------------|------------------------|----------------------|----------------|',
);
for (const c of r.calls) {
  const idx = c.memoryProvenanceNotes?.indices ?? [];
  p(
    `| ${c.callNumber} | ${c.repetitionObservation || 'n/a'} | ${
      c.mindReadingClaimFound ? 'YES' : 'NO'
    } | ${c.objectiveRelationshipClaimFound ? 'YES' : 'NO'} | ${
      c.deterministicFutureFound ? 'YES' : 'NO'
    } | ${JSON.stringify(idx)} |`,
  );
}
p('');
p('### Human / QA notes for ChatGPT');
p('');
p(
  '- **Call #1 EN open:** lifeAreas empty (preferred). Concise. Closing slightly blessing-like — review.',
);
p(
  '- **Call #2 TR reversed:** Natural diacritics present (dönem, kayıplara, eğiliminiz). Loss theme recurs across sections — mild repetition risk.',
);
p(
  '- **Call #3 RU relationship:** Modal language (могут / может). Automated mind-reading flag NO. Soft relationship-state framing in summary — review epistemic strength.',
);
p(
  '- **Call #4 EN three/future:** No automated `future promises` / `will lead to` hit. Future framed as potential/could/opportunity — primary Q1 regression candidate for human review.',
);
p(
  '- **Call #5 RU five:** Conflict insight present; idiomatic review needed for calques.',
);
p(
  '- **Call #6 enriched:** `memoryIndices: [0,1]` multi-memory synthesis explicit. Recurring Fool + theme `ilişki` present.',
);
p('');
p('## Enriched memory QA context (Call #6)');
p('');
const c6 = r.calls.find((c) => c.callNumber === 6);
for (const m of c6.memorySummariesForQa || []) {
  p(
    `- Memory ${m.index} · sourceType=\`${m.sourceType ?? 'n/a'}\` · ${
      m.contentForModel
    }`,
  );
}
p('');
p('Provider memoryInsights:');
p('```json');
p(JSON.stringify(c6.structuredResult.memoryInsights, null, 2));
p('```');
p('');
p('---');
p('');
p('## Per-case structured results (exact provider prose)');
p('');
for (const c of r.calls) {
  p(`### CALL #${c.callNumber} — \`${c.manifestId}\``);
  p('');
  p(
    `- Language: \`${c.languageCode}\` · Spread: \`${c.spreadId}\` · cards: ${c.cardCount}`,
  );
  p(`- Display: ${c.displayName || 'n/a'}`);
  p(`- Transport: ${c.transportStatus} · latencyMs: ${c.latencyMs}`);
  p(`- Provider request id: \`${c.providerRequestId || 'n/a'}\``);
  p(
    `- Client / Narrative / AiOutputQuality: ${[
      c.clientParsePass,
      c.narrativeQualityPass,
      c.aiOutputQualityPass,
    ]
      .map((x) => (x ? 'PASS' : 'FAIL'))
      .join(' / ')}`,
  );
  p(`- Repetition observation: ${c.repetitionObservation}`);
  p(`- Mind-reading claim: ${c.mindReadingClaimFound ? 'YES' : 'NO'}`);
  p(
    `- Objective relationship claim: ${
      c.objectiveRelationshipClaimFound ? 'YES' : 'NO'
    }`,
  );
  p(
    `- Deterministic future (automated): ${
      c.deterministicFutureFound ? 'YES' : 'NO'
    }`,
  );
  p('');
  p('```json');
  p(JSON.stringify(c.structuredResult, null, 2));
  p('```');
  p('');
}
p('---');
p('');
p('## Agent quality claim');
p('');
p('**PROVIDER QUALITY CLAIMED PASS BY AGENT: NO**');
p('');
p(
  'Ready for ChatGPT independent writing-quality review of the captured Result Contract V2 prose.',
);

writeFileSync(
  'docs/product/tarot/NARRATIVE_PROVIDER_SHADOW_QA_6E42_V2.md',
  L.join('\n'),
  'utf8',
);
console.log('wrote', L.length, 'lines');
