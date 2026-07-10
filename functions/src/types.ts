export type JsonObject = Record<string, unknown>;

export interface Coordinate {
  latitude: number;
  longitude: number;
}

export type WaypointInput = Coordinate | string;

export interface SearchPlacesInput extends Coordinate {
  modeId: string;
  query?: string;
  category?: string;
  radius: number;
  openNow: boolean;
  maxResults: number;
}

export interface PlaceDetailsInput {
  placeId: string;
  sessionToken?: string;
}

export interface PlacePhotoInput {
  photoName: string;
  maxWidthPx: number;
}

export interface ComputeRouteInput {
  origin: WaypointInput;
  destination: WaypointInput;
  travelMode: TravelMode;
}

export type TravelMode =
  | "DRIVE"
  | "WALK"
  | "BICYCLE"
  | "TRANSIT"
  | "TWO_WHEELER";

export interface RoadTripStopsInput {
  origin: WaypointInput;
  destination: WaypointInput;
  categories: string[];
}

export interface AirQualityInput extends Coordinate {
  includeForecast: boolean;
  forecastHours: number;
}

export interface PollenInput extends Coordinate {
  days: number;
}

export interface SolarCheckInput {
  address: string;
}

export interface AutocompleteInput {
  text: string;
  sessionToken: string;
  latitude?: number;
  longitude?: number;
  radius?: number;
}

export interface BackendOptions {
  airQualityForecastEnabled: boolean;
  solarEnabled: boolean;
}

export type FetchLike = (
  input: string | URL | Request,
  init?: RequestInit,
) => Promise<Response>;
