import { createHash } from 'node:crypto';

export function readingDocId(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

export function purchaseIdentityId(platform: string, appId: string, transactionId: string): string {
  return readingDocId(`${platform}\0${appId}\0${transactionId}`);
}

export function purchaseTokenId(platform: string, purchaseToken: string): string {
  return readingDocId(`${platform}\0${purchaseToken}`);
}
