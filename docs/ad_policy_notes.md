# Ad and Sponsorship Policy Notes

These notes are implementation guardrails, not a substitute for reviewing the
current Apple, Google Play, and ad-network policies immediately before release.

## MVP policy

- No ad SDK is installed.
- No real or test ad unit IDs are committed because no SDK call is needed.
- If an SDK is evaluated later, development and automated tests must use only
  the SDK vendor's official test units. Real units belong in restricted runtime
  configuration, never source control.
- Ads, sponsored content, affiliate links, and rewarded prompts are off in
  release builds by default.
- Core discovery, current results, Save, Navigate, and route usage must never be
  blocked by an ad or purchase.

## Native sponsored content

- Label every paid placement `Sponsored` at all times, including loading,
  expanded, and accessibility states.
- Do not copy the exact appearance of an organic result or place paid content in
  a way that invites accidental taps.
- Use one reserved slot at most per list for the initial rollout. Do not place a
  sponsored card before the first organic result.
- Sponsored ranking must not affect nearby/organic ranking claims.
- The sponsor name and destination must match the disclosure and creative.

## Rewarded ads

- State the reward before the user opts in.
- Reward only optional incremental content; never require a rewarded ad to use a
  core mode or recover from an error.
- Grant a completed reward exactly once, handle cancellation without penalty,
  and define a safe outcome when completion cannot be verified.
- Do not auto-play rewarded ads or present them as a required Continue button.

## Premium

- Premium removes sponsored and rewarded-ad surfaces when the entitlement says
  ads are removed.
- Purchase terms, price, billing period, renewal behavior, restoration, and
  cancellation must come from the store and be clear before checkout.
- Do not describe unavailable or mock functionality as purchasable.

## Privacy, consent, and targeting

- Do not initialize an ad SDK, request tracking permission, or create an ad
  identifier merely because a UI flag is enabled.
- Prefer contextual placement over behavioral targeting for the first rollout.
- Complete platform privacy manifests/data-safety disclosures and region/age
  consent flows before collecting advertising identifiers or serving
  personalized ads.
- Never send saved plans, precise location, health/environmental interests,
  housing preferences, lead-form contents, or contact information to an ad
  network without an explicit, reviewed data-use decision.
- Lead data is not ad data. Keep it out of ad attribution and audience systems
  unless users receive a separate clear disclosure and valid choice.

## Affiliate links

- Use an adjacent `Sponsored` or `Affiliate link` disclosure before the user
  opens the destination.
- Keep the destination disabled until partner review, URL allowlisting, privacy
  review, and attribution behavior are complete.
- Do not let affiliate compensation alter factual claims, safety caveats, or
  the availability of normal map/navigation actions.

## Release review checklist

- Recheck the latest platform and SDK policies.
- Verify all release flags default off and the mock service cannot render.
- Search source and packaged configuration for ad IDs and unapproved endpoints.
- Verify premium hides every ad-backed surface.
- Test screen-reader disclosure and large text without truncating `Sponsored`.
- Confirm an unavailable ad never blocks or degrades the core flow.
- Confirm privacy disclosures match the actual SDK/network data behavior.
