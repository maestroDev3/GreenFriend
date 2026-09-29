# Green Friend – Design spec

Style: natural, calm, modern and high-quality. Warm and organic, not technical.
Plant photos play an important visual role. Elegant rather than colorful or playful.

## Light palette (agreed with the user)

| Role | Name | Hex | Use |
|---|---|---|---|
| `primary` | Forest Green | `#173B2A` | Headings, navigation, important buttons |
| `secondary` | Botanical Green | `#244A36` | Secondary elements, icons |
| `secondaryContainer` | Sage | `#A8B59A` | Icons, subtle highlights, secondary button fill, chips |
| scaffold / `surface` | Cream | `#F5F0E4` | Main background |
| card / `surfaceContainer` | Warm Beige | `#E8DECC` | Cards and sections |
| `tertiary` | Terracotta | `#B8785C` | Sparingly: small accents and warnings |
| `onSurface` | Ink | `#2B2B2B` | Body text |

Contrast: Forest Green on Cream 10.9:1, on Beige 9.3:1. Terracotta on Cream is only 3.1:1,
so it is used for icons, badges and backgrounds, never for small text.

## Dark palette (confirmed by the user, 2026-09-29)

| Role | Hex | Note |
|---|---|---|
| scaffold / `surface` | `#13201A` | Very dark forest green instead of black |
| card / `surfaceContainer` | `#1E2E25` | |
| `primary` | `#A8B59A` | Sage, with `onPrimary` `#13201A` (7.8:1) |
| `secondary` | `#C9D2BC` | Light sage |
| `tertiary` | `#D9A080` | Lighter terracotta (7.4:1 on background) |
| `onSurface` | `#F5F0E4` | Cream text (14.8:1) |

## Typography

| Level | Font | Weight / size |
|---|---|---|
| Heading 1 | Playfair Display | SemiBold, 24–32 |
| Heading 2 | Playfair Display | Medium, 18–22 |
| Heading 3 | Inter | SemiBold, 16 |
| Body | Inter | Regular, 14 |
| Small text / labels | Inter | Regular, 12 |

Fonts are bundled as assets (SIL Open Font License), not loaded at runtime.

## Shapes and layout

- Rounded cards (radius 20) and fully rounded (stadium) buttons.
- Primary button: filled Forest Green with cream text; secondary: outlined, cream fill.
- Icons: outlined line icons, often on a round sage/beige background.
- Lots of white space, clear and calm layout.
- Chips: sage (e.g. growth) and beige (e.g. care); warnings as terracotta-tinted pill.

## App icon (agreed 2026-09-29)

Seedling with two slightly asymmetric leaves (right one a bit larger) in Botanical/Forest Green
with sage veins, on Cream; three drops (`#8FA07F`) falling onto it – top left, middle right,
bottom centre. Source SVG in task #27 (`assets/icon/app_icon.svg`).

## Screens from the user's reference mockup

- **Home (#4):** greeting ("Hello! Nice to see you."), highlight card with plant photo
  ("1 of 5 plants needs attention today"), "My plants" as photo cards with next care, tip of the day (#30).
- **Plant detail (#28):** large photo header with back/favourite/more, name in Playfair,
  species, three care tiles (water, light, humidity), description, "Next care" row, primary button "Care plan".
- **Calendar (#25):** week strip with selected day, tasks grouped by day with icon,
  interval and a check circle.
- **Scan (#15):** full-screen camera with frame, bottom sheet "Identifying plant…" with steps and a tip.
- **Navigation (#29):** bottom bar Home, Plants, central "+" button, Calendar, More.
- Components: filled primary button with arrow, secondary outlined button, list cards with
  round icon badge and chevron, switch rows, chips (sage "Growth", beige "Care"), terracotta warning pill ("Water soon").
