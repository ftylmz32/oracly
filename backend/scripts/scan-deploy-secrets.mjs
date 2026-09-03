#!/usr/bin/env node
/** Scan deploy/container assets for accidental secret patterns. Exit 1 on hit. */
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { exit } from 'node:process';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const roots = [
  join(root, 'Dockerfile'),
  join(root, '.dockerignore'),
  join(root, 'scripts'),
];

const patterns = [
  /sk-[A-Za-z0-9]{20,}/,
  /BEGIN (RSA )?PRIVATE KEY/,
  /AIza[0-9A-Za-z_-]{30,}/,
  /"private_key"\s*:\s*"-----/,
];

const hits = [];

function walk(p) {
  let st;
  try {
    st = statSync(p);
  } catch {
    return;
  }
  if (st.isDirectory()) {
    for (const name of readdirSync(p)) {
      if (name === 'node_modules' || name === 'dist') continue;
      walk(join(p, name));
    }
    return;
  }
  const base = p.replace(/\\/g, '/');
  if (
    !/\.(sh|mjs|js|ts|json|yml|yaml|md)$/i.test(base) &&
    !base.endsWith('Dockerfile') &&
    !base.endsWith('.dockerignore')
  ) {
    return;
  }
  const text = readFileSync(p, 'utf8');
  for (const re of patterns) {
    if (re.test(text)) hits.push(relative(root, p));
  }
}

for (const r of roots) walk(r);

if (hits.length) {
  console.error(JSON.stringify({ ok: false, secretPatternHits: hits }));
  exit(1);
}
console.log(JSON.stringify({ ok: true, scanned: 'deploy-assets', hits: 0 }));