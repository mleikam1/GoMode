# Date Night Design QA

- Source visual truth: `docs/design_refs/approved/03_date_night_clean.png`
- Implementation screenshot: `/private/tmp/gomode_date_night_setup_390x844.png`
- Reference-proportion screenshot: `/private/tmp/gomode_date_night_setup_471x837.png`
- Generated-plan action screenshot: `/private/tmp/gomode_date_night_plan_actions_390x844.png`
- Viewports: 390 × 844 for mobile resilience; 471 × 837 to compare at the approved image's 2× logical proportions
- State: light theme, default `$50` / Romantic / `2 hrs`, all toggles enabled

## Full-view comparison evidence

The approved reference and the 390 × 844 Flutter capture were opened together at original resolution. The final implementation preserves the same hierarchy and composition: centered nested-page header, back/favorite controls, pink illustrated hero, three short planning groups, one compact toggle row, Tonight's plan preview, primary CTA, and five-item navigation. The CTA and every required setup control remain visible without scrolling at 390 × 844.

The generated hero asset matches the reference subject, left-side copy space, pink skyline, bridge lights, wine-and-candle table, and bottom foliage treatment. Flutter renders the reference copy as native text over that artwork.

Focused crops were not required because the original-resolution 390 × 844 comparison keeps the typography, icons, chip borders, toggle states, preview copy, and CTA readable. Separate browser captures also verified the selected Fun state, disabled Open Now state, generated-plan cards, and the Save Plan/Open Map action region.

## Required fidelity surfaces

- Fonts and typography: GoMode's configured system/Roboto stack is used consistently. Weight and hierarchy match the reference closely; all setup copy remains readable with no clipping or unintended wrapping. The reference's slightly rounder display face remains a P3 system-font difference.
- Spacing and layout rhythm: Header, hero, controls, preview, CTA, and bottom navigation follow the approved order and proportions. The first pass was too tall; the final pass uses reference-like chip, toggle, preview, and CTA heights and fits the narrow mobile viewport.
- Colors and visual tokens: The existing navy header, coral selected state, blush preview surface, white cards, gray borders, and blue CTA tokens closely match the approved palette. Contrast remains clear in selected and unselected states.
- Image quality and asset fidelity: `assets/images/date_night_hero.png` is a project-local high-resolution raster generated from the approved art direction. It is sharp at both tested viewports and uses the correct crop without placeholder or code-drawn substitute art.
- Copy and content: The title, subtitle, budgets, vibes, durations, toggles, Tonight's plan labels, Austin location, start time, and CTA match the requested copy. Generated-plan content adds the required dinner, activity, dessert/drink, time blocks, save, and map actions.
- Icons and controls: Material icons are visually consistent and aligned. Chip, switch, favorite, back, save, and map states are interactive. Browser checks confirmed Fun selection, Open Now toggling, plan generation, and successful local saving.
- Responsiveness and accessibility: No Flutter overflow or browser console errors occur at 390 × 844 or 471 × 837. Interactive choices expose button/selected semantics and native switches. The screen remains scrollable for larger text or shorter devices.

## Comparison history

### Pass 1

- Evidence: `/private/tmp/gomode_date_night_setup_pass1_390x844.png`
- [P2] The planning surface was too tall, leaving the preview and primary CTA below the initial mobile viewport.
- [P2] The Open Now label clipped to `Open` at 390 px width.
- [P2] The preview location/start-time row and generated-plan time rows overflowed in widget layout checks.

Fixes made:

- Reduced the visual height and gaps of the three choice rows, toggle panel, preview card, and CTA to the proportions in the approved reference.
- Tightened toggle icon, label, and switch sizing so `Open Now` remains fully visible.
- Made the preview metadata responsive and stacked generated-plan labels/time blocks to prevent horizontal overflow.

### Pass 2

- Evidence: `/private/tmp/gomode_date_night_setup_390x844.png`
- Post-fix result: all required setup content and the CTA are visible at 390 × 844, labels are complete, and no P0/P1/P2 mismatch remains.
- Interaction evidence: chip selection, toggle state, generation, save success, and plan/map actions passed with no browser console errors.

## Findings

No actionable P0, P1, or P2 findings remain.

## Open questions

- The approved image shows Home selected in the bottom navigation. The implementation intentionally shows Modes selected because Date Night is a nested route in GoMode's existing Modes branch. This preserves the current navigation architecture and does not affect the Date Night task flow.

## Implementation checklist

- [x] Match the approved clean setup hierarchy and copy.
- [x] Keep all setup controls functional and unclipped at the narrow viewport.
- [x] Generate a local three-stop plan with estimated times.
- [x] Provide working local save and map navigation actions.
- [x] Verify default, selected, toggled, generated, and saved states.

## Follow-up polish

- [P3] A future app-wide font asset could more closely match the reference's rounded display typography, but changing global typography is outside this focused Date Night milestone.

final result: passed
