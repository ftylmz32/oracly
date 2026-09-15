import { createHash } from 'node:crypto';
import { GoogleAuth } from 'google-auth-library';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import type { ReadingCompletionNotifier } from './reading-processor.js';

const TOKENS = 'readingNotificationTokens';
const TOKEN_OWNERS = 'readingNotificationTokenOwners';

export class ReadingNotificationTokens {
  constructor(private readonly firestore: FirestoreLike) {}

  async register(ownerUserId: string, token: string): Promise<void> {
    const ref = this.firestore.collection(TOKENS).doc(id(ownerUserId));
    const ownerRef = this.firestore.collection(TOKEN_OWNERS).doc(id(token));
    await this.firestore.runTransaction(async (tx) => {
      const [current, tokenOwner] = await Promise.all([tx.get(ref), tx.get(ownerRef)]);
      const previousToken = current.data()?.token;
      if (typeof previousToken === 'string' && previousToken !== token) {
        tx.delete(this.firestore.collection(TOKEN_OWNERS).doc(id(previousToken)));
      }
      const previousOwner = tokenOwner.data()?.ownerUserId;
      if (typeof previousOwner === 'string' && previousOwner !== ownerUserId) {
        tx.delete(this.firestore.collection(TOKENS).doc(id(previousOwner)));
      }
      tx.set(ref, {
        schemaVersion: 1,
        ownerUserId,
        token,
        updatedAtMs: Date.now(),
      });
      tx.set(ownerRef, { ownerUserId, updatedAtMs: Date.now() });
    });
  }

  async unregister(ownerUserId: string, expectedToken?: string): Promise<boolean> {
    const ref = this.firestore.collection(TOKENS).doc(id(ownerUserId));
    return this.firestore.runTransaction(async (tx) => {
      const current = await tx.get(ref);
      const token = current.data()?.token;
      if (current.data()?.ownerUserId !== ownerUserId || typeof token !== 'string') return false;
      if (expectedToken && token !== expectedToken) return false;
      tx.delete(ref);
      tx.delete(this.firestore.collection(TOKEN_OWNERS).doc(id(token)));
      return true;
    });
  }

  async get(ownerUserId: string): Promise<string | null> {
    const data = (await this.firestore.collection(TOKENS).doc(id(ownerUserId)).get()).data();
    return data?.ownerUserId === ownerUserId && typeof data.token === 'string'
      ? data.token
      : null;
  }
}

export class FirebaseReadingCompletionNotifier implements ReadingCompletionNotifier {
  private readonly auth: Pick<GoogleAuth, 'request'>;

  constructor(
    private readonly config: AppConfig,
    private readonly tokens: ReadingNotificationTokens,
    auth?: Pick<GoogleAuth, 'request'>,
  ) {
    this.auth = auth ?? new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });
  }

  async notifyCompleted(input: {
    operationId: string;
    ownerUserId: string;
    readingType: 'coffee' | 'palm' | 'soulmate';
  }): Promise<void> {
    const project = this.config.firebaseProjectId;
    if (!project) return;
    const token = await this.tokens.get(input.ownerUserId);
    if (!token) return;
    const title = input.readingType === 'coffee'
      ? 'Kahve falın hazır ☕✨'
      : input.readingType === 'palm'
        ? 'El falın hazır ✋✨'
        : 'Ruh eşi portren hazır 🎨✨';
    try {
      await this.auth.request({
      url: `https://fcm.googleapis.com/v1/projects/${project}/messages:send`,
      method: 'POST',
      data: {
        message: {
          token,
          notification: {
            title,
            body: 'Yorumunu görmek için dokun.',
          },
          data: {
            type: 'reading_completed',
            readingType: input.readingType,
            operationId: input.operationId,
          },
          android: { notification: { clickAction: 'FLUTTER_NOTIFICATION_CLICK' } },
        },
      },
      });
    } catch (error) {
      if (isInvalidTokenError(error)) await this.tokens.unregister(input.ownerUserId, token);
      throw error;
    }
  }
}

function isInvalidTokenError(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;
  const candidate = error as { code?: unknown; message?: unknown; response?: { status?: unknown; data?: unknown } };
  const text = `${String(candidate.code ?? '')} ${String(candidate.message ?? '')} ${JSON.stringify(candidate.response?.data ?? '')}`.toUpperCase();
  return candidate.response?.status === 404 || candidate.response?.status === 410 ||
    text.includes('UNREGISTERED') || text.includes('REGISTRATION_TOKEN_NOT_REGISTERED');
}

function id(ownerUserId: string): string {
  return createHash('sha256').update(ownerUserId).digest('hex');
}
