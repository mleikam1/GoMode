import assert from "node:assert/strict";
import test from "node:test";
import {createBackend} from "../src/backend";
import {GoogleApiClient} from "../src/googleApiClient";
import {FetchLike} from "../src/types";

test("computeRoute and roadTripStops normalize route data and cap route searches", async () => {
  let nearbyCalls = 0;
  const backend = backendWithFetch(async (input) => {
    const url = new URL(input instanceof Request ? input.url : input.toString());
    if (url.pathname.endsWith(":computeRoutes")) {
      return jsonResponse({
        routes: [
          {
            distanceMeters: 12345,
            duration: "901.5s",
            polyline: {encodedPolyline: "_p~iF~ps|U_ulLnnqC_mqNvxq`@"},
          },
        ],
      });
    }
    if (url.pathname.endsWith(":searchNearby")) {
      nearbyCalls += 1;
      return jsonResponse({
        places: [
          {id: `stop-${nearbyCalls}`, displayName: {text: "Stop"}},
          {id: "duplicate", displayName: {text: "Shared stop"}},
        ],
      });
    }
    throw new Error(`Unexpected URL ${url}`);
  });

  const route = await backend.computeRoute({
    origin: {latitude: 38.5, longitude: -120.2},
    destination: {latitude: 43.252, longitude: -126.453},
    travelMode: "drive",
  });
  assert.deepEqual(route, {
    route: {
      distanceMeters: 12345,
      durationSeconds: 902,
      encodedPolyline: "_p~iF~ps|U_ulLnnqC_mqNvxq`@",
    },
  });

  const roadTrip = await backend.roadTripStops({
    origin: {latitude: 38.5, longitude: -120.2},
    destination: {latitude: 43.252, longitude: -126.453},
    categories: ["restaurant", "gas_station"],
  });
  assert.equal(nearbyCalls, 3);
  assert.equal((roadTrip.stops as unknown[]).length, 4);
  assert.equal(roadTrip.strategy, "route_polyline_midpoints");
  assert.deepEqual(roadTrip.route, route.route);
});

test("computeRoute rejects malformed upstream route metrics", async () => {
  const backend = backendWithFetch(async () =>
    jsonResponse({routes: [{polyline: {encodedPolyline: "abc"}}]}),
  );

  await assert.rejects(
    backend.computeRoute({
      origin: {latitude: 30, longitude: -97},
      destination: {latitude: 31, longitude: -98},
      travelMode: "DRIVE",
    }),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      (error as Error & {code: string}).code === "unavailable",
  );
});

test("airQuality keeps current conditions primary and gates forecast", async () => {
  let calls = 0;
  const fetchImpl: FetchLike = async () => {
    calls += 1;
    return jsonResponse({
      dateTime: "2026-07-10T12:00:00Z",
      indexes: [{code: "uaqi", aqi: 42, category: "Good", dominantPollutant: "pm25"}],
      healthRecommendations: {generalPopulation: "Enjoy outdoor activities."},
    });
  };
  const disabled = backendWithFetch(fetchImpl, false, false);

  const result = await disabled.airQuality({
    latitude: 30,
    longitude: -97,
    includeForecast: true,
    forecastHours: 6,
  });

  assert.equal(calls, 1);
  assert.deepEqual(result.current, {
    dateTime: "2026-07-10T12:00:00Z",
    aqi: 42,
    category: "Good",
    dominantPollutant: "pm25",
    healthRecommendation: "Enjoy outdoor activities.",
  });
  assert.deepEqual(result.forecast, []);
  assert.equal(result.forecastAvailable, false);
  assert.equal(result.forecastStatus, "not_configured");
});

test("solarCheck does not make a request while the opt-in flag is disabled", async () => {
  let calls = 0;
  const backend = backendWithFetch(async () => {
    calls += 1;
    return jsonResponse({});
  });

  const result = await backend.solarCheck({address: "101 Congress Ave, Austin, TX"});

  assert.equal(calls, 0);
  assert.deepEqual(result, {
    available: false,
    status: "not_configured",
    address: "101 Congress Ave, Austin, TX",
    reason: "Solar checks are not enabled for this deployment.",
  });
});

test("pollen includes the requested coordinates and normalized daily data", async () => {
  const backend = backendWithFetch(async () =>
    jsonResponse({regionCode: "US", dailyInfo: [{date: {year: 2026}}]}),
  );

  const result = await backend.pollen({latitude: 30.2, longitude: -97.7, days: 2});

  assert.deepEqual(result, {
    latitude: 30.2,
    longitude: -97.7,
    regionCode: "US",
    dailyInfo: [{date: {year: 2026}}],
  });
});

function backendWithFetch(
  fetchImpl: FetchLike,
  forecastEnabled = false,
  solarEnabled = false,
) {
  const client = new GoogleApiClient("test-api-key", {
    fetchImpl,
    maxAttempts: 1,
    retryDelayMs: 0,
    sleep: async () => undefined,
  });
  return createBackend(client, {
    airQualityForecastEnabled: forecastEnabled,
    solarEnabled,
  });
}

function jsonResponse(value: unknown, status = 200): Response {
  return new Response(JSON.stringify(value), {
    status,
    headers: {"content-type": "application/json"},
  });
}
