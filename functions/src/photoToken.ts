import {createHmac, timingSafeEqual} from "node:crypto";
import {BackendError} from "./errors";

export interface PhotoTokenPayload {
  photoName: string;
  maxWidthPx: number;
  expires: number;
}

export function signPhotoToken(
  payload: PhotoTokenPayload,
  signingKey: string,
): string {
  requireSigningKey(signingKey);
  return createHmac("sha256", signingKey)
    .update(serializedPayload(payload))
    .digest("base64url");
}

export function verifyPhotoToken(
  payload: PhotoTokenPayload,
  signature: string,
  signingKey: string,
  nowSeconds = Math.floor(Date.now() / 1_000),
): void {
  requireSigningKey(signingKey);
  if (
    !Number.isInteger(payload.expires) ||
    payload.expires < nowSeconds ||
    payload.expires > nowSeconds + 305
  ) {
    throw new BackendError("invalid-argument", "The photo URL has expired.");
  }
  const expected = Buffer.from(signPhotoToken(payload, signingKey), "base64url");
  let provided: Buffer;
  try {
    provided = Buffer.from(signature, "base64url");
  } catch {
    throw new BackendError("invalid-argument", "The photo URL is invalid.");
  }
  if (provided.length !== expected.length || !timingSafeEqual(provided, expected)) {
    throw new BackendError("invalid-argument", "The photo URL is invalid.");
  }
}

export function appendSignedPhotoQuery(
  baseUrl: string,
  payload: PhotoTokenPayload,
  signingKey: string,
): string {
  const url = new URL(baseUrl);
  url.searchParams.set("photoName", payload.photoName);
  url.searchParams.set("maxWidthPx", String(payload.maxWidthPx));
  url.searchParams.set("expires", String(payload.expires));
  url.searchParams.set("signature", signPhotoToken(payload, signingKey));
  return url.toString();
}

function serializedPayload(payload: PhotoTokenPayload): string {
  return `${payload.photoName}\n${payload.maxWidthPx}\n${payload.expires}`;
}

function requireSigningKey(signingKey: string): void {
  if (signingKey.length < 32) {
    throw new BackendError(
      "failed-precondition",
      "The photo proxy signing secret is not configured correctly.",
    );
  }
}
