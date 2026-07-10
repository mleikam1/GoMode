import {BackendError} from "./errors";

interface RequestLike {
  originalUrl: string;
  protocol: string;
  get(name: string): string | undefined;
}

interface RuntimeEnvironment {
  FUNCTIONS_EMULATOR?: string;
  GCLOUD_PROJECT?: string;
  GOOGLE_CLOUD_PROJECT?: string;
}

export function photoProxyBaseUrl(
  request: RequestLike,
  environment: RuntimeEnvironment = process.env,
): string {
  if (environment.FUNCTIONS_EMULATOR !== "true") {
    const projectId =
      environment.GCLOUD_PROJECT ?? environment.GOOGLE_CLOUD_PROJECT;
    if (
      projectId === undefined ||
      !/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(projectId)
    ) {
      throw new BackendError(
        "internal",
        "The photo proxy URL could not be created.",
      );
    }
    return `https://us-central1-${projectId}.cloudfunctions.net/placePhotoProxy`;
  }

  const host = request.get("host");
  if (host === undefined || !/^[A-Za-z0-9.:[\]-]+$/.test(host)) {
    throw new BackendError("internal", "The photo proxy URL could not be created.");
  }
  const forwardedProtocol = request
    .get("x-forwarded-proto")
    ?.split(",")[0]
    ?.trim();
  const protocol =
    forwardedProtocol === "https" ||
    (forwardedProtocol === undefined && request.protocol === "https")
      ? "https"
      : "http";
  const url = new URL(request.originalUrl, `${protocol}://${host}`);
  url.pathname = url.pathname.replace(/\/placePhoto\/?$/, "/placePhotoProxy");
  if (!url.pathname.endsWith("/placePhotoProxy")) {
    throw new BackendError("internal", "The photo proxy URL could not be created.");
  }
  url.search = "";
  return url.toString();
}
