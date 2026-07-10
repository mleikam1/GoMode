import {BackendError, GoogleApiError} from "./errors";
import {GoogleApiClient} from "./googleApiClient";
import {
  decodePolyline,
  interpolateWaypoints,
  sampleRoutePoints,
} from "./polyline";
import {BackendOptions, Coordinate} from "./types";
import {
  validateAirQuality,
  validateAutocomplete,
  validateComputeRoute,
  validatePlaceDetails,
  validatePollen,
  validateRoadTripStops,
  validateSearchPlaces,
  validateSolarCheck,
} from "./validation";

export function createBackend(
  client: GoogleApiClient,
  options: BackendOptions,
) {
  return {
    searchPlaces: (data: unknown) => client.searchPlaces(validateSearchPlaces(data)),

    async placeDetails(data: unknown): Promise<Record<string, unknown>> {
      return {place: await client.placeDetails(validatePlaceDetails(data))};
    },

    async computeRoute(data: unknown): Promise<Record<string, unknown>> {
      const response = await client.computeRoute(validateComputeRoute(data));
      return {route: normalizePrimaryRoute(response)};
    },

    async roadTripStops(data: unknown): Promise<Record<string, unknown>> {
      const input = validateRoadTripStops(data);
      const routeResponse = await client.computeRoute({
        origin: input.origin,
        destination: input.destination,
        travelMode: "DRIVE",
      });
      const routes = arrayProperty(routeResponse, "routes");
      const rawRoute = isObject(routes[0]) ? routes[0] : null;
      const route = normalizePrimaryRoute(routeResponse);
      const encodedPolyline = readEncodedPolyline(rawRoute);
      let points: Coordinate[] = [];
      let strategy = "route_polyline_midpoints";

      if (encodedPolyline !== undefined) {
        try {
          points = sampleRoutePoints(decodePolyline(encodedPolyline), 3);
        } catch {
          points = [];
        }
      }
      if (
        points.length === 0 &&
        typeof input.origin !== "string" &&
        typeof input.destination !== "string"
      ) {
        points = interpolateWaypoints(input.origin, input.destination, 3);
        strategy = "coordinate_interpolation";
      } else if (points.length === 0) {
        strategy = "route_geometry_unavailable";
      }

      const nearbyResults = await Promise.allSettled(
        points.map((point) =>
          client.nearbyRoadTripPlaces(point, input.categories, 8_000),
        ),
      );
      if (
        nearbyResults.length > 0 &&
        nearbyResults.every((result) => result.status === "rejected")
      ) {
        throw nearbyResults[0]!.reason;
      }
      const uniqueStops = new Map<string, Record<string, unknown>>();
      nearbyResults.forEach((result) => {
        if (result.status === "rejected") return;
        const places = result.value;
        for (const place of places) {
          const id = typeof place.id === "string" ? place.id : undefined;
          if (id === undefined || uniqueStops.has(id) || uniqueStops.size >= 15) {
            continue;
          }
          uniqueStops.set(id, {
            ...place,
          });
        }
      });

      return {
        route,
        stops: [...uniqueStops.values()],
        strategy,
      };
    },

    async airQuality(data: unknown): Promise<Record<string, unknown>> {
      const input = validateAirQuality(data);
      const current = normalizeCurrentAirQuality(
        await client.airQualityCurrent(input),
      );
      if (!input.includeForecast) {
        return {
          latitude: input.latitude,
          longitude: input.longitude,
          current,
          forecast: [],
          forecastAvailable: false,
          forecastStatus: "not_requested",
        };
      }
      if (!options.airQualityForecastEnabled) {
        return {
          latitude: input.latitude,
          longitude: input.longitude,
          current,
          forecast: [],
          forecastAvailable: false,
          forecastStatus: "not_configured",
        };
      }
      try {
        const forecast = normalizeAirQualityForecast(
          await client.airQualityForecast(input),
        );
        return {
          latitude: input.latitude,
          longitude: input.longitude,
          current,
          forecast,
          forecastAvailable: true,
          forecastStatus: "available",
        };
      } catch (error) {
        if (!(error instanceof BackendError)) throw error;
        return {
          latitude: input.latitude,
          longitude: input.longitude,
          current,
          forecast: [],
          forecastAvailable: false,
          forecastStatus: "temporarily_unavailable",
        };
      }
    },

    async pollen(data: unknown): Promise<Record<string, unknown>> {
      const input = validatePollen(data);
      const response = await client.pollen(input);
      return {
        latitude: input.latitude,
        longitude: input.longitude,
        ...(typeof response.regionCode === "string"
          ? {regionCode: response.regionCode}
          : {}),
        dailyInfo: arrayProperty(response, "dailyInfo"),
      };
    },

    async solarCheck(data: unknown): Promise<Record<string, unknown>> {
      const input = validateSolarCheck(data);
      if (!options.solarEnabled) {
        return {
          available: false,
          status: "not_configured",
          address: input.address,
          reason: "Solar checks are not enabled for this deployment.",
        };
      }
      const address = await client.resolveAddress(input);
      if (address === null) {
        return {
          available: false,
          status: "address_not_found",
          address: input.address,
          reason: "The address could not be resolved.",
        };
      }
      try {
        const insights = await client.solarBuildingInsights(address.location);
        return {
          available: true,
          status: "available",
          address: address.formattedAddress ?? input.address,
          location: address.location,
          buildingInsights: insights,
        };
      } catch (error) {
        if (!(error instanceof BackendError)) throw error;
        return {
          available: false,
          status:
            error instanceof GoogleApiError && error.upstreamStatus === 404
              ? "no_coverage"
              : "upstream_unavailable",
          address: address.formattedAddress ?? input.address,
          reason: "Solar data is unavailable for this address.",
        };
      }
    },

    autocomplete: (data: unknown) =>
      client.autocomplete(validateAutocomplete(data)),
  };
}

function readEncodedPolyline(
  route: Record<string, unknown> | null,
): string | undefined {
  if (route === null || !isObject(route.polyline)) return undefined;
  return typeof route.polyline.encodedPolyline === "string"
    ? route.polyline.encodedPolyline
    : undefined;
}

function normalizePrimaryRoute(
  response: Record<string, unknown>,
): Record<string, unknown> {
  const rawRoute = arrayProperty(response, "routes").find(isObject);
  if (rawRoute === undefined) {
    throw new BackendError("not-found", "No route was found for those locations.");
  }
  const distanceMeters = rawRoute.distanceMeters;
  const duration = rawRoute.duration;
  if (
    typeof distanceMeters !== "number" ||
    !Number.isInteger(distanceMeters) ||
    distanceMeters < 0 ||
    typeof duration !== "string" ||
    !/^\d+(?:\.\d+)?s$/.test(duration)
  ) {
    throw new BackendError(
      "unavailable",
      "The map service returned an invalid route.",
    );
  }
  const durationSeconds = Number(duration.slice(0, -1));
  if (!Number.isFinite(durationSeconds)) {
    throw new BackendError(
      "unavailable",
      "The map service returned an invalid route.",
    );
  }
  const encodedPolyline = readEncodedPolyline(rawRoute);
  return {
    distanceMeters,
    durationSeconds: Math.round(durationSeconds),
    ...(encodedPolyline === undefined ? {} : {encodedPolyline}),
  };
}

function normalizeCurrentAirQuality(
  response: Record<string, unknown>,
): Record<string, unknown> {
  const index = preferredAirQualityIndex(arrayProperty(response, "indexes"));
  const recommendations = isObject(response.healthRecommendations)
    ? response.healthRecommendations
    : {};
  return {
    ...(typeof response.dateTime === "string" ? {dateTime: response.dateTime} : {}),
    ...(typeof index?.aqi === "number" ? {aqi: index.aqi} : {}),
    ...(typeof index?.category === "string" ? {category: index.category} : {}),
    ...(typeof index?.dominantPollutant === "string"
      ? {dominantPollutant: index.dominantPollutant}
      : {}),
    ...(typeof recommendations.generalPopulation === "string"
      ? {healthRecommendation: recommendations.generalPopulation}
      : {}),
  };
}

function normalizeAirQualityForecast(
  response: Record<string, unknown>,
): Record<string, unknown>[] {
  return arrayProperty(response, "hourlyForecasts")
    .filter(isObject)
    .map((hour) => {
      const index = preferredAirQualityIndex(arrayProperty(hour, "indexes"));
      return {
        ...(typeof hour.dateTime === "string" ? {dateTime: hour.dateTime} : {}),
        ...(typeof index?.aqi === "number" ? {aqi: index.aqi} : {}),
        ...(typeof index?.category === "string"
          ? {category: index.category}
          : {}),
        ...(typeof index?.dominantPollutant === "string"
          ? {dominantPollutant: index.dominantPollutant}
          : {}),
      };
    });
}

function preferredAirQualityIndex(values: unknown[]): Record<string, unknown> | undefined {
  const indexes = values.filter(isObject);
  return indexes.find((index) => index.code === "uaqi") ?? indexes[0];
}

function arrayProperty(value: Record<string, unknown>, key: string): unknown[] {
  return Array.isArray(value[key]) ? value[key] : [];
}

function isObject(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
