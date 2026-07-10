import assert from "node:assert/strict";
import test from "node:test";
import {
  AIR_QUALITY_CURRENT_FIELDS,
  AIR_QUALITY_FORECAST_FIELDS,
  GoogleApiClient,
  PATIO_PLACE_SEARCH_FIELDS,
  PLACE_DETAILS_FIELDS,
  PLACE_SEARCH_FIELDS,
  POLLEN_FIELDS,
  ROUTE_FIELDS,
} from "../src/googleApiClient";
import {FetchLike} from "../src/types";

test("air quality requests only fields normalized for Flutter", async () => {
  const calls: URL[] = [];
  const client = testClient(async (input) => {
    calls.push(toUrl(input));
    return jsonResponse(calls.length === 1 ? {indexes: []} : {hourlyForecasts: []});
  });

  const input = {
    latitude: 30.2672,
    longitude: -97.7431,
    includeForecast: true,
    forecastHours: 6,
  };
  await client.airQualityCurrent(input);
  await client.airQualityForecast(input);

  assert.equal(calls[0]!.searchParams.get("fields"), AIR_QUALITY_CURRENT_FIELDS);
  assert.equal(calls[1]!.searchParams.get("fields"), AIR_QUALITY_FORECAST_FIELDS);
  assert.equal(AIR_QUALITY_CURRENT_FIELDS.includes("regionCode"), false);
  assert.equal(AIR_QUALITY_CURRENT_FIELDS.includes("displayName"), false);
  assert.equal(AIR_QUALITY_CURRENT_FIELDS.includes("aqiDisplay"), false);
  assert.equal(AIR_QUALITY_CURRENT_FIELDS.includes("color"), false);
  assert.equal(AIR_QUALITY_CURRENT_FIELDS.includes("elderly"), false);
  assert.equal(AIR_QUALITY_FORECAST_FIELDS.includes("regionCode"), false);
});

test("searchPlaces uses Text Search pageSize for openNow and never puts key in URL", async () => {
  const calls: Array<{url: URL; init?: RequestInit}> = [];
  const fetchImpl: FetchLike = async (input, init) => {
    calls.push({url: toUrl(input), init});
    return jsonResponse({places: [{id: "place-1"}]});
  };
  const client = testClient(fetchImpl);

  const result = await client.searchPlaces({
    latitude: 30.2672,
    longitude: -97.7431,
    modeId: "open-now",
    category: "restaurant",
    radius: 5_000,
    openNow: true,
    maxResults: 7,
  });

  assert.deepEqual(result, {places: [{id: "place-1", openNow: true}]});
  assert.equal(calls.length, 1);
  assert.equal(calls[0]!.url.pathname, "/v1/places:searchText");
  assert.equal(calls[0]!.url.searchParams.has("key"), false);
  const headers = calls[0]!.init!.headers as Record<string, string>;
  assert.equal(headers["X-Goog-Api-Key"], "test-api-key");
  assert.equal(headers["X-Goog-FieldMask"], PLACE_SEARCH_FIELDS);
  assert.equal(PLACE_SEARCH_FIELDS.includes("rating"), false);
  const body = JSON.parse(calls[0]!.init!.body as string) as Record<string, unknown>;
  assert.equal(body.pageSize, 7);
  assert.equal(body.openNow, true);
  assert.equal(body.includedType, "restaurant");
  assert.equal("maxResultCount" in body, false);
  assert.equal(
    (result.places[0] as Record<string, unknown>).openNow,
    true,
  );
});

test("Patio Finder alone requests ranking signals from search", async () => {
  let mask = "";
  const client = testClient(async (_input, init) => {
    mask = (init!.headers as Record<string, string>)["X-Goog-FieldMask"]!;
    return jsonResponse({places: []});
  });

  await client.searchPlaces({
    latitude: 30,
    longitude: -97,
    modeId: "patio-finder",
    query: "restaurant patio",
    category: "restaurant",
    radius: 5_000,
    openNow: false,
    maxResults: 8,
  });

  assert.equal(mask, PATIO_PLACE_SEARCH_FIELDS);
  assert.match(mask, /places\.rating/);
  assert.match(mask, /places\.userRatingCount/);
  assert.match(mask, /places\.photos\.name/);
  assert.equal(PLACE_SEARCH_FIELDS.includes("rating"), false);
  assert.equal(PLACE_SEARCH_FIELDS.includes("photos"), false);
});

test("searchPlaces uses Nearby Search only when no query or openNow filter is present", async () => {
  let capturedBody: Record<string, unknown> | undefined;
  const client = testClient(async (_input, init) => {
    capturedBody = JSON.parse(init!.body as string) as Record<string, unknown>;
    return jsonResponse({places: []});
  });

  await client.searchPlaces({
    latitude: 30,
    longitude: -97,
    modeId: "food-wheel",
    radius: 2_000,
    openNow: false,
    maxResults: 5,
  });

  assert.deepEqual(capturedBody!.includedTypes, ["restaurant"]);
  assert.equal(capturedBody!.maxResultCount, 5);
  assert.equal("openNow" in capturedBody!, false);
});

test("placeDetails forwards an autocomplete session token and an explicit minimal mask", async () => {
  let captured: {url: URL; headers: Record<string, string>} | undefined;
  const client = testClient(async (input, init) => {
    captured = {
      url: toUrl(input),
      headers: init!.headers as Record<string, string>,
    };
    return jsonResponse({id: "abc"});
  });

  await client.placeDetails({placeId: "abc/unsafe", sessionToken: "session-1"});

  assert.equal(captured!.url.pathname, "/v1/places/abc%2Funsafe");
  assert.equal(captured!.url.searchParams.get("sessionToken"), "session-1");
  assert.equal(captured!.headers["X-Goog-FieldMask"], PLACE_DETAILS_FIELDS);
  assert.equal(PLACE_DETAILS_FIELDS.includes("websiteUri"), true);
  assert.equal(PLACE_DETAILS_FIELDS.includes("nationalPhoneNumber"), true);
  assert.match(PLACE_DETAILS_FIELDS, /photos\.authorAttributions\.displayName/);
});

test("computeRoute uses only distance, duration, and encoded polyline fields", async () => {
  let mask = "";
  let body: Record<string, unknown> = {};
  const client = testClient(async (_input, init) => {
    mask = (init!.headers as Record<string, string>)["X-Goog-FieldMask"]!;
    body = JSON.parse(init!.body as string) as Record<string, unknown>;
    return jsonResponse({routes: []});
  });

  await client.computeRoute({
    origin: {latitude: 30, longitude: -97},
    destination: "Dallas, TX",
    travelMode: "DRIVE",
  });

  assert.equal(mask, ROUTE_FIELDS);
  assert.equal(mask, "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline");
  assert.deepEqual(body.destination, {address: "Dallas, TX"});
});

test("pollen requests only the fields consumed by Flutter, including inSeason", async () => {
  let capturedUrl: URL | undefined;
  const client = testClient(async (input) => {
    capturedUrl = toUrl(input);
    return jsonResponse({dailyInfo: []});
  });

  await client.pollen({latitude: 30.2, longitude: -97.7, days: 3});

  assert.equal(
    POLLEN_FIELDS,
    "dailyInfo(date,pollenTypeInfo(code,displayName,inSeason,indexInfo(value,category)))",
  );
  assert.equal(capturedUrl!.searchParams.get("fields"), POLLEN_FIELDS);
  assert.equal(POLLEN_FIELDS.includes("healthRecommendations"), false);
  assert.equal(POLLEN_FIELDS.includes("indexDescription"), false);
  assert.equal(POLLEN_FIELDS.includes("color"), false);
  assert.equal(POLLEN_FIELDS.includes("indexInfo(code"), false);
  assert.equal(POLLEN_FIELDS.includes("indexInfo(displayName"), false);
});

test("place photo resolves metadata first and downloads only an allowlisted host without a key", async () => {
  const calls: Array<{url: URL; init?: RequestInit}> = [];
  const client = testClient(async (input, init) => {
    const url = toUrl(input);
    calls.push({url, init});
    if (calls.length === 1) {
      return jsonResponse({photoUri: "https://lh3.googleusercontent.com/photo"});
    }
    return new Response(Uint8Array.from([1, 2, 3]), {
      status: 200,
      headers: {"content-type": "image/jpeg"},
    });
  });

  const photo = await client.fetchPlacePhoto("places/abc/photos/def", 800);

  assert.equal(photo.contentType, "image/jpeg");
  assert.deepEqual([...photo.bytes], [1, 2, 3]);
  assert.equal(calls[0]!.url.searchParams.get("skipHttpRedirect"), "true");
  assert.equal(calls[0]!.url.searchParams.has("key"), false);
  const secondHeaders = calls[1]!.init!.headers as Record<string, string>;
  assert.equal(secondHeaders["X-Goog-Api-Key"], undefined);
  assert.equal(calls[1]!.init!.redirect, "error");
});

test("transient upstream failures retry at most once", async () => {
  let attempts = 0;
  const client = new GoogleApiClient("test-api-key", {
    fetchImpl: async () => {
      attempts += 1;
      return attempts === 1
        ? jsonResponse({error: "busy"}, 503)
        : jsonResponse({places: []});
    },
    retryDelayMs: 0,
    sleep: async () => undefined,
  });

  await client.searchPlaces({
    latitude: 30,
    longitude: -97,
    modeId: "food-wheel",
    radius: 1_000,
    openNow: false,
    maxResults: 3,
  });

  assert.equal(attempts, 2);
});

function testClient(fetchImpl: FetchLike): GoogleApiClient {
  return new GoogleApiClient("test-api-key", {
    fetchImpl,
    maxAttempts: 1,
    retryDelayMs: 0,
    sleep: async () => undefined,
  });
}

function jsonResponse(value: unknown, status = 200): Response {
  return new Response(JSON.stringify(value), {
    status,
    headers: {"content-type": "application/json"},
  });
}

function toUrl(input: string | URL | Request): URL {
  return new URL(input instanceof Request ? input.url : input.toString());
}
