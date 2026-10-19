import { describe, expect, it } from 'vitest';
import { AccountOrderIsolation } from './account-order-isolation';

describe('account order isolation', () => {
  it('rejects a late A response after logout and B login', () => {
    const isolation = new AccountOrderIsolation();
    isolation.switchAccount('uid-a'); const requestA = isolation.begin('uid-a')!;
    isolation.switchAccount(null);
    expect(requestA.signal.aborted).toBe(true); expect(isolation.accepts(requestA)).toBe(false);
    isolation.switchAccount('uid-b'); const requestB = isolation.begin('uid-b')!;
    expect(isolation.accepts(requestA)).toBe(false); expect(isolation.accepts(requestB)).toBe(true);
  });
  it('uses a new generation when A signs in again', () => {
    const isolation = new AccountOrderIsolation();
    isolation.switchAccount('uid-a'); const firstA = isolation.begin('uid-a')!;
    isolation.switchAccount('uid-b'); isolation.switchAccount('uid-a'); const secondA = isolation.begin('uid-a')!;
    expect(firstA.signal.aborted).toBe(true); expect(isolation.accepts(firstA)).toBe(false); expect(isolation.accepts(secondA)).toBe(true);
  });
  it('cannot begin a request for another UID', () => {
    const isolation = new AccountOrderIsolation(); isolation.switchAccount('uid-b');
    expect(isolation.begin('uid-a')).toBeNull();
  });
});
