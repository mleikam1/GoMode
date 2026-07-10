# Secure Backend API Contract

This document describes the GoMode backend contract consumed by Flutter. The client receives only the fixed, bounded fields described here; some nested names intentionally mirror the selected Google response fields so the typed client can parse them without a second lossy transformation.

## Transport and Trust Boundary

Production operations are Firebase Functions v2 callables in `us-central1`. Flutter invokes them with the Firebase Functions SDK, which sends the input as callable `data` and unwraps the returned `result.data`. App Check is enforced on every callable before its handler runs.

The Flutter HTTP transport is for a compatible local proxy or emulator only. It is not permission to call the deployed callable URL as an ordinary unauthenticated JSON endpoint.

Common rules:

- Request and response bodies are JSON-compatible objects.
- Latitude is `-90...90`; longitude is `-180...180`.
- Missing, unknown, or invalid fields produce a callable `invalid-argument` error.
- Google credentials, Google key-bearing URLs, upstream error bodies, and internal stack traces are never returned.
- Optional values can be omitted. The client must not infer `false` from a missing opening, rating, environmental, or Solar field.
- All timestamps are UTC ISO 8601 strings. Route durations are rounded integer seconds in the bounded response.
- Autocomplete session tokens are URL-safe strings and must not be logged.

## Timeouts and Retries

- Normal callables have a 15-second Function timeout; `roadTripStops`, `airQuality`, and `solarCheck` have 30 seconds. Flutter uses matching per-function callable timeouts.
- Each individual Google request has a six-second timeout and at most two attempts. Only network failures and HTTP 408, 429, 500, 502, 503, or 504 are retried, with a short increasing delay.
- Flutter retries a callable once only for timeout, rate-limit, or unavailable failures. It does not retry validation, App Check/permission, or not-found failures.
- `autocomplete` disables client retry so one keystroke cannot multiply billable prediction requests. UI code should debounce and cancel stale work.
- The optional local HTTP transport uses the same per-function timeout and retries transient transport failures only. It is not the production transport.

These bounds intentionally avoid unbounded retry amplification. A transient failure can still create more than one upstream request, so quotas and the runtime concurrency limits remain required.

## Common Objects

### Coordinate

```json
{
  "latitude": 30.2672,
  "longitude": -97.7431
}
```

### Waypoint

A route waypoint is either a 2-200 character address string or a `Coordinate` object. The backend does not accept an arbitrary URL or an upstream Google request object.

### Place

Operations return the applicable subset of this object:

```json
{
  "id": "place-id",
  "displayName": {"text": "Example Place"},
  "formattedAddress": "123 Example St, Austin, TX",
  "location": {"latitude": 30.2672, "longitude": -97.7431},
  "primaryType": "restaurant",
  "types": ["restaurant", "food"],
  "rating": 4.6,
  "userRatingCount": 120,
  "currentOpeningHours": {"openNow": true},
  "photos": [
    {
      "name": "places/place-id/photos/photo-id",
      "authorAttributions": [
        {
          "displayName": "Photo contributor",
          "uri": "https://...",
          "photoUri": "https://..."
        }
      ]
    }
  ],
  "googleMapsUri": "https://maps.google.com/..."
}
```

Only fields included by the operation's fixed Google field mask can appear. In particular, `openNow` can be absent when Google has no current-hours data; it must not be treated as closed.

## `searchPlaces`

Searches Places API (New). A free-text `query` uses Text Search. A supported `category` uses Nearby Search unless Text Search is required for the requested behavior. The server, not Flutter, chooses the Google operation and field mask.

Input:

| Field | Type | Required | Validation/default |
| --- | --- | --- | --- |
| `latitude` | number | Yes | `-90...90` |
| `longitude` | number | Yes | `-180...180` |
| `modeId` | string | Yes | lowercase letters, digits, hyphens; max 64 |
| `query` | string | No | trimmed; max 120 |
| `category` | string | No | lowercase Google type form; max 64 |
| `radius` | number | Yes | 50-50,000 metres |
| `openNow` | boolean | No | default `false` |
| `maxResults` | integer | No | 1-20; default 10 |

Response:

```json
{
  "places": [
    {
      "id": "place-id",
      "displayName": {"text": "Example Place"},
      "formattedAddress": "123 Example St, Austin, TX",
      "location": {"latitude": 30.2672, "longitude": -97.7431},
      "primaryType": "restaurant",
      "types": ["restaurant"],
      "photos": [
        {
          "name": "places/place-id/photos/photo-id",
          "authorAttributions": [
            {
              "displayName": "Photo contributor",
              "uri": "https://...",
              "photoUri": "https://..."
            }
          ]
        }
      ]
    }
  ]
}
```

`maxResults` maps to the appropriate Google request field and is also enforced on the bounded response. Search fields are limited to identity, name, address, coordinates, type, and photo metadata. `openNow: true` filters Text Search results but does not add current-hours data to this response. Semantic concepts that are not valid Places types must be sent as text, not as an invented category.

## `placeDetails`

Input:

| Field | Type | Required | Validation |
| --- | --- | --- | --- |
| `placeId` | string | Yes | trimmed; max 256 |
| `sessionToken` | string | No | URL-safe; 1-128 characters |

Response:

```json
{
  "place": {
    "id": "place-id",
    "displayName": {"text": "Example Place"},
    "formattedAddress": "123 Example St, Austin, TX",
    "location": {"latitude": 30.2672, "longitude": -97.7431},
    "primaryType": "restaurant",
    "types": ["restaurant"],
    "rating": 4.6,
    "userRatingCount": 120,
    "currentOpeningHours": {"openNow": true},
    "photos": [
      {
        "name": "places/place-id/photos/photo-id",
        "authorAttributions": [
          {
            "displayName": "Photo contributor",
            "uri": "https://...",
            "photoUri": "https://..."
          }
        ]
      }
    ],
    "googleMapsUri": "https://maps.google.com/..."
  }
}
```

Pass the same `sessionToken` used for the selected autocomplete prediction, then discard the token. This terminates the Places autocomplete session correctly.

## `placePhoto`

This callable does not return a Google URL containing the API key. It mints a five-minute signed URL for `placePhotoProxy`.

Input:

| Field | Type | Required | Validation/default |
| --- | --- | --- | --- |
| `photoName` | string | Yes | exactly `places/{place}/photos/{photo}`; no query or fragment |
| `maxWidthPx` | integer | No | 64-1,200; default 800 |

Response:

```json
{
  "url": "https://.../placePhotoProxy?...",
  "expiresAt": "2026-07-10T15:05:00.000Z"
}
```

The URL is a temporary bearer capability. Clients must not persist it or add it to analytics. Request a new URL after expiry.

The `authorAttributions` returned with the source photo metadata must be retained with the photo and displayed whenever the live photo is shown. Proxying the image does not remove Google Places attribution requirements.

### `placePhotoProxy`

`placePhotoProxy` is the sole non-callable HTTPS surface. `placePhoto` generates this shape:

```text
GET /placePhotoProxy?photoName=...&maxWidthPx=...&expires=...&signature=...
```

`expires` is Unix time in seconds. `signature` is a base64url HMAC-SHA256 over the canonical photo name, width, and expiry. Clients must treat the complete query and signature construction as opaque and must never attempt to mint or modify it.

The proxy verifies the signature and five-minute expiry before any upstream request, permits only the signed 64-1,200 pixel width, asks Google for a non-redirecting photo URI, requires an HTTPS `googleusercontent.com` host, refuses further redirects, and allows only JPEG, PNG, WebP, or GIF up to 6 MiB. Successful images use a private cache lifetime no longer than the signed URL's remaining lifetime, `X-Content-Type-Options: nosniff`, and a wildcard CORS response so the signed image can render on supported clients; the unguessable short-lived signature remains the authorization control. Non-GET requests return 405; invalid or expired tokens return 400, oversized photos return 413, and other photo failures return a sanitized 502 without Google credentials.

## `computeRoute`

Input:

| Field | Type | Required | Validation |
| --- | --- | --- | --- |
| `origin` | Waypoint | Yes | address or coordinate |
| `destination` | Waypoint | Yes | address or coordinate |
| `travelMode` | string | Yes | `DRIVE`, `WALK`, `BICYCLE`, `TRANSIT`, or `TWO_WHEELER` |

Response:

```json
{
  "route": {
    "distanceMeters": 131970,
    "durationSeconds": 4980,
    "encodedPolyline": "encoded-polyline"
  }
}
```

The Google Routes request uses a fixed field mask for distance, duration, and encoded polyline. Alternative routes are disabled. The backend selects the primary route, rounds Google's duration to integer seconds, and omits `encodedPolyline` if Google did not return one.

## `roadTripStops`

Input:

| Field | Type | Required | Validation |
| --- | --- | --- | --- |
| `origin` | Waypoint | Yes | address or coordinate |
| `destination` | Waypoint | Yes | address or coordinate |
| `categories` | string array | Yes | 1-3 unique lowercase Google type values |

Response:

```json
{
  "route": {
    "distanceMeters": 131970,
    "durationSeconds": 4980,
    "encodedPolyline": "encoded-polyline"
  },
  "stops": [
    {
      "id": "place-id",
      "displayName": {"text": "Example Stop"},
      "formattedAddress": "Along the route",
      "location": {"latitude": 30.5, "longitude": -97.8},
      "primaryType": "gas_station",
      "types": ["gas_station"]
    }
  ],
  "strategy": "route_polyline_midpoints"
}
```

The current strategy is best-effort bounded distance sampling along the returned route, followed by Nearby searches and place-ID deduplication. `strategy` is `route_polyline_midpoints`, `coordinate_interpolation` when only coordinate endpoints can be interpolated, or `route_geometry_unavailable` when no search points can be derived. It uses at most three quartile sample points, three categories, five results per point, and 15 deduplicated stops. Partial sample failures are tolerated unless every search fails. Function concurrency is 2 rather than the global 10. A result means near a route sample; the response does not claim an exact detour time.

## `airQuality`

Input:

| Field | Type | Required | Validation/default |
| --- | --- | --- | --- |
| `latitude` | number | Yes | `-90...90` |
| `longitude` | number | Yes | `-180...180` |
| `includeForecast` | boolean | No | default `false` |
| `forecastHours` | integer | No | 1-24; default 6 |

Response:

```json
{
  "latitude": 30.2672,
  "longitude": -97.7431,
  "current": {
    "dateTime": "2026-07-10T15:00:00Z",
    "aqi": 42,
    "category": "Good",
    "dominantPollutant": "pm25",
    "healthRecommendation": "Enjoy normal activities."
  },
  "forecast": [
    {
      "dateTime": "2026-07-10T16:00:00Z",
      "aqi": 44,
      "category": "Good",
      "dominantPollutant": "pm25"
    }
  ],
  "forecastAvailable": true,
  "forecastStatus": "available"
}
```

Current conditions can be returned independently. The backend prefers Google's Universal AQI entry and returns only the selected index and general-population recommendation. Forecast is queried only when both `includeForecast` and `ENABLE_AIR_QUALITY_FORECAST` are true. Otherwise `forecast` is empty, `forecastAvailable` is false, and `forecastStatus` is `not_requested` or `not_configured`. A handled upstream forecast failure uses `temporarily_unavailable` while preserving current conditions.

## `pollen`

Input:

| Field | Type | Required | Validation/default |
| --- | --- | --- | --- |
| `latitude` | number | Yes | `-90...90` |
| `longitude` | number | Yes | `-180...180` |
| `days` | integer | No | 1-5; default 3 |

Response:

```json
{
  "latitude": 30.2672,
  "longitude": -97.7431,
  "dailyInfo": [
    {
      "date": {"year": 2026, "month": 7, "day": 10},
      "pollenTypeInfo": [
        {
          "code": "GRASS",
          "displayName": "Grass",
          "inSeason": true,
          "indexInfo": {"value": 2, "category": "Low"}
        }
      ]
    }
  ]
}
```

Plant descriptions, health recommendations, index descriptions, colors, and unused index labels are not requested. Missing pollen-type data means unknown, not zero exposure.

## `solarCheck`

Input:

| Field | Type | Required | Validation |
| --- | --- | --- | --- |
| `address` | string | Yes | trimmed; 3-200 characters |

Disabled response:

```json
{
  "available": false,
  "status": "not_configured",
  "address": "123 Example St, Austin, TX",
  "reason": "Solar checks are not enabled for this deployment."
}
```

Available response:

```json
{
  "available": true,
  "status": "available",
  "address": "123 Example St, Austin, TX",
  "location": {"latitude": 30.2672, "longitude": -97.7431},
  "buildingInsights": {
    "solarPotential": {
      "maxArrayPanelsCount": 24,
      "maxSunshineHoursPerYear": 1450.5,
      "carbonOffsetFactorKgPerMwh": 350.0
    }
  }
}
```

Solar API accepts coordinates, not an address. When `ENABLE_SOLAR_API` is true, the backend first resolves the address with a minimal Places Text Search, then requests the nearest low-quality-or-better building insight. Structured statuses are `not_configured`, `address_not_found`, `available`, `no_coverage`, and `upstream_unavailable`. Disabled or unavailable results must not be presented as a roof, production, savings, or installation assessment.

## `autocomplete`

Input:

| Field | Type | Required | Validation/default |
| --- | --- | --- | --- |
| `text` | string | Yes | trimmed; max 200 |
| `sessionToken` | string | Yes | URL-safe; 1-128 characters |
| `latitude` | number | No | must be paired with longitude |
| `longitude` | number | No | must be paired with latitude |
| `radius` | number | No | 50-50,000 metres; requires coordinates |

Response:

```json
{
  "suggestions": [
    {
      "placePrediction": {
        "placeId": "place-id",
        "text": {"text": "Austin, TX, USA"},
        "structuredFormat": {
          "mainText": {"text": "Austin"},
          "secondaryText": {"text": "TX, USA"}
        },
        "types": ["locality"]
      }
    }
  ]
}
```

Flutter should create one session token per autocomplete interaction, debounce input, cancel stale requests, reuse the token across predictions, pass it to `placeDetails` for the selected prediction, and then discard it.

## Errors and Fallback

Handlers convert expected failures to Firebase callable error codes:

| Code | Meaning |
| --- | --- |
| `invalid-argument` | Request validation failed |
| `not-found` | Requested place/photo/coverage result was not found |
| `failed-precondition` | Backend configuration is invalid or Google returned a non-retryable rejection |
| `resource-exhausted` | Google or backend quota/rate limit reached |
| `unavailable` | Retryable Google/network failure |
| `internal` | Sanitized unexpected failure |

App Check rejection occurs before handler logic and is surfaced by Firebase as `unauthenticated` or another verification/authorization failure. Error details may identify a safe field or operation but never contain input payloads, Google bodies, credentials, or stack traces.

Flutter repositories use demo fallback for unconfigured, timeout, rate-limit, unavailable, malformed-response, or unexpected live-service failures and mark returned models with `isDemo` plus a user-facing fallback message where applicable. Invalid requests, App Check/permission failures, and not-found results are surfaced instead of being hidden by demo data. Demo values must not be presented as current ratings, hours, routes, AQI, pollen, or Solar analysis. Tests inject fake clients; CI never calls Google.
