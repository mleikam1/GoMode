# GoMode Design Implementation Notes

## Reference Assets

- Approved mockups live in `docs/design_refs/approved/`.
- Earlier iterations live in `docs/design_refs/archive/`.
- The mockups are reference-only files. Runtime UI is built from Flutter widgets, theme tokens, icons, gradients, and `CustomPainter` illustrations.

## Shared Visual System

- `lib/core/theme/app_colors.dart` defines the deep navy header, bright blue action gradient, teal, coral, amber, lavender, and green accents, surface whites, text colors, and borders.
- `lib/core/theme/app_spacing.dart`, `app_radius.dart`, and `app_shadows.dart` centralize safe spacing, large rounded surfaces, pill controls, and soft elevated card shadows.
- `lib/core/theme/app_theme.dart` applies Material 3, system typography, rounded input/chip/card defaults, and GoMode navigation colors.

## Approved Screen Mapping

### `01_home.png`

- Deep navy hero: `GradientHeader`
- Location and notification treatment: `GradientHeader`, `HeaderIconButton`
- Mood filters: `FilterChipPill`
- Blue spin card: `FeaturedModeCard`, `ModeWheelIllustration`, `PrimaryGradientButton`
- Popular mode cards: `CategoryCarousel`, `ModeCard`, `SoftIconBadge`, and mode illustration widgets
- Continue card: `SavedPlanThumbnail`, `StatusPill`, `ProgressPill`
- Five-item nav: `BottomNavShell`

### `02_modes_latest_large_category_carousels.png`

- Search affordance: `AppSearchBar`
- Selected and unselected category pills: `FilterChipPill`
- Large top carousel cards: `CategoryCarousel`, `ModeCard`
- Smaller grouped mode rows: `CategoryCarousel`, `CompactModeCard`
- The current home route uses the same carousel/card primitives so a future Modes route can compose this screen without new visual tokens.

### `03_date_night_clean.png`

- Detail header/back/favorite structure: `GradientHeader` with custom `leading` and `trailing`
- Pink hero artwork: `DateNightIllustration`
- Budget/vibe/time controls: `FilterChipPill` and `StatusPill` styles
- Bottom CTA: `PrimaryGradientButton`
- Large white form surface: shared `AppRadius.largeCard`, `AppShadows.card`, and `AppColors.surfaceRaised`

### `04_road_trip_results.png`

- Route header: `GradientHeader`
- Results/map segmented treatment: `FilterChipPill` styling
- Route summary accents: `AppColors.primaryBlue`, `AppColors.lavender`, and `AppColors.teal`
- Stop cards and actions: shared white card surface, `StatusPill`, `PrimaryGradientButton`
- Road artwork: `RoadTripIllustration`

### `05_saved.png`

- Saved header and tab pills: `GradientHeader`, `FilterChipPill`
- Saved plan list thumbnails: `SavedPlanThumbnail`
- Plan status treatments: `StatusPill`, `ProgressPill`
- Empty collection surface: shared border, radius, and white raised surface tokens
- Active Saved tab: `BottomNavShell`

## Illustration Widgets

Flutter-drawn illustrations live in `lib/shared/widgets/mode_illustrations.dart`:

- `DateNightIllustration`
- `WeekendParkIllustration`
- `RoadTripIllustration`
- `AllergyOutdoorIllustration`
- `LocalQuestIllustration`
- `SavedPlanThumbnail`
- `ModeWheelIllustration`

These intentionally approximate the mockup subjects with gradients, Material icons where useful, and simple `CustomPainter` shapes instead of embedding full-screen mockups or generated screenshots.
