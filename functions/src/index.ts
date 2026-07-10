import {logger} from "firebase-functions";
import {defineBoolean, defineSecret} from "firebase-functions/params";
import {setGlobalOptions} from "firebase-functions/v2";
import {
  CallableRequest,
  HttpsError,
  onCall,
  onRequest,
} from "firebase-functions/v2/https";
import {createBackend} from "./backend";
import {BackendError} from "./errors";
import {GoogleApiClient} from "./googleApiClient";
import {appendSignedPhotoQuery, verifyPhotoToken} from "./photoToken";
import {photoProxyBaseUrl} from "./proxyUrl";
import {validatePlacePhoto} from "./validation";

const googleMapsApiKey = defineSecret("GOMODE_GOOGLE_MAPS_API_KEY");
const photoProxySigningKey = defineSecret("GOMODE_PHOTO_PROXY_SIGNING_KEY");
const enableSolarApi = defineBoolean("ENABLE_SOLAR_API", {default: false});
const enableAirQualityForecast = defineBoolean(
  "ENABLE_AIR_QUALITY_FORECAST",
  {default: false},
);

setGlobalOptions({
  region: "us-central1",
  memory: "256MiB",
  timeoutSeconds: 15,
  minInstances: 0,
  maxInstances: 3,
  concurrency: 10,
});

const callableOptions = {
  enforceAppCheck: true,
  secrets: [googleMapsApiKey],
};

export const searchPlaces = onCall(callableOptions, (request) =>
  runCallable("searchPlaces", request, (backend, data) =>
    backend.searchPlaces(data),
  ),
);

export const placeDetails = onCall(callableOptions, (request) =>
  runCallable("placeDetails", request, (backend, data) =>
    backend.placeDetails(data),
  ),
);

export const computeRoute = onCall(callableOptions, (request) =>
  runCallable("computeRoute", request, (backend, data) =>
    backend.computeRoute(data),
  ),
);

export const roadTripStops = onCall(
  {...callableOptions, concurrency: 2, timeoutSeconds: 30},
  (request) =>
    runCallable("roadTripStops", request, (backend, data) =>
      backend.roadTripStops(data),
    ),
);

export const airQuality = onCall(
  {...callableOptions, timeoutSeconds: 30},
  (request) =>
    runCallable("airQuality", request, (backend, data) =>
      backend.airQuality(data),
    ),
);

export const pollen = onCall(callableOptions, (request) =>
  runCallable("pollen", request, (backend, data) => backend.pollen(data)),
);

export const solarCheck = onCall(
  {...callableOptions, timeoutSeconds: 30},
  (request) =>
    runCallable("solarCheck", request, (backend, data) =>
      backend.solarCheck(data),
    ),
);

export const autocomplete = onCall(callableOptions, (request) =>
  runCallable("autocomplete", request, (backend, data) =>
    backend.autocomplete(data),
  ),
);

export const placePhoto = onCall(
  {enforceAppCheck: true, secrets: [photoProxySigningKey]},
  async (request) => {
    try {
      const input = validatePlacePhoto(request.data);
      const expires = Math.floor(Date.now() / 1_000) + 300;
      const proxyUrl = photoProxyBaseUrl(request.rawRequest);
      return {
        url: appendSignedPhotoQuery(
          proxyUrl,
          {...input, expires},
          photoProxySigningKey.value(),
        ),
        expiresAt: new Date(expires * 1_000).toISOString(),
      };
    } catch (error) {
      throw callableError("placePhoto", error);
    }
  },
);

export const placePhotoProxy = onRequest(
  {
    secrets: [googleMapsApiKey, photoProxySigningKey],
    timeoutSeconds: 30,
    concurrency: 10,
  },
  async (request, response) => {
    response.set("Access-Control-Allow-Origin", "*");
    response.set("X-Content-Type-Options", "nosniff");
    if (request.method !== "GET") {
      response.set("Allow", "GET").status(405).json({error: "method_not_allowed"});
      return;
    }
    try {
      const input = validatePlacePhoto({
        photoName: queryString(request.query.photoName),
        maxWidthPx: queryInteger(request.query.maxWidthPx),
      });
      const expires = queryInteger(request.query.expires);
      const signature = queryString(request.query.signature);
      verifyPhotoToken(
        {...input, expires},
        signature,
        photoProxySigningKey.value(),
      );
      const photo = await new GoogleApiClient(googleMapsApiKey.value(), {
        timeoutMs: 6_000,
      }).fetchPlacePhoto(input.photoName, input.maxWidthPx);
      const remainingSeconds = Math.max(
        0,
        expires - Math.floor(Date.now() / 1_000),
      );
      response.set("Cache-Control", `private, max-age=${remainingSeconds}`);
      response.set("Content-Type", photo.contentType);
      response.status(200).send(Buffer.from(photo.bytes));
    } catch (error) {
      const status =
        error instanceof BackendError && error.code === "invalid-argument"
          ? 400
          : error instanceof BackendError && error.code === "resource-exhausted"
            ? 413
            : 502;
      logSanitizedError("placePhotoProxy", error);
      response.status(status).json({error: "photo_unavailable"});
    }
  },
);

async function runCallable(
  operation: string,
  request: CallableRequest<unknown>,
  handler: (
    backend: ReturnType<typeof createBackend>,
    data: unknown,
  ) => Promise<Record<string, unknown>>,
): Promise<Record<string, unknown>> {
  try {
    const client = new GoogleApiClient(googleMapsApiKey.value(), {
      timeoutMs: 6_000,
    });
    const backend = createBackend(client, {
      airQualityForecastEnabled: enableAirQualityForecast.value(),
      solarEnabled: enableSolarApi.value(),
    });
    return await handler(backend, request.data);
  } catch (error) {
    throw callableError(operation, error);
  }
}

function callableError(operation: string, error: unknown): HttpsError {
  logSanitizedError(operation, error);
  if (error instanceof BackendError) {
    return new HttpsError(error.code, error.message, error.details);
  }
  return new HttpsError("internal", "The request could not be completed.");
}

function logSanitizedError(operation: string, error: unknown): void {
  if (error instanceof BackendError) {
    logger.warn("Backend request failed", {
      operation,
      code: error.code,
      ...(error.details?.upstreamStatus === undefined
        ? {}
        : {upstreamStatus: error.details.upstreamStatus}),
    });
  } else {
    logger.error("Unexpected backend request failure", {
      operation,
      errorType:
        error !== null && typeof error === "object"
          ? error.constructor.name
          : typeof error,
    });
  }
}

function queryString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function queryInteger(value: unknown): number {
  if (typeof value !== "string" || !/^\d+$/.test(value)) return Number.NaN;
  return Number(value);
}
