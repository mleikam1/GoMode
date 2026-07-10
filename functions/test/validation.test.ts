import assert from "node:assert/strict";
import test from "node:test";
import {BackendError} from "../src/errors";
import {
  validateAutocomplete,
  validatePlacePhoto,
  validateRoadTripStops,
  validateSearchPlaces,
} from "../src/validation";

test("validation rejects unknown fields and out-of-range coordinates", () => {
  assert.throws(
    () =>
      validateSearchPlaces({
        latitude: 30,
        longitude: -97,
        modeId: "food-wheel",
        radius: 1_000,
        surprise: true,
      }),
    (error) => error instanceof BackendError && error.code === "invalid-argument",
  );
  assert.throws(() =>
    validateSearchPlaces({
      latitude: 91,
      longitude: -97,
      modeId: "food-wheel",
      radius: 1_000,
    }),
  );
});

test("road trip validation caps categories at three", () => {
  assert.throws(() =>
    validateRoadTripStops({
      origin: "Austin, TX",
      destination: "Dallas, TX",
      categories: ["restaurant", "cafe", "gas_station", "park"],
    }),
  );
});

test("place categories are limited to documented app types", () => {
  assert.throws(() =>
    validateSearchPlaces({
      latitude: 30,
      longitude: -97,
      modeId: "food-wheel",
      radius: 1_000,
      category: "made_up_place_type",
    }),
  );
  assert.throws(() =>
    validateRoadTripStops({
      origin: "Austin, TX",
      destination: "Dallas, TX",
      categories: ["restaurant", "made_up_place_type"],
    }),
  );
});

test("autocomplete requires a safe session token and coordinate pair", () => {
  assert.throws(() =>
    validateAutocomplete({
      text: "coffee",
      sessionToken: "token with spaces",
    }),
  );
  assert.throws(() =>
    validateAutocomplete({
      text: "coffee",
      sessionToken: "token-1",
      latitude: 30,
    }),
  );
});

test("photo validation accepts only Places photo resource names and clamps width", () => {
  assert.deepEqual(
    validatePlacePhoto({photoName: "places/abc/photos/def", maxWidthPx: 1_200}),
    {photoName: "places/abc/photos/def", maxWidthPx: 1_200},
  );
  assert.throws(() =>
    validatePlacePhoto({photoName: "https://example.com/photo", maxWidthPx: 800}),
  );
  assert.throws(() =>
    validatePlacePhoto({photoName: "places/abc/photos/def", maxWidthPx: 1_201}),
  );
});
