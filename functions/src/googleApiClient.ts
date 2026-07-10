import {BackendError, GoogleApiError} from "./errors";
import {
  AirQualityInput,
  AutocompleteInput,
  ComputeRouteInput,
  Coordinate,
  FetchLike,
  PlaceDetailsInput,
  PollenInput,
  SearchPlacesInput,
  SolarCheckInput,
  WaypointInput,
} from "./types";

const PLACES_BASE = "https://places.googleapis.com/v1";
const ROUTES_BASE = "https://routes.googleapis.com/directions/v2";
const AIR_QUALITY_BASE = "https://airquality.googleapis.com/v1";
const POLLEN_BASE = "https://pollen.googleapis.com/v1";
const SOLAR_BASE = "https://solar.googleapis.com/v1";

export const PLACE_SEARCH_FIELDS = [
  "places.id",
  "places.displayName",
  "places.formattedAddress",
  "places.location",
  "places.primaryType",
  "places.types",
  "places.photos.name",
  "places.photos.authorAttributions.displayName",
  "places.photos.authorAttributions.uri",
  "places.photos.authorAttributions.photoUri",
].join(",");

export const PLACE_DETAILS_FIELDS = [
  "id",
  "displayName",
  "formattedAddress",
  "location",
  "primaryType",
  "types",
  "rating",
  "userRatingCount",
  "currentOpeningHours.openNow",
  "googleMapsUri",
  "photos.name",
  "photos.authorAttributions.displayName",
  "photos.authorAttributions.uri",
  "photos.authorAttributions.photoUri",
].join(",");

export const ROUTE_FIELDS = [
  "routes.distanceMeters",
  "routes.duration",
  "routes.polyline.encodedPolyline",
].join(",");

export const AIR_QUALITY_CURRENT_FIELDS = [
  "dateTime",
  "indexes(code,aqi,category,dominantPollutant)",
  "healthRecommendations(generalPopulation)",
].join(",");

export const AIR_QUALITY_FORECAST_FIELDS =
  "hourlyForecasts(dateTime,indexes(code,aqi,category,dominantPollutant))";

const ROAD_TRIP_PLACE_FIELDS = [
  "places.id",
  "places.displayName",
  "places.formattedAddress",
  "places.location",
  "places.primaryType",
  "places.types",
  "places.photos.name",
  "places.photos.authorAttributions.displayName",
  "places.photos.authorAttributions.uri",
  "places.photos.authorAttributions.photoUri",
].join(",");

const RETRYABLE_STATUSES = new Set([408, 429, 500, 502, 503, 504]);
const MAX_PHOTO_BYTES = 6 * 1024 * 1024;

export const POLLEN_FIELDS =
  "dailyInfo(date,pollenTypeInfo(code,displayName,inSeason,indexInfo(value,category)))";

export interface GoogleApiClientOptions {
  fetchImpl?: FetchLike;
  timeoutMs?: number;
  maxAttempts?: number;
  retryDelayMs?: number;
  now?: () => Date;
  sleep?: (milliseconds: number) => Promise<void>;
}

export interface PhotoBytes {
  bytes: Uint8Array;
  contentType: string;
}

export class GoogleApiClient {
  private readonly fetchImpl: FetchLike;
  private readonly timeoutMs: number;
  private readonly maxAttempts: number;
  private readonly retryDelayMs: number;
  private readonly now: () => Date;
  private readonly sleep: (milliseconds: number) => Promise<void>;

  constructor(
    private readonly apiKey: string,
    options: GoogleApiClientOptions = {},
  ) {
    if (apiKey.trim().length === 0) {
      throw new BackendError(
        "failed-precondition",
        "The Google Maps backend secret is not configured.",
      );
    }
    this.fetchImpl = options.fetchImpl ?? fetch;
    this.timeoutMs = options.timeoutMs ?? 8_000;
    this.maxAttempts = options.maxAttempts ?? 2;
    this.retryDelayMs = options.retryDelayMs ?? 150;
    this.now = options.now ?? (() => new Date());
    this.sleep =
      options.sleep ??
      ((milliseconds) =>
        new Promise((resolve) => setTimeout(resolve, milliseconds)));
  }

  async searchPlaces(input: SearchPlacesInput): Promise<Record<string, unknown>> {
    const useTextSearch = Boolean(input.query) || input.openNow;
    const response = useTextSearch
      ? await this.textSearch(input)
      : await this.nearbySearch(input);
    return {places: arrayProperty(response, "places")};
  }

  async placeDetails(input: PlaceDetailsInput): Promise<Record<string, unknown>> {
    const query = input.sessionToken
      ? {sessionToken: input.sessionToken}
      : undefined;
    return this.requestJson(
      "placeDetails",
      `${PLACES_BASE}/places/${encodeURIComponent(input.placeId)}`,
      {fieldMask: PLACE_DETAILS_FIELDS, query},
    );
  }

  async computeRoute(input: ComputeRouteInput): Promise<Record<string, unknown>> {
    return this.requestJson(
      "computeRoute",
      `${ROUTES_BASE}:computeRoutes`,
      {
        method: "POST",
        fieldMask: ROUTE_FIELDS,
        body: {
          origin: routeWaypoint(input.origin),
          destination: routeWaypoint(input.destination),
          travelMode: input.travelMode,
          computeAlternativeRoutes: false,
          polylineQuality: "OVERVIEW",
          polylineEncoding: "ENCODED_POLYLINE",
        },
      },
    );
  }

  async nearbyRoadTripPlaces(
    location: Coordinate,
    categories: string[],
    radius = 8_000,
  ): Promise<Record<string, unknown>[]> {
    const response = await this.requestJson(
      "roadTripNearbySearch",
      `${PLACES_BASE}/places:searchNearby`,
      {
        method: "POST",
        fieldMask: ROAD_TRIP_PLACE_FIELDS,
        body: {
          includedTypes: categories,
          maxResultCount: 5,
          rankPreference: "POPULARITY",
          locationRestriction: {circle: {center: location, radius}},
        },
      },
    );
    return arrayProperty(response, "places").filter(isObject);
  }

  async airQualityCurrent(input: AirQualityInput): Promise<Record<string, unknown>> {
    return this.requestJson(
      "airQualityCurrent",
      `${AIR_QUALITY_BASE}/currentConditions:lookup`,
      {
        method: "POST",
        query: {
          fields: AIR_QUALITY_CURRENT_FIELDS,
        },
        body: {
          location: coordinate(input),
          universalAqi: true,
          extraComputations: ["HEALTH_RECOMMENDATIONS"],
        },
      },
    );
  }

  async airQualityForecast(input: AirQualityInput): Promise<Record<string, unknown>> {
    const start = new Date(this.now().getTime() + 60 * 60 * 1_000);
    start.setUTCMinutes(0, 0, 0);
    const end = new Date(start.getTime() + input.forecastHours * 60 * 60 * 1_000);
    return this.requestJson(
      "airQualityForecast",
      `${AIR_QUALITY_BASE}/forecast:lookup`,
      {
        method: "POST",
        query: {
          fields: AIR_QUALITY_FORECAST_FIELDS,
        },
        body: {
          location: coordinate(input),
          period: {startTime: start.toISOString(), endTime: end.toISOString()},
          pageSize: input.forecastHours,
          universalAqi: true,
        },
      },
    );
  }

  async pollen(input: PollenInput): Promise<Record<string, unknown>> {
    return this.requestJson("pollen", `${POLLEN_BASE}/forecast:lookup`, {
      query: {
        "location.latitude": String(input.latitude),
        "location.longitude": String(input.longitude),
        days: String(input.days),
        plantsDescription: "false",
        fields: POLLEN_FIELDS,
      },
    });
  }

  async resolveAddress(
    input: SolarCheckInput,
  ): Promise<{location: Coordinate; formattedAddress?: string} | null> {
    const response = await this.requestJson(
      "solarAddressLookup",
      `${PLACES_BASE}/places:searchText`,
      {
        method: "POST",
        fieldMask: "places.location,places.formattedAddress",
        body: {textQuery: input.address, pageSize: 1},
      },
    );
    const first = arrayProperty(response, "places")[0];
    if (!isObject(first) || !isObject(first.location)) return null;
    const latitude = first.location.latitude;
    const longitude = first.location.longitude;
    if (typeof latitude !== "number" || typeof longitude !== "number") return null;
    return {
      location: {latitude, longitude},
      ...(typeof first.formattedAddress === "string"
        ? {formattedAddress: first.formattedAddress}
        : {}),
    };
  }

  async solarBuildingInsights(
    location: Coordinate,
  ): Promise<Record<string, unknown>> {
    return this.requestJson(
      "solarBuildingInsights",
      `${SOLAR_BASE}/buildingInsights:findClosest`,
      {
        query: {
          "location.latitude": String(location.latitude),
          "location.longitude": String(location.longitude),
          requiredQuality: "LOW",
          fields: [
            "name",
            "center",
            "imageryDate",
            "imageryQuality",
            "solarPotential(maxArrayPanelsCount,maxSunshineHoursPerYear,carbonOffsetFactorKgPerMwh)",
          ].join(","),
        },
      },
    );
  }

  async autocomplete(input: AutocompleteInput): Promise<Record<string, unknown>> {
    const locationBias =
      input.latitude === undefined
        ? undefined
        : {
            circle: {
              center: {
                latitude: input.latitude,
                longitude: input.longitude!,
              },
              radius: input.radius ?? 10_000,
            },
          };
    const response = await this.requestJson(
      "autocomplete",
      `${PLACES_BASE}/places:autocomplete`,
      {
        method: "POST",
        fieldMask: [
          "suggestions.placePrediction.placeId",
          "suggestions.placePrediction.text.text",
          "suggestions.placePrediction.structuredFormat.mainText.text",
          "suggestions.placePrediction.structuredFormat.secondaryText.text",
          "suggestions.placePrediction.types",
        ].join(","),
        body: {
          input: input.text,
          sessionToken: input.sessionToken,
          includeQueryPredictions: false,
          ...(locationBias === undefined ? {} : {locationBias}),
        },
      },
    );
    return {suggestions: arrayProperty(response, "suggestions")};
  }

  async fetchPlacePhoto(
    photoName: string,
    maxWidthPx: number,
  ): Promise<PhotoBytes> {
    const metadata = await this.requestJson(
      "placePhotoMetadata",
      `${PLACES_BASE}/${photoName}/media`,
      {
        query: {maxWidthPx: String(maxWidthPx), skipHttpRedirect: "true"},
      },
    );
    const photoUri = stringProperty(metadata, "photoUri");
    if (photoUri === undefined || !isAllowedPhotoUri(photoUri)) {
      throw new BackendError("unavailable", "The place photo is unavailable.");
    }
    const response = await this.fetchResponse("placePhotoBytes", photoUri, {
      method: "GET",
      headers: {Accept: "image/*"},
      redirect: "error",
    });
    const contentType = response.headers.get("content-type")?.split(";")[0] ?? "";
    const allowedContentTypes = new Set([
      "image/jpeg",
      "image/png",
      "image/webp",
      "image/gif",
    ]);
    if (!allowedContentTypes.has(contentType.toLowerCase())) {
      throw new BackendError("unavailable", "The place photo is unavailable.");
    }
    const declaredLength = Number(response.headers.get("content-length") ?? 0);
    if (declaredLength > MAX_PHOTO_BYTES) {
      throw new BackendError("resource-exhausted", "The place photo is too large.");
    }
    const bytes = new Uint8Array(await response.arrayBuffer());
    if (bytes.byteLength > MAX_PHOTO_BYTES) {
      throw new BackendError("resource-exhausted", "The place photo is too large.");
    }
    return {bytes, contentType};
  }

  private async textSearch(
    input: SearchPlacesInput,
  ): Promise<Record<string, unknown>> {
    const textQuery =
      input.query ?? input.category?.replaceAll("_", " ") ?? modeSearchTerm(input.modeId);
    return this.requestJson("placesTextSearch", `${PLACES_BASE}/places:searchText`, {
      method: "POST",
      fieldMask: PLACE_SEARCH_FIELDS,
      body: {
        textQuery,
        pageSize: input.maxResults,
        openNow: input.openNow,
        ...(input.category === undefined
          ? {}
          : {includedType: input.category}),
        locationBias: {
          circle: {
            center: coordinate(input),
            radius: input.radius,
          },
        },
      },
    });
  }

  private async nearbySearch(
    input: SearchPlacesInput,
  ): Promise<Record<string, unknown>> {
    const category = input.category ?? modePlaceType(input.modeId);
    return this.requestJson(
      "placesNearbySearch",
      `${PLACES_BASE}/places:searchNearby`,
      {
        method: "POST",
        fieldMask: PLACE_SEARCH_FIELDS,
        body: {
          ...(category === undefined ? {} : {includedTypes: [category]}),
          maxResultCount: input.maxResults,
          rankPreference: "POPULARITY",
          locationRestriction: {
            circle: {center: coordinate(input), radius: input.radius},
          },
        },
      },
    );
  }

  private async requestJson(
    operation: string,
    endpoint: string,
    options: {
      method?: "GET" | "POST";
      body?: Record<string, unknown>;
      fieldMask?: string;
      query?: Record<string, string>;
    },
  ): Promise<Record<string, unknown>> {
    const headers: Record<string, string> = {
      "X-Goog-Api-Key": this.apiKey,
      Accept: "application/json",
    };
    if (options.body !== undefined) headers["Content-Type"] = "application/json";
    if (options.fieldMask !== undefined) {
      headers["X-Goog-FieldMask"] = options.fieldMask;
    }
    const response = await this.fetchResponse(
      operation,
      endpoint,
      {
        method: options.method ?? "GET",
        headers,
        ...(options.body === undefined
          ? {}
          : {body: JSON.stringify(options.body)}),
      },
      options.query,
    );
    const text = await response.text();
    if (text.length === 0) return {};
    try {
      const parsed: unknown = JSON.parse(text);
      if (!isObject(parsed)) {
        throw new Error("Response was not an object.");
      }
      return parsed;
    } catch {
      throw new BackendError(
        "unavailable",
        "The map service returned an invalid response.",
        {operation},
      );
    }
  }

  private async fetchResponse(
    operation: string,
    endpoint: string,
    init: RequestInit,
    query?: Record<string, string>,
  ): Promise<Response> {
    const url = new URL(endpoint);
    for (const [key, value] of Object.entries(query ?? {})) {
      url.searchParams.set(key, value);
    }

    for (let attempt = 1; attempt <= this.maxAttempts; attempt += 1) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), this.timeoutMs);
      try {
        const response = await this.fetchImpl(url, {
          ...init,
          signal: controller.signal,
        });
        if (response.ok) return response;
        const retryable = RETRYABLE_STATUSES.has(response.status);
        if (!retryable || attempt === this.maxAttempts) {
          await discardResponse(response);
          throw new GoogleApiError(operation, response.status, retryable);
        }
        await discardResponse(response);
      } catch (error) {
        if (error instanceof GoogleApiError) throw error;
        if (attempt === this.maxAttempts) {
          throw new BackendError(
            "unavailable",
            "The map service is temporarily unavailable.",
            {operation},
          );
        }
      } finally {
        clearTimeout(timer);
      }
      await this.sleep(this.retryDelayMs * attempt);
    }
    throw new BackendError("internal", "The map request could not be completed.");
  }
}

function routeWaypoint(value: WaypointInput): Record<string, unknown> {
  return typeof value === "string"
    ? {address: value}
    : {location: {latLng: value}};
}

function coordinate(value: Coordinate): Coordinate {
  return {latitude: value.latitude, longitude: value.longitude};
}

function modeSearchTerm(modeId: string): string {
  const terms: Record<string, string> = {
    "open-now": "places open now",
    "patio-finder": "patio restaurants",
    "road-rescue": "roadside services",
    "rainy-day-ideas": "indoor activities",
    "weekend-plan": "things to do",
  };
  return terms[modeId] ?? modeId.replaceAll("-", " ");
}

function modePlaceType(modeId: string): string | undefined {
  const types: Record<string, string> = {
    "food-wheel": "restaurant",
    "patio-finder": "restaurant",
    "food-challenge": "restaurant",
    "dog-friendly-spots": "dog_park",
    "ev-charge-chill": "electric_vehicle_charging_station",
    "road-rescue": "car_repair",
  };
  return types[modeId];
}

function arrayProperty(value: Record<string, unknown>, key: string): unknown[] {
  const property = value[key];
  return Array.isArray(property) ? property : [];
}

function stringProperty(
  value: Record<string, unknown>,
  key: string,
): string | undefined {
  return typeof value[key] === "string" ? value[key] : undefined;
}

function isObject(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

async function discardResponse(response: Response): Promise<void> {
  try {
    await response.arrayBuffer();
  } catch {
    // Intentionally discard untrusted upstream error bodies.
  }
}

function isAllowedPhotoUri(value: string): boolean {
  try {
    const url = new URL(value);
    return (
      url.protocol === "https:" &&
      (url.hostname === "googleusercontent.com" ||
        url.hostname.endsWith(".googleusercontent.com"))
    );
  } catch {
    return false;
  }
}
