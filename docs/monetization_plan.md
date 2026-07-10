# GoMode Monetization Plan

## Current state

GoMode is monetization-ready, not monetized. The app ships with no ad SDK, ad
unit IDs, purchase product IDs, affiliate destinations, lead destination, or
lead-storage backend. Release flags default to off. Debug builds may render the
mock UI so layout and product behavior can be evaluated without making an ad,
purchase, tracking, or lead request.

`MonetizationService` is the single integration boundary. The default
`MockMonetizationService` returns clearly labeled previews, reports lead capture
as unconfigured, discards any payload it receives, and cannot start a purchase.

## Feature flags

| Product flag | Dart define | Default | Purpose |
| --- | --- | --- | --- |
| `adsEnabled` | `GOMODE_ADS_ENABLED` | Off | Allows rewarded/ad-backed UI. |
| `premiumEnabled` | `GOMODE_PREMIUM_ENABLED` | Off | Allows the Premium entry point and status UI. |
| `leadFormsEnabled` | `GOMODE_LEAD_FORMS_ENABLED` | Off | Allows guarded lead-form UI. |
| `sponsoredCardsEnabled` | `GOMODE_SPONSORED_CARDS_ENABLED` | Off | Allows native sponsored slots; also requires `adsEnabled`. |

Debug builds keep mock preview flags off by default so normal visual QA matches
the production experience. Set `GOMODE_MONETIZATION_DEBUG_UI=true` to inspect
the labeled mock placements. Mock service output is suppressed outside debug
builds.

Flags are only a presentation gate. Enabling a flag is not sufficient to ship a
surface: the corresponding production service, policy review, store setup, and
privacy work must also be complete.

## Surface rules

### Native sponsored cards

- Reserve at most one slot in a result list, after the first organic result.
- Keep the card visually compatible with GoMode while making the `Sponsored`
  disclosure persistent and prominent.
- Never let payment change the organic order or make a sponsored item look like
  an organic recommendation.
- Suppress sponsored cards when `PremiumStatus.adsRemoved` is true.
- Current mock cards have no destination and cannot be tapped.

### Rewarded unlocks

The abstraction covers an extra Date Night reroll, extra hidden gems, and extra
Road Trip stops. Every prompt states that the current result or route remains
usable. A declined, unavailable, or failed reward must leave the core flow
unchanged. Premium suppresses rewarded-ad prompts.

Before enabling, define the exact reward quantity, idempotency behavior, daily
limits, completion callback, offline behavior, and restore behavior. Only
official SDK test units may be used during development.

### Premium / no ads

Premium is modeled as entitlement state, including whether ads are removed. The
mock upgrade always reports unavailable; there is no store product or checkout
flow in this milestone. A production adapter must validate store entitlements,
restore purchases, handle grace/refund states, and keep all core MVP features
available to free users.

### Lead capture

Lead forms exist only for Solar Checker, Neighborhood Check, and Where Should I
Live?. The UI validates name, email, postal code, and consent locally. It does
not invoke `submitLeadCapture` unless the injected service explicitly reports
`leadCaptureConfigured == true`.

No current implementation is configured. Before enabling lead forms:

1. Approve clear, surface-specific privacy and contact-consent language.
2. Implement authenticated transport and a documented storage destination.
3. Define retention, deletion, access control, encryption, audit, and incident
   response policies.
4. Update the in-app Privacy screen and App Store / Play data disclosures.
5. Add consent-version and policy-version fields at the backend boundary.
6. Test deletion and opt-out workflows before accepting real data.

Do not add hidden fields, location enrichment, marketing profiles, or onward
sale/sharing without a separate product and privacy review.

### Affiliate and sponsored links

`SponsoredLinkMetadata` may be attached to result-card models, but defaults to
disabled and has no destination. Presentation code only renders a disclosure
when metadata is explicitly enabled. A future opener must allowlist schemes,
show the partner disclosure, avoid silent redirects, and preserve the organic
Save and Navigate actions.

## Production readiness gate

Do not turn on any monetization flag until all applicable items are complete:

- Production service adapter and failure-safe tests.
- Store/ad-network account ownership and restricted credentials.
- Consent, privacy, age-rating, and regional requirements reviewed.
- App Store and Play policy/disclosure updates reviewed.
- Accessibility, dark/text-scale, offline, and slow-network QA.
- Frequency caps and analytics that do not expose lead contents.
- Premium purchase restore and ad-suppression tests.
- Kill switch and rollback plan.
