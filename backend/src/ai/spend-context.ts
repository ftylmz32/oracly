import { AsyncLocalStorage } from 'node:async_hooks';

/** Stable reservation scope for one user operation. Not a prompt. */
export const spendReservationScope = new AsyncLocalStorage<string>();
