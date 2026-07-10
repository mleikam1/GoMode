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

---

# Saved Design QA

- Source visual truth: `docs/design_refs/approved/05_saved.png`
- Implementation screenshot: `/private/tmp/gomode_saved_471x809.png`
- Normalized side-by-side comparison: `/private/tmp/gomode_saved_design_comparison.png`
- Supporting interaction captures: `/private/tmp/gomode_saved_places_empty_471x836.png`, `/private/tmp/gomode_saved_collection_created_471x836.png`, and `/private/tmp/gomode_saved_collection_reloaded_471x836.png`
- Viewport: 471 × 809 app-content pixels. The approved 941 × 1672 source includes a 54-physical-pixel OS status bar, so that region was removed and the remaining source was downsampled exactly to the browser app surface.
- State: light theme, Plans selected, four first-launch demo saves, and no collections

## Full-view comparison evidence

The status-bar-normalized approved reference and final Flutter capture were combined into one 962 × 809 original-resolution comparison and opened together. The implementation matches the source hierarchy and main region positions: wordmark/location/notification header, title and subtitle, four typed tabs, overlapping white cards, all four image subjects and text records, status pills, quest progress, Collections heading, empty collection call to action, and active Saved navigation.

The card stack begins within one logical pixel of the source after status-bar normalization. Header, tab, collection, and navigation boundaries align within a few logical pixels. Focused crops were not required because the original-resolution comparison keeps category labels, titles, descriptions, timestamps, statuses, progress, and collection copy readable.

## Required fidelity surfaces

- Fonts and typography: GoMode's configured system/Roboto stack preserves the source's heavy display hierarchy, compact uppercase category labels, readable card titles, and muted supporting copy. All text fits without clipping. The approved display face remains slightly rounder, which is P3 app-wide typography polish.
- Spacing and layout rhythm: Header content, tabs, card overlap, 20-pixel page margins, 110-pixel card rhythm, collection surface, and compact navigation follow the approved proportions. The final 471 × 809 capture and 390 × 844 widget tests have no overflow.
- Colors and visual tokens: Existing navy header, active blue gradient, coral, teal, lavender, amber, green, white surface, border, and shadow tokens closely match the approved palette and semantic states.
- Image quality and asset fidelity: Four project-local 512 × 512 raster illustrations match the approved Date Night, Austin park, scenic drive, and Local Quest subjects and crops. They remain sharp in the card slots and use no network placeholders or code-drawn substitutes.
- Copy and content: Header copy, all four tabs, every card category/title/description/metadata/status, quest progress, Collections heading, empty-state title, and Create collection label match the requested content.
- Controls and states: Tabs filter by saved type, all item menus can remove saves, mode-result bookmarks toggle, Date Night and Road Trip save controls are reversible, and collection creation accepts a local name. Browser checks verified the Places empty state, collection creation, and collection persistence after reload.
- Responsiveness and accessibility: Tabs and cards fit at 390 pixels wide, the collection layout stacks on narrow screens, native buttons expose semantics, and the final fresh browser tab reported no console warnings or errors.

## Comparison history

### Pass 1

- Evidence: `/private/tmp/gomode_saved_pass2_471x836.png`
- [P2] The existing 86-pixel bottom navigation covered most of the empty collection surface.
- [P2] The four-card stack used slightly too much vertical space for the approved viewport.

Fixes made:

- Matched the approved compact navigation proportions and tightened the indicator, icon, and label rhythm.
- Reduced wide-card height and inter-card gaps while preserving the reference image crop and all text.
- Made the collection empty state responsive and compacted its button to the approved width.

### Pass 2

- Evidence: `/private/tmp/gomode_saved_471x836.png`
- [P2] A one-pixel navigation overflow remained at the compact height.
- [P2] Browser capture included no OS status bar, leaving the header/card comparison vertically offset from the source.

Fixes made:

- Reduced bottom-navigation icon and label metrics so the compact shell has no overflow.
- Tightened the dense header's notification, location, subtitle, and tab metrics.
- Compared the implementation against the source's 471 × 809 app-content region after removing the 54-pixel status bar.

### Final pass

- Evidence: `/private/tmp/gomode_saved_471x809.png` and `/private/tmp/gomode_saved_design_comparison.png`
- Header, tabs, cards, collection surface, and navigation align with no actionable P0/P1/P2 differences.
- Interaction evidence confirms filter empty states, collection creation, reload persistence, and a clean browser console.

## Findings

No actionable P0, P1, or P2 findings remain.

## Open questions

- The approved collection surface uses a dashed border and decorative sparkles. The implementation uses the existing solid border token and Material folder/favorite icons; this is an acceptable P3 simplification that keeps the empty-state action clear.

## Implementation checklist

- [x] Match the approved Saved header, tabs, four demo cards, statuses, and collection empty state.
- [x] Persist typed saved items and collections locally behind a replaceable repository abstraction.
- [x] Seed demo data only once and preserve user removals across restarts.
- [x] Make Date Night, Road Trip, and generic mode-result save controls reversible.
- [x] Verify filter, empty, collection-create, and reload states with no browser console errors.

## Follow-up polish

- [P3] A future app-wide rounded display font and dashed-border primitive could close the remaining small decorative differences.

final result: passed

---

# Road Trip Stops Design QA

- Source visual truth: `docs/design_refs/approved/04_road_trip_results.png`
- Implementation screenshot: `/private/tmp/gomode_road_trip_471x836.png`
- Normalized side-by-side comparison: `/private/tmp/gomode_road_trip_design_comparison.png`
- Supporting interaction captures: `/private/tmp/gomode_road_trip_food_filter_471x836.png`, `/private/tmp/gomode_road_trip_map_471x836.png`, `/private/tmp/gomode_road_trip_persisted_stop_471x836.png`, and `/private/tmp/gomode_road_trip_navigate_map_471x836.png`
- Viewport: 471 × 836 logical pixels, matching the approved 941 × 1672 reference at 2× density
- State: light theme, Results selected, no quick filters selected, Austin-to-San Antonio demo route

## Full-view comparison evidence

The approved reference and the final Flutter capture were normalized into a single original-resolution comparison. The reference's 54-pixel OS status-bar region was removed and white padding added at the bottom so the app surfaces align without treating browser chrome as design drift. The implementation matches the reference's nested header, title/subtitle hierarchy, centered segmented control, blue route summary, quick-filter strip, three photo-led stop cards, dual actions, sticky route CTA, and five-item navigation.

The final app regions align within a few logical pixels after status-bar normalization: the summary begins at the same height, filter strip and first result sit within roughly five pixels, and the CTA/navigation boundary follows the same vertical rhythm. A separate focused crop was not needed because the 1883 × 1672 side-by-side file retains legible typography, icons, ratings, pills, photo crops, and controls at original detail.

## Required fidelity surfaces

- Fonts and typography: GoMode's configured system/Roboto stack preserves the mock's strong rounded hierarchy, heavy title/card weights, compact metadata, and single-line truncation. The reference display face is marginally rounder, which remains P3 app-wide typography polish.
- Spacing and layout rhythm: Header controls, segment, summary, filter strip, cards, CTA, and navigation align closely after two responsive fixes. All three result actions are visible at 471 × 836, while the 390 × 844 widget suite confirms there is no Flutter overflow on a narrower screen.
- Colors and visual tokens: Existing navy, primary-blue, lavender, amber, teal, coral, surface, border, and shadow tokens reproduce the approved palette and semantic states. The route card intentionally uses the existing primary gradient rather than adding an isolated new token.
- Image quality and asset fidelity: Three project-local high-resolution rasters match the approved subjects and crops: Buc-ee's storefront, Texas hill-country overlook, and brisket tray. All are sharp in the 143 × 114 result slots with no network, placeholder, or code-drawn substitute imagery.
- Copy and content: Title, Austin-to-San Antonio subtitle, endpoints, 82-mile total, 1h 23m estimate, five filters, three result names, ratings, distances, detours, open states, Save/Navigate controls, and Open Route Map CTA match the requested content.
- Controls and interaction states: Food filtering removes the Scenic result and visibly selects the chip; Results/Map switches to the demo preview; Save fills the heart, changes the button to Saved, and survives a browser reload; Navigate opens `#/map`; Open Route Map uses the same in-app route behavior.
- Responsiveness and accessibility: Tests pass at 390 × 844 with selected semantics on the segment and filter controls, native button hit targets, tooltips on favorite hearts, and scroll fallback for smaller/large-text layouts. The final browser reload added no new console errors; accumulated console entries only record the earlier fixed three-pixel card overflow.

## Comparison history

### Pass 1

- Evidence: `/private/tmp/gomode_road_trip_471x836_pass1.png`
- [P2] The 52-pixel sticky CTA sat too high and obscured the third result's controls because GoMode's existing navigation is taller than the reference navigation.
- [P2] The result imagery and header-to-list rhythm were less tightly cropped than the approved mock.

Fixes made:

- Reduced the CTA to the reference-like 38-pixel height and aligned it immediately above the existing navigation.
- Tightened each stop card to 132 pixels, reduced internal action/title heights, removed extra header tail spacing, and adjusted the Buc-ee's crop.

### Pass 2

- Evidence: `/private/tmp/gomode_road_trip_471x836_pass2.png`
- [P2] The first compact-card pass overflowed its content column by three pixels and exposed Flutter's overflow stripe.
- [P2] The route summary's bright cyan edge was more pronounced than the approved blue treatment.

Fixes made:

- Removed three pixels from the title/action vertical allocation while preserving every label and touch surface.
- Switched the summary to GoMode's existing primary blue gradient.

### Final pass

- Evidence: `/private/tmp/gomode_road_trip_471x836.png` and `/private/tmp/gomode_road_trip_design_comparison.png`
- All result content and actions render without clipping or overflow, the sticky CTA is fully visible, the route summary is closer to the approved palette, and no actionable P0/P1/P2 mismatch remains.

## Findings

No actionable P0, P1, or P2 findings remain.

## Open questions

- The approved image shows Home selected in the bottom navigation. The implementation intentionally shows Modes because Road Trip Stops is a nested custom route in GoMode's established Modes branch, matching the navigation decision already used for Date Night.
- The reference contains decorative route squiggles, mountains, and star specks in the summary/header. The implementation uses standard route/end-point/progress icons and the existing GoMode header treatment; this is acceptable P3 decorative simplification and does not reduce route comprehension.

## Implementation checklist

- [x] Match the approved results hierarchy, route content, cards, and sticky CTA.
- [x] Provide realistic local demo data and project-local image assets.
- [x] Make filters, segmented views, Save/favorite, Navigate, and Open Route Map interactive.
- [x] Verify save persistence across reload.
- [x] Verify the 390 × 844 narrow layout and 471 × 836 reference layout.
- [x] Run browser console and interaction checks.

## Follow-up polish

- [P3] A future app-wide rounded font asset could more exactly match the approved display type.
- [P3] Google Maps configuration can replace the current polished route placeholder without changing the segmented-control contract.

final result: passed
