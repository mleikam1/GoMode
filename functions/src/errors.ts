export type PublicErrorCode =
  | "invalid-argument"
  | "not-found"
  | "failed-precondition"
  | "resource-exhausted"
  | "unavailable"
  | "internal";

export class BackendError extends Error {
  constructor(
    public readonly code: PublicErrorCode,
    message: string,
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "BackendError";
  }
}

export class GoogleApiError extends BackendError {
  constructor(
    public readonly operation: string,
    public readonly upstreamStatus: number,
    public readonly retryable: boolean,
  ) {
    const code: PublicErrorCode =
      upstreamStatus === 429
        ? "resource-exhausted"
        : retryable
          ? "unavailable"
          : upstreamStatus === 404
            ? "not-found"
            : upstreamStatus >= 400 && upstreamStatus < 500
              ? "failed-precondition"
              : "internal";
    const message =
      code === "resource-exhausted"
        ? "The map service is busy. Please try again shortly."
        : code === "unavailable"
          ? "The map service is temporarily unavailable."
          : code === "not-found"
            ? "The requested map resource was not found."
            : "The map service could not complete the request.";
    super(code, message, {operation, upstreamStatus});
    this.name = "GoogleApiError";
  }
}

export function invalidArgument(
  message: string,
  field?: string,
): BackendError {
  return new BackendError(
    "invalid-argument",
    message,
    field === undefined ? undefined : {field},
  );
}
