// node --test tool/asc/
// Uses only keys generated here; no real credential is involved.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createPublicKey, generateKeyPairSync, sign, verify } from 'node:crypto';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { after, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { AscKeyError, loadAscPrivateKey } from './asc_key.mjs';

const ec = generateKeyPairSync('ec', { namedCurve: 'P-256' });
const PEM = ec.privateKey.export({ type: 'pkcs8', format: 'pem' });
const BODY = PEM.replace(/-----[A-Z ]+-----/g, '').replace(/\s+/g, '');
const DER_B64 = ec.privateKey.export({ type: 'pkcs8', format: 'der' }).toString('base64');
const wrap = (s, n) => s.match(new RegExp(`.{1,${n}}`, 'g')).join('\n');

function signsWithGeneratedKey(key) {
  const data = Buffer.from('header.payload');
  const sig = sign('sha256', data, { key, dsaEncoding: 'ieee-p1363' });
  assert.equal(sig.length, 64, 'ES256 raw signature');
  assert.ok(verify('sha256', data, { key: createPublicKey(ec.privateKey), dsaEncoding: 'ieee-p1363' }, sig));
}

const accepted = {
  'PEM, LF': PEM,
  'PEM, CRLF': PEM.replace(/\n/g, '\r\n'),
  'PEM, literal \\n escapes': PEM.replace(/\n/g, '\\n'),
  'PEM, literal \\r\\n escapes': PEM.replace(/\n/g, '\\r\\n'),
  'PEM flattened with spaces': PEM.replace(/\n/g, ' '),
  'PEM flattened, no separators': PEM.replace(/\n/g, ''),
  'PEM in double quotes': `"${PEM}"`,
  'PEM in single quotes with padding': `  '${PEM}'  \n`,
  'base64 of the PEM file': Buffer.from(PEM).toString('base64'),
  'base64 of the PEM file, wrapped at 76': wrap(Buffer.from(PEM).toString('base64'), 76),
  'base64 of a CRLF PEM file': Buffer.from(PEM.replace(/\n/g, '\r\n')).toString('base64'),
  'bare PKCS#8 DER base64': DER_B64,
  'bare PKCS#8 DER base64, wrapped at 64': wrap(DER_B64, 64),
};

for (const [label, input] of Object.entries(accepted)) {
  test(`accepts ${label}`, () => {
    const key = loadAscPrivateKey(input);
    assert.equal(key.asymmetricKeyType, 'ec');
    signsWithGeneratedKey(key);
  });
}

const rsa = generateKeyPairSync('rsa', { modulusLength: 2048 }).privateKey.export({ type: 'pkcs8', format: 'pem' });
const p384 = generateKeyPairSync('ec', { namedCurve: 'P-384' }).privateKey.export({ type: 'pkcs8', format: 'pem' });
const ed = generateKeyPairSync('ed25519').privateKey.export({ type: 'pkcs8', format: 'pem' });
const sec1 = ec.privateKey.export({ type: 'sec1', format: 'pem' });
const pub = createPublicKey(ec.privateKey).export({ type: 'spki', format: 'pem' });
const lines = PEM.trim().split('\n');
// One body character replaced by a non-base64 one; the armour stays intact.
const corruptBody = (at) =>
  [lines[0], lines[1].slice(0, at) + '*' + lines[1].slice(at + 1), ...lines.slice(2)].join('\n');

const refused = {
  'undefined': [undefined, 'missing'],
  'empty': ['', 'missing'],
  'whitespace / empty quotes': ['  ""  ', 'missing'],
  'plain text': ['not a key at all', 'unrecognized_format'],
  'base64 of random bytes': [Buffer.from('random-bytes-not-asn1').toString('base64'), 'unrecognized_format'],
  'body with a bad character': [corruptBody(10), 'malformed_pem'],
  'missing END line': [lines.slice(0, -1).join('\n'), 'malformed_pem'],
  'truncated body': [[lines[0], ...lines.slice(1, 2), lines.at(-1)].join('\n'), 'undecodable'],
  'two keys concatenated': [PEM + PEM, 'malformed_pem'],
  'RSA PKCS#8': [rsa, 'not_ec'],
  'Ed25519 PKCS#8': [ed, 'not_ec'],
  'EC P-384 PKCS#8': [p384, 'not_p256'],
  'SEC1 "EC PRIVATE KEY"': [sec1, 'not_pkcs8'],
  'public key PEM': [pub, 'not_pkcs8'],
  'base64 of an RSA PEM': [Buffer.from(rsa).toString('base64'), 'not_ec'],
};

for (const [label, [input, reason]] of Object.entries(refused)) {
  test(`refuses ${label} as ${reason}, without key material in the error`, () => {
    assert.throws(() => loadAscPrivateKey(input), (error) => {
      assert.ok(error instanceof AscKeyError);
      assert.equal(error.reason, reason);
      assert.equal(error.message, `App Store Connect private key refused: ${reason}`);
      return true;
    });
  });
}

test('inventory script stops on a bad key before any Apple request and logs no key material', () => {
  const script = fileURLToPath(new URL('./asc_inventory.mjs', import.meta.url));
  const bad = corruptBody(20);
  const run = spawnSync(process.execPath, [script], {
    env: {
      ...process.env,
      APP_STORE_CONNECT_PRIVATE_KEY: bad,
      APP_STORE_CONNECT_KEY_IDENTIFIER: 'TESTKEYID',
      APP_STORE_CONNECT_ISSUER_ID: '00000000-0000-0000-0000-000000000000',
      CM_BUILD_DIR: fileURLToPath(new URL('.', import.meta.url)),
    },
    encoding: 'utf8',
  });
  const out = run.stdout + run.stderr;
  assert.equal(run.status, 4);
  assert.match(out, /STOP: private key not usable \(malformed_pem\)\. No Apple request was made\./);
  assert.doesNotMatch(out, /GET /);
  for (let i = 0; i + 12 <= BODY.length; i += 12) {
    assert.ok(!out.includes(BODY.slice(i, i + 12)), 'no fragment of the key body');
  }
  assert.doesNotMatch(out, /BEGIN|PRIVATE KEY|Bearer|eyJ/);
});

// "@env:" / "@file:" references, as Codemagic cli-tools resolves them for
// APP_STORE_CONNECT_PRIVATE_KEY (src/codemagic/cli/argument/typed_cli_argument.py).
const dir = mkdtempSync(join(tmpdir(), 'asc-key-test-'));
after(() => rmSync(dir, { recursive: true, force: true }));
const keyFile = join(dir, 'AuthKey_TEST.p8');
writeFileSync(keyFile, PEM);
const badFile = join(dir, 'bad.p8');
writeFileSync(badFile, corruptBody(5));

const refEnv = {
  ASC_KEY_PEM: PEM,
  ASC_KEY_ESCAPED: PEM.replace(/\n/g, '\n'),
  ASC_KEY_DIR: dir,
  ASC_KEY_NESTED: `@file:${keyFile}`,
};

const acceptedRefs = {
  '@env: holding a PEM': '@env:ASC_KEY_PEM',
  '@env: holding an escaped PEM': '@env:ASC_KEY_ESCAPED',
  '@file: absolute path': `@file:${keyFile}`,
  '@file: path with $VAR': '@file:$ASC_KEY_DIR/AuthKey_TEST.p8',
  '@file: path with ${VAR}': '@file:${ASC_KEY_DIR}/AuthKey_TEST.p8',
};

for (const [label, input] of Object.entries(acceptedRefs)) {
  test(`accepts ${label}`, () => {
    signsWithGeneratedKey(loadAscPrivateKey(input, refEnv));
  });
}

const refusedRefs = {
  '@env: naming an unset variable': ['@env:ASC_KEY_UNSET', 'reference_env_missing'],
  '@file: missing file': [`@file:${join(dir, 'nope.p8')}`, 'reference_file_missing'],
  '@file: a directory': [`@file:${dir}`, 'reference_file_missing'],
  '@file: with a corrupt key': [`@file:${badFile}`, 'malformed_pem'],
  'only one level of reference': ['@env:ASC_KEY_NESTED', 'unrecognized_format'],
  'unknown @ prefix': [`@path:${keyFile}`, 'unrecognized_format'],
};

for (const [label, [input, reason]] of Object.entries(refusedRefs)) {
  test(`refuses ${label} as ${reason}, naming neither variable nor path`, () => {
    assert.throws(() => loadAscPrivateKey(input, refEnv), (error) => {
      assert.ok(error instanceof AscKeyError);
      assert.equal(error.reason, reason);
      assert.ok(!error.message.includes('ASC_KEY') && !error.message.includes(dir));
      return true;
    });
  });
}

test('inventory script resolves the reference before any request and does not log it', () => {
  const script = fileURLToPath(new URL('./asc_inventory.mjs', import.meta.url));
  const run = spawnSync(process.execPath, [script], {
    env: {
      ...process.env,
      APP_STORE_CONNECT_PRIVATE_KEY: `@file:${join(dir, 'missing-secret-name.p8')}`,
      APP_STORE_CONNECT_KEY_IDENTIFIER: 'TESTKEYID',
      APP_STORE_CONNECT_ISSUER_ID: '00000000-0000-0000-0000-000000000000',
      CM_BUILD_DIR: dir,
    },
    encoding: 'utf8',
  });
  const out = run.stdout + run.stderr;
  assert.equal(run.status, 4);
  assert.match(out, /STOP: private key not usable \(reference_file_missing\)\. No Apple request was made\./);
  assert.doesNotMatch(out, /GET |missing-secret-name|asc-key-test-/);
});
