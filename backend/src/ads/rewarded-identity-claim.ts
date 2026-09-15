import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';

type Claim = { v: 1; owner: string; exp: number; nonce: string };

export class RewardedIdentityClaims {
  constructor(private readonly secret: string, private readonly ttlMs = 10 * 60_000) {}

  get configured(): boolean { return this.secret.length >= 32; }

  issue(owner: string, nowMs: number): { customData: string; expiresAtMs: number } {
    if (!this.configured || !owner) throw new Error('reward_claim_unconfigured');
    const claim: Claim = { v: 1, owner, exp: nowMs + this.ttlMs, nonce: randomBytes(12).toString('hex') };
    const payload = Buffer.from(JSON.stringify(claim)).toString('base64url');
    return { customData: `${payload}.${this.sign(payload)}`, expiresAtMs: claim.exp };
  }

  verify(token: string, nowMs: number): Claim | null {
    if (!this.configured || token.length > 1200) return null;
    const [payload, signature, extra] = token.split('.');
    if (!payload || !signature || extra) return null;
    const expected = this.sign(payload);
    const a = Buffer.from(signature); const b = Buffer.from(expected);
    if (a.length !== b.length || !timingSafeEqual(a, b)) return null;
    try {
      const value = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as Partial<Claim>;
      if (value.v !== 1 || typeof value.owner !== 'string' || !value.owner ||
          typeof value.exp !== 'number' || value.exp < nowMs || value.exp > nowMs + this.ttlMs + 5000 ||
          typeof value.nonce !== 'string' || value.nonce.length < 16) return null;
      return value as Claim;
    } catch { return null; }
  }

  private sign(payload: string): string {
    return createHmac('sha256', this.secret).update(payload).digest('base64url');
  }
}
