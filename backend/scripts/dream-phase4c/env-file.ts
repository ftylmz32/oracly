/**
 * Reads one `NAME=value` entry from a dotenv file (UTF-8 BOM tolerant).
 * Only the requested name is returned; nothing is logged or stored.
 */
import { readFileSync } from 'node:fs';

export function readEnvFileValue(path: string, name: string): string | undefined {
  const text = readFileSync(path, 'utf8').replace(/^\uFEFF/, '');
  for (const line of text.split(/\r?\n/)) {
    const eq = line.indexOf('=');
    if (eq < 0 || line.slice(0, eq).trim() !== name) continue;
    const value = line.slice(eq + 1).trim().replace(/^(['"])(.*)\1$/, '$2');
    return value || undefined;
  }
  return undefined;
}
