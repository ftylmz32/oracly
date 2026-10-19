export type AccountOrderRequest = { uid: string; generation: number; signal: AbortSignal };

export class AccountOrderIsolation {
  private uid: string | null = null;
  private generation = 0;
  private controller: AbortController | null = null;

  switchAccount(uid: string | null): void {
    this.controller?.abort();
    this.controller = null;
    this.uid = uid;
    this.generation += 1;
  }

  begin(uid: string): AccountOrderRequest | null {
    if (uid !== this.uid) return null;
    this.controller?.abort();
    this.controller = new AbortController();
    return { uid, generation: this.generation, signal: this.controller.signal };
  }

  accepts(request: Pick<AccountOrderRequest, 'uid' | 'generation'>): boolean {
    return request.uid === this.uid && request.generation === this.generation;
  }

  dispose(): void { this.switchAccount(null); }
}
