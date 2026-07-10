import {invalidArgument} from "./errors";
import {
  AirQualityInput,
  AutocompleteInput,
  ComputeRouteInput,
  Coordinate,
  PlaceDetailsInput,
  PlacePhotoInput,
  PollenInput,
  RoadTripStopsInput,
  SearchPlacesInput,
  SolarCheckInput,
  TravelMode,
  WaypointInput,
} from "./types";

type UnknownObject = Record<string, unknown>;

const CATEGORY_PATTERN = /^[a-z][a-z0-9_]{1,63}$/;
const MODE_ID_PATTERN = /^[a-z0-9][a-z0-9-]{0,63}$/;
const SESSION_TOKEN_PATTERN = /^[A-Za-z0-9._~-]{1,128}$/;
const PHOTO_NAME_PATTERN = /^places\/[^/?#]+\/photos\/[^/?#]+$/;

// Every value is from Places API (New) Table A, verified 2026-07-10.
// Keep this allowlist intentionally narrower than Google's full catalog so a
// compromised client cannot turn the callable into an arbitrary type proxy.
const SUPPORTED_PLACE_TYPES = new Set([
  "amusement_center",
  "bar",
  "bowling_alley",
  "cafe",
  "car_repair",
  "coffee_shop",
  "dessert_shop",
  "dog_park",
  "electric_vehicle_charging_station",
  "gas_station",
  "indoor_playground",
  "library",
  "museum",
  "park",
  "pharmacy",
  "public_bathroom",
  "restaurant",
  "rest_stop",
  "scenic_spot",
  "tourist_attraction",
  "video_arcade",
]);

export function validateSearchPlaces(data: unknown): SearchPlacesInput {
  const value = objectValue(data);
  assertAllowedKeys(value, [
    "latitude",
    "longitude",
    "modeId",
    "query",
    "category",
    "radius",
    "openNow",
    "maxResults",
  ]);
  const query = optionalString(value, "query", 120);
  const category = optionalPatternString(
    value,
    "category",
    CATEGORY_PATTERN,
    "a supported Places type such as restaurant or gas_station",
  );
  if (category !== undefined && !SUPPORTED_PLACE_TYPES.has(category)) {
    throw invalidArgument("category is not enabled for this app.", "category");
  }
  return {
    ...coordinateFrom(value),
    modeId: patternString(
      value,
      "modeId",
      MODE_ID_PATTERN,
      "a lowercase mode identifier",
    ),
    ...(query === undefined ? {} : {query}),
    ...(category === undefined ? {} : {category}),
    radius: requiredNumber(value, "radius", 50, 50_000),
    openNow: optionalBoolean(value, "openNow", false),
    maxResults: optionalInteger(value, "maxResults", 10, 1, 20),
  };
}

export function validatePlaceDetails(data: unknown): PlaceDetailsInput {
  const value = objectValue(data);
  assertAllowedKeys(value, ["placeId", "sessionToken"]);
  const sessionToken = optionalPatternString(
    value,
    "sessionToken",
    SESSION_TOKEN_PATTERN,
    "a 1-128 character URL-safe token",
  );
  return {
    placeId: requiredString(value, "placeId", 256),
    ...(sessionToken === undefined ? {} : {sessionToken}),
  };
}

export function validatePlacePhoto(data: unknown): PlacePhotoInput {
  const value = objectValue(data);
  assertAllowedKeys(value, ["photoName", "maxWidthPx"]);
  return {
    photoName: patternString(
      value,
      "photoName",
      PHOTO_NAME_PATTERN,
      "a Places photo resource name",
    ),
    maxWidthPx: optionalInteger(value, "maxWidthPx", 800, 64, 1_200),
  };
}

export function validateComputeRoute(data: unknown): ComputeRouteInput {
  const value = objectValue(data);
  assertAllowedKeys(value, ["origin", "destination", "travelMode"]);
  return {
    origin: waypoint(value.origin, "origin"),
    destination: waypoint(value.destination, "destination"),
    travelMode: travelMode(value.travelMode),
  };
}

export function validateRoadTripStops(data: unknown): RoadTripStopsInput {
  const value = objectValue(data);
  assertAllowedKeys(value, ["origin", "destination", "categories"]);
  const rawCategories = value.categories;
  if (!Array.isArray(rawCategories) || rawCategories.length < 1) {
    throw invalidArgument("categories must contain at least one Places type.", "categories");
  }
  if (rawCategories.length > 3) {
    throw invalidArgument("categories accepts at most 3 values.", "categories");
  }
  const categories = rawCategories.map((entry, index) => {
    if (
      typeof entry !== "string" ||
      !CATEGORY_PATTERN.test(entry) ||
      !SUPPORTED_PLACE_TYPES.has(entry)
    ) {
      throw invalidArgument(
        `categories[${index}] must be a supported lowercase Places type.`,
        "categories",
      );
    }
    return entry;
  });
  return {
    origin: waypoint(value.origin, "origin"),
    destination: waypoint(value.destination, "destination"),
    categories: [...new Set(categories)],
  };
}

export function validateAirQuality(data: unknown): AirQualityInput {
  const value = objectValue(data);
  assertAllowedKeys(value, [
    "latitude",
    "longitude",
    "includeForecast",
    "forecastHours",
  ]);
  return {
    ...coordinateFrom(value),
    includeForecast: optionalBoolean(value, "includeForecast", false),
    forecastHours: optionalInteger(value, "forecastHours", 6, 1, 24),
  };
}

export function validatePollen(data: unknown): PollenInput {
  const value = objectValue(data);
  assertAllowedKeys(value, ["latitude", "longitude", "days"]);
  return {
    ...coordinateFrom(value),
    days: optionalInteger(value, "days", 3, 1, 5),
  };
}

export function validateSolarCheck(data: unknown): SolarCheckInput {
  const value = objectValue(data);
  assertAllowedKeys(value, ["address"]);
  return {address: requiredString(value, "address", 200, 3)};
}

export function validateAutocomplete(data: unknown): AutocompleteInput {
  const value = objectValue(data);
  assertAllowedKeys(value, [
    "text",
    "sessionToken",
    "latitude",
    "longitude",
    "radius",
  ]);
  const latitude = optionalNumber(value, "latitude", -90, 90);
  const longitude = optionalNumber(value, "longitude", -180, 180);
  if ((latitude === undefined) !== (longitude === undefined)) {
    throw invalidArgument(
      "latitude and longitude must be provided together.",
      "latitude",
    );
  }
  const radius = optionalNumber(value, "radius", 50, 50_000);
  if (radius !== undefined && latitude === undefined) {
    throw invalidArgument("radius requires latitude and longitude.", "radius");
  }
  return {
    text: requiredString(value, "text", 200),
    sessionToken: patternString(
      value,
      "sessionToken",
      SESSION_TOKEN_PATTERN,
      "a 1-128 character URL-safe token",
    ),
    ...(latitude === undefined ? {} : {latitude, longitude: longitude!}),
    ...(radius === undefined ? {} : {radius}),
  };
}

function objectValue(value: unknown): UnknownObject {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw invalidArgument("Request data must be a JSON object.");
  }
  return value as UnknownObject;
}

function assertAllowedKeys(value: UnknownObject, allowed: string[]): void {
  const allowedSet = new Set(allowed);
  const unexpected = Object.keys(value).find((key) => !allowedSet.has(key));
  if (unexpected !== undefined) {
    throw invalidArgument(`Unexpected request field: ${unexpected}.`, unexpected);
  }
}

function coordinateFrom(value: UnknownObject): Coordinate {
  return {
    latitude: requiredNumber(value, "latitude", -90, 90),
    longitude: requiredNumber(value, "longitude", -180, 180),
  };
}

function waypoint(value: unknown, field: string): WaypointInput {
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (trimmed.length < 2 || trimmed.length > 200) {
      throw invalidArgument(`${field} must be 2-200 characters.`, field);
    }
    return trimmed;
  }
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw invalidArgument(
      `${field} must be an address or latitude/longitude object.`,
      field,
    );
  }
  return coordinateFrom(value as UnknownObject);
}

function travelMode(value: unknown): TravelMode {
  if (typeof value !== "string") {
    throw invalidArgument("travelMode is required.", "travelMode");
  }
  const normalized = value.trim().toUpperCase().replace(/-/g, "_");
  const allowed: TravelMode[] = [
    "DRIVE",
    "WALK",
    "BICYCLE",
    "TRANSIT",
    "TWO_WHEELER",
  ];
  if (!allowed.includes(normalized as TravelMode)) {
    throw invalidArgument(
      `travelMode must be one of ${allowed.join(", ")}.`,
      "travelMode",
    );
  }
  return normalized as TravelMode;
}

function requiredString(
  value: UnknownObject,
  field: string,
  maxLength: number,
  minLength = 1,
): string {
  const raw = value[field];
  if (typeof raw !== "string") {
    throw invalidArgument(`${field} is required.`, field);
  }
  const trimmed = raw.trim();
  if (trimmed.length < minLength || trimmed.length > maxLength) {
    throw invalidArgument(
      `${field} must be ${minLength}-${maxLength} characters.`,
      field,
    );
  }
  return trimmed;
}

function optionalString(
  value: UnknownObject,
  field: string,
  maxLength: number,
): string | undefined {
  const raw = value[field];
  if (raw === undefined || raw === null || raw === "") return undefined;
  return requiredString(value, field, maxLength);
}

function patternString(
  value: UnknownObject,
  field: string,
  pattern: RegExp,
  description: string,
): string {
  const result = requiredString(value, field, 512);
  if (!pattern.test(result)) {
    throw invalidArgument(`${field} must be ${description}.`, field);
  }
  return result;
}

function optionalPatternString(
  value: UnknownObject,
  field: string,
  pattern: RegExp,
  description: string,
): string | undefined {
  if (value[field] === undefined || value[field] === null || value[field] === "") {
    return undefined;
  }
  return patternString(value, field, pattern, description);
}

function requiredNumber(
  value: UnknownObject,
  field: string,
  minimum: number,
  maximum: number,
): number {
  const raw = value[field];
  if (typeof raw !== "number" || !Number.isFinite(raw)) {
    throw invalidArgument(`${field} must be a finite number.`, field);
  }
  if (raw < minimum || raw > maximum) {
    throw invalidArgument(
      `${field} must be between ${minimum} and ${maximum}.`,
      field,
    );
  }
  return raw;
}

function optionalNumber(
  value: UnknownObject,
  field: string,
  minimum: number,
  maximum: number,
): number | undefined {
  if (value[field] === undefined || value[field] === null) return undefined;
  return requiredNumber(value, field, minimum, maximum);
}

function optionalInteger(
  value: UnknownObject,
  field: string,
  fallback: number,
  minimum: number,
  maximum: number,
): number {
  if (value[field] === undefined || value[field] === null) return fallback;
  const result = requiredNumber(value, field, minimum, maximum);
  if (!Number.isInteger(result)) {
    throw invalidArgument(`${field} must be an integer.`, field);
  }
  return result;
}

function optionalBoolean(
  value: UnknownObject,
  field: string,
  fallback: boolean,
): boolean {
  const raw = value[field];
  if (raw === undefined || raw === null) return fallback;
  if (typeof raw !== "boolean") {
    throw invalidArgument(`${field} must be true or false.`, field);
  }
  return raw;
}
