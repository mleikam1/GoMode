import assert from "node:assert/strict";
import test from "node:test";
import {photoProxyBaseUrl} from "../src/proxyUrl";

test("production photo proxy URL is project-scoped and ignores request host", () => {
  const result = photoProxyBaseUrl(
    requestLike("attacker.example", "/placePhoto"),
    {GCLOUD_PROJECT: "wingman-interactive-live"},
  );

  assert.equal(
    result,
    "https://us-central1-wingman-interactive-live.cloudfunctions.net/placePhotoProxy",
  );
});

test("emulator photo proxy URL preserves the emulator route prefix", () => {
  const result = photoProxyBaseUrl(
    requestLike(
      "127.0.0.1:5001",
      "/wingman-interactive-live/us-central1/placePhoto",
      "http",
    ),
    {FUNCTIONS_EMULATOR: "true"},
  );

  assert.equal(
    result,
    "http://127.0.0.1:5001/wingman-interactive-live/us-central1/placePhotoProxy",
  );
});

function requestLike(host: string, originalUrl: string, protocol = "https") {
  return {
    host,
    originalUrl,
    protocol,
    get(name: string): string | undefined {
      return name.toLowerCase() === "host" ? this.host : undefined;
    },
  };
}
