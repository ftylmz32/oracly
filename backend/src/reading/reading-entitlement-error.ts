export class ReadingEntitlementError extends Error {
  constructor(readonly code: 'owned_by_other' | 'invalid' | 'unavailable') {
    super(code);
    this.name = 'ReadingEntitlementError';
  }
}
