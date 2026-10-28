// Loads the App Store Connect API private key (Apple .p8: PKCS#8, EC P-256)
// from however the CI variable carries it:
//   - PEM with real newlines (LF or CRLF)
//   - PEM with literal "\n" / "\r\n" escapes
//   - PEM flattened to one line (newlines lost, spaces instead)
//   - base64 of a whole PEM file
//   - base64 of the PKCS#8 DER body (no PEM armour)
// optionally wrapped in quotes. Anything else is refused.
// Like Codemagic's own cli-tools (EnvironmentArgumentValue), the variable
// may instead hold "@env:<NAME>" or "@file:<path>"; one level is resolved.
// Errors carry only a fixed reason code: never the key, its parts or length,
// nor the referenced variable name or path.
import { createPrivateKey } from 'node:crypto';
import { readFileSync, statSync } from 'node:fs';
import { homedir } from 'node:os';

export class AscKeyError extends Error {
  constructor(reason) {
    super(`App Store Connect private key refused: ${reason}`);
    this.reason = reason;
  }
}

const BEGIN = '-----BEGIN PRIVATE KEY-----';
const END = '-----END PRIVATE KEY-----';
const BASE64 = /^[A-Za-z0-9+/]+={0,2}$/;

function strictBase64(text) {
  const compact = text.replace(/\s+/g, '');
  if (!compact || compact.length % 4 !== 0 || !BASE64.test(compact)) return null;
  return compact;
}

function pemFromBody(body) {
  const lines = body.match(/.{1,64}/g) ?? [];
  return `${BEGIN}\n${lines.join('\n')}\n${END}\n`;
}

// Rebuilds a clean PEM from text that contains the PKCS#8 armour.
function pemFromArmoured(text) {
  const start = text.indexOf(BEGIN);
  const end = text.indexOf(END);
  if (start < 0 || end < 0 || end < start) return null;
  if (text.indexOf(BEGIN, start + 1) >= 0) return null;
  const body = strictBase64(text.slice(start + BEGIN.length, end));
  return body ? pemFromBody(body) : null;
}

function normalize(raw) {
  if (typeof raw !== 'string') throw new AscKeyError('missing');
  let text = raw.trim();
  if (text.length >= 2 && /^(['"]).*\1$/s.test(text)) text = text.slice(1, -1).trim();
  text = text.replace(/\\r/g, '').replace(/\\n/g, '\n').replace(/\r/g, '');
  if (!text) throw new AscKeyError('missing');

  if (text.includes('-----BEGIN')) {
    if (!text.includes(BEGIN)) throw new AscKeyError('not_pkcs8');
    const pem = pemFromArmoured(text);
    if (!pem) throw new AscKeyError('malformed_pem');
    return pem;
  }

  const compact = strictBase64(text);
  if (!compact) throw new AscKeyError('unrecognized_format');
  const decoded = Buffer.from(compact, 'base64');
  const asText = decoded.toString('utf8');
  if (asText.includes('-----BEGIN')) {
    if (!asText.includes(BEGIN)) throw new AscKeyError('not_pkcs8');
    const pem = pemFromArmoured(asText.replace(/\r/g, ''));
    if (!pem) throw new AscKeyError('malformed_pem');
    return pem;
  }
  // DER body: PKCS#8 is an ASN.1 SEQUENCE (0x30).
  if (decoded[0] !== 0x30) throw new AscKeyError('unrecognized_format');
  return pemFromBody(compact);
}

// os.path.expandvars + expanduser, as cli-tools does for "@file:".
function expandPath(path, env) {
  const vars = path.replace(/\$(\w+)|\$\{(\w+)\}/g, (all, a, b) => env[a ?? b] ?? all);
  return vars === '~' || vars.startsWith('~/') ? homedir() + vars.slice(1) : vars;
}

function resolveReference(raw, env) {
  if (typeof raw !== 'string') return raw;
  if (raw.startsWith('@env:')) {
    const value = env[raw.slice(5)];
    if (value === undefined) throw new AscKeyError('reference_env_missing');
    return value;
  }
  if (raw.startsWith('@file:')) {
    const path = expandPath(raw.slice(6), env);
    try {
      if (!statSync(path).isFile()) throw new AscKeyError('reference_file_missing');
      return readFileSync(path, 'utf8');
    } catch (error) {
      if (error instanceof AscKeyError) throw error;
      throw new AscKeyError('reference_file_missing');
    }
  }
  return raw;
}

/** Returns a Node KeyObject for a valid Apple .p8 key, else throws AscKeyError. */
export function loadAscPrivateKey(raw, env = process.env) {
  const pem = normalize(resolveReference(raw, env));
  let key;
  try {
    key = createPrivateKey({ key: pem, format: 'pem' });
  } catch {
    throw new AscKeyError('undecodable');
  }
  if (key.asymmetricKeyType !== 'ec') throw new AscKeyError('not_ec');
  if (key.asymmetricKeyDetails?.namedCurve !== 'prime256v1') throw new AscKeyError('not_p256');
  return key;
}
