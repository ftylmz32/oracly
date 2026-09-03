import type { AppConfig } from '../config.js';
import { ErrorCode, fail } from '../errors.js';
import { asRecord, sanitizeText } from './sanitize.js';

const ALLOWED = new Set(['image/jpeg', 'image/jpg', 'image/png', 'image/webp']);

export type CoffeeImage = {
  mimeType: string;
  bytes: Buffer;
};

export function parseCoffeeImage(
  payload: Record<string, unknown>,
  config: AppConfig,
): CoffeeImage {
  const mime = sanitizeText(payload.mimeType, 64).toLowerCase();
  if (!mime || !ALLOWED.has(mime)) fail(ErrorCode.unsupportedImageType);
  const b64 =
    typeof payload.imageBase64 === 'string' ? payload.imageBase64.trim() : '';
  if (!b64) fail(ErrorCode.invalidImage);
  const maxB64 = Math.ceil((config.maxImageBytes * 4) / 3) + 128;
  if (b64.length > maxB64) fail(ErrorCode.imageTooLarge);
  let bytes: Buffer;
  try {
    bytes = Buffer.from(b64, 'base64');
  } catch {
    fail(ErrorCode.invalidImage);
  }
  // Reject obviously corrupt base64 (decoded empty / nonsense).
  if (bytes.length === 0) fail(ErrorCode.invalidImage);
  if (bytes.length > config.maxImageBytes) fail(ErrorCode.imageTooLarge);
  if (bytes.length < config.minImageBytes) fail(ErrorCode.invalidImage);
  if (!magicMatches(bytes, mime)) fail(ErrorCode.invalidImage);
  return {
    mimeType: mime === 'image/jpg' ? 'image/jpeg' : mime,
    bytes,
  };
}

export function coffeePayloadFromUnknown(
  payload: unknown,
  config: AppConfig,
): CoffeeImage {
  const record = asRecord(payload);
  if (!record) fail(ErrorCode.invalidRequest);
  return parseCoffeeImage(record, config);
}

/** Validate provider-returned portrait bytes — never log content. */
export function assertGeneratedImageBytes(
  imageBase64: string,
  config: AppConfig,
): { bytes: Buffer; mimeType: string } {
  const trimmed = imageBase64.trim();
  if (!trimmed) fail(ErrorCode.invalidResponse);
  let bytes: Buffer;
  try {
    bytes = Buffer.from(trimmed, 'base64');
  } catch {
    fail(ErrorCode.invalidResponse);
  }
  if (bytes.length < 32) fail(ErrorCode.invalidResponse);
  if (bytes.length > config.maxImageBytes) fail(ErrorCode.imageTooLarge);
  if (magicMatches(bytes, 'image/png')) {
    return { bytes, mimeType: 'image/png' };
  }
  if (magicMatches(bytes, 'image/jpeg')) {
    return { bytes, mimeType: 'image/jpeg' };
  }
  if (magicMatches(bytes, 'image/webp')) {
    return { bytes, mimeType: 'image/webp' };
  }
  fail(ErrorCode.invalidResponse);
}

export function magicMatches(bytes: Buffer, mime: string): boolean {
  if (mime === 'image/jpeg' || mime === 'image/jpg') {
    return (
      bytes.length >= 3 &&
      bytes[0] === 0xff &&
      bytes[1] === 0xd8 &&
      bytes[2] === 0xff
    );
  }
  if (mime === 'image/png') {
    return (
      bytes.length >= 8 &&
      bytes[0] === 0x89 &&
      bytes[1] === 0x50 &&
      bytes[2] === 0x4e &&
      bytes[3] === 0x47
    );
  }
  if (mime === 'image/webp') {
    return (
      bytes.length >= 12 &&
      bytes.toString('ascii', 0, 4) === 'RIFF' &&
      bytes.toString('ascii', 8, 12) === 'WEBP'
    );
  }
  return false;
}
