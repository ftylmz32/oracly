import { createHash } from 'node:crypto';
import { Timestamp } from '@google-cloud/firestore';
import type {
  FirestoreDocRefLike,
  FirestoreDocSnapshotLike,
  FirestoreLike,
  FirestoreTransactionLike,
} from '../billing/entitlement-repository.js';

const ADMISSION = 'readingAdmission';
const RATE_WINDOWS = 'securityRateWindows';

export type ReadingAdmissionLimits = {
  activeMaxPerIdentity: number;
  createRateMax: number;
  createRateWindowMs: number;
};

export const DEFAULT_READING_ADMISSION_LIMITS: ReadingAdmissionLimits = {
  activeMaxPerIdentity: 6,
  createRateMax: 10,
  createRateWindowMs: 15 * 60 * 1000,
};

export class ReadingAdmissionDenied extends Error {
  constructor(readonly reason: 'active_cap' | 'create_rate') {
    super(reason);
    this.name = 'ReadingAdmissionDenied';
  }
}

export function readingAdmissionLimitsFromConfig(config: {
  readingActiveMaxPerIdentity: number;
  readingCreateRateMax: number;
  readingCreateRateWindowMs: number;
}): ReadingAdmissionLimits {
  return {
    activeMaxPerIdentity: config.readingActiveMaxPerIdentity,
    createRateMax: config.readingCreateRateMax,
    createRateWindowMs: config.readingCreateRateWindowMs,
  };
}

export function readingAdmissionRefs(
  firestore: FirestoreLike,
  ownerUserId: string,
  windowMs: number,
  nowMs: number,
) {
  const bucket = Math.floor(nowMs / windowMs);
  return {
    admission: firestore.collection(ADMISSION).doc(hash(`reading_admission\0${ownerUserId}`)),
    rate: firestore.collection(RATE_WINDOWS).doc(hash(`reading_create\0${ownerUserId}\0${bucket}`)),
    bucket,
  };
}

export function admitNewReadingInTx(
  tx: FirestoreTransactionLike,
  input: {
    ownerUserId: string;
    nowMs: number;
    limits: ReadingAdmissionLimits;
    admissionSnap: FirestoreDocSnapshotLike;
    rateSnap: FirestoreDocSnapshotLike;
    refs: ReturnType<typeof readingAdmissionRefs>;
  },
): void {
  const activeCount = count(input.admissionSnap, 'activeCount');
  if (activeCount >= input.limits.activeMaxPerIdentity) {
    throw new ReadingAdmissionDenied('active_cap');
  }
  const rateCount = count(input.rateSnap, 'count');
  if (rateCount >= input.limits.createRateMax) {
    throw new ReadingAdmissionDenied('create_rate');
  }
  tx.set(input.refs.admission, {
    activeCount: activeCount + 1,
    updatedAtMs: input.nowMs,
  });
  tx.set(input.refs.rate, {
    scope: 'reading_create',
    bucket: input.refs.bucket,
    count: rateCount + 1,
    expiresAt: Timestamp.fromMillis((input.refs.bucket + 2) * input.limits.createRateWindowMs),
    updatedAt: Timestamp.fromMillis(input.nowMs),
  });
}

export function releaseActiveReadingInTx(
  tx: FirestoreTransactionLike,
  nowMs: number,
  admissionSnap: FirestoreDocSnapshotLike,
  admissionRef: FirestoreDocRefLike,
): void {
  tx.set(admissionRef, {
    activeCount: Math.max(0, count(admissionSnap, 'activeCount') - 1),
    updatedAtMs: nowMs,
  });
}

function count(snapshot: FirestoreDocSnapshotLike, field: string): number {
  const value = snapshot.data()?.[field];
  return typeof value === 'number' && Number.isFinite(value) ? Math.max(0, value) : 0;
}

function hash(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}
