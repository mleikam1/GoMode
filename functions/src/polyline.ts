import {Coordinate} from "./types";

export function decodePolyline(encoded: string): Coordinate[] {
  const coordinates: Coordinate[] = [];
  let index = 0;
  let latitude = 0;
  let longitude = 0;

  while (index < encoded.length) {
    const latitudeResult = decodeValue(encoded, index);
    index = latitudeResult.nextIndex;
    latitude += latitudeResult.delta;

    const longitudeResult = decodeValue(encoded, index);
    index = longitudeResult.nextIndex;
    longitude += longitudeResult.delta;

    coordinates.push({
      latitude: latitude / 100_000,
      longitude: longitude / 100_000,
    });
  }
  return coordinates;
}

export function sampleRoutePoints(
  coordinates: Coordinate[],
  maximum = 3,
): Coordinate[] {
  if (coordinates.length === 0 || maximum < 1) return [];
  if (coordinates.length === 1) return [coordinates[0]!];

  const segmentLengths: number[] = [];
  let totalLength = 0;
  for (let index = 1; index < coordinates.length; index += 1) {
    const length = approximateDistance(
      coordinates[index - 1]!,
      coordinates[index]!,
    );
    segmentLengths.push(length);
    totalLength += length;
  }
  if (totalLength === 0) return [coordinates[0]!];

  const result: Coordinate[] = [];
  for (let i = 1; i <= maximum; i += 1) {
    const targetDistance = (totalLength * i) / (maximum + 1);
    let traversed = 0;
    for (let segmentIndex = 0; segmentIndex < segmentLengths.length; segmentIndex += 1) {
      const segmentLength = segmentLengths[segmentIndex]!;
      if (
        targetDistance <= traversed + segmentLength ||
        segmentIndex === segmentLengths.length - 1
      ) {
        const fraction =
          segmentLength === 0
            ? 0
            : (targetDistance - traversed) / segmentLength;
        const start = coordinates[segmentIndex]!;
        const end = coordinates[segmentIndex + 1]!;
        result.push({
          latitude: start.latitude + (end.latitude - start.latitude) * fraction,
          longitude:
            start.longitude + (end.longitude - start.longitude) * fraction,
        });
        break;
      }
      traversed += segmentLength;
    }
  }
  return result;
}

export function interpolateWaypoints(
  origin: Coordinate,
  destination: Coordinate,
  maximum = 3,
): Coordinate[] {
  return Array.from({length: maximum}, (_, index) => {
    const fraction = (index + 1) / (maximum + 1);
    return {
      latitude:
        origin.latitude + (destination.latitude - origin.latitude) * fraction,
      longitude:
        origin.longitude +
        (destination.longitude - origin.longitude) * fraction,
    };
  });
}

function decodeValue(
  encoded: string,
  startingIndex: number,
): {delta: number; nextIndex: number} {
  let result = 0;
  let shift = 0;
  let index = startingIndex;

  while (index < encoded.length) {
    const byte = encoded.charCodeAt(index) - 63;
    index += 1;
    if (byte < 0 || byte > 63) throw new Error("Invalid encoded polyline.");
    result |= (byte & 0x1f) << shift;
    shift += 5;
    if (byte < 0x20) {
      return {
        delta: result & 1 ? ~(result >> 1) : result >> 1,
        nextIndex: index,
      };
    }
    if (shift > 30) throw new Error("Invalid encoded polyline.");
  }
  throw new Error("Truncated encoded polyline.");
}

function approximateDistance(start: Coordinate, end: Coordinate): number {
  const radians = Math.PI / 180;
  const meanLatitude = ((start.latitude + end.latitude) / 2) * radians;
  const latitudeDelta = (end.latitude - start.latitude) * radians;
  const longitudeDelta = (end.longitude - start.longitude) * radians;
  const x = longitudeDelta * Math.cos(meanLatitude);
  return Math.hypot(x, latitudeDelta);
}
