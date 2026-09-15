/** Exact-hash portrait index. Stores hashes only, never image bytes or prompts. */
import { createHash } from 'node:crypto';

export type UniquenessDecision = 'new' | 'same-owner' | 'collision';

type Entry = {
  contentHash: string;
  ownerHash: string;
  coreSignature: string;
  createdAt: number;
};

const MAX_ENTRIES = 400;

export function contentHashOf(bytes: Buffer): string {
  return createHash('sha256').update(bytes).digest('hex');
}

export function ownerHashOf(accountKey: string): string {
  return createHash('sha256')
    .update(`oracly-soulmate-owner|${accountKey}`)
    .digest('hex')
    .slice(0, 24);
}

export class SoulmateUniquenessIndex {
  private readonly entries: Entry[] = [];

  decide(owner: string, contentHash: string): UniquenessDecision {
    const found = this.entries.find((entry) => entry.contentHash === contentHash);
    if (!found) return 'new';
    return found.ownerHash === owner ? 'same-owner' : 'collision';
  }

  coreOwnedByOther(owner: string, signature: string): boolean {
    return this.entries.some(
      (entry) => entry.coreSignature === signature && entry.ownerHash !== owner,
    );
  }

  remember(input: {
    owner: string;
    contentHash: string;
    coreSignature: string;
    createdAt?: number;
  }): void {
    if (this.decide(input.owner, input.contentHash) !== 'new') return;
    this.entries.push({
      contentHash: input.contentHash,
      ownerHash: input.owner,
      coreSignature: input.coreSignature,
      createdAt: input.createdAt ?? Date.now(),
    });
    if (this.entries.length > MAX_ENTRIES) this.entries.shift();
  }

  size(): number {
    return this.entries.length;
  }
}

let shared = new SoulmateUniquenessIndex();

export function soulmateUniquenessIndex(): SoulmateUniquenessIndex {
  return shared;
}

export function resetSoulmateUniquenessIndex(): void {
  shared = new SoulmateUniquenessIndex();
}
