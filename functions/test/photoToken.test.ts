import assert from "node:assert/strict";
import test from "node:test";
import {
  appendSignedPhotoQuery,
  signPhotoToken,
  verifyPhotoToken,
} from "../src/photoToken";

const SIGNING_KEY = "a-test-signing-key-that-is-at-least-32-bytes";

test("photo proxy tokens round trip and reject tampering", () => {
  const payload = {
    photoName: "places/abc/photos/def",
    maxWidthPx: 800,
    expires: 1_300,
  };
  const signature = signPhotoToken(payload, SIGNING_KEY);

  assert.doesNotThrow(() =>
    verifyPhotoToken(payload, signature, SIGNING_KEY, 1_000),
  );
  assert.throws(() =>
    verifyPhotoToken({...payload, maxWidthPx: 801}, signature, SIGNING_KEY, 1_000),
  );
  assert.throws(() =>
    verifyPhotoToken(payload, signature, SIGNING_KEY, 1_301),
  );
});

test("signed photo URL contains no Google API key", () => {
  const url = new URL(
    appendSignedPhotoQuery(
      "https://us-central1-example.cloudfunctions.net/placePhotoProxy",
      {
        photoName: "places/abc/photos/def",
        maxWidthPx: 800,
        expires: 1_300,
      },
      SIGNING_KEY,
    ),
  );

  assert.equal(url.searchParams.get("photoName"), "places/abc/photos/def");
  assert.equal(url.searchParams.get("maxWidthPx"), "800");
  assert.ok(url.searchParams.get("signature"));
  assert.equal(url.searchParams.has("key"), false);
});
