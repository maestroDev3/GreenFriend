# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-30

## In progress

- #29 App navigation: bottom bar – Epic #1 Foundation (being refined)

## Up next

- #7 Reminders as notifications, #8 Confirm care and history (Epic #5)

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| #1 Foundation | #29 App navigation: bottom bar (`in-progress`) |
| #5 Care and reminders | #7 Reminders as notifications → #8 Confirm care and history → #9 Fertilizing and repotting → #25 Care calendar: what is due when and where |
| #13 Plant knowledge and automatic care plans | #14 Plant database: care profile per species, applied automatically → #15 Identify a plant from a photo and set up its care plan automatically (after decision) → #30 Tip of the day |
| #10 Growth journal | #11 Photos and notes per plant → #12 Timeline with before/after |
| #16 Data safety | #17 Backup and export |
| #31 Outdoor plants and weather (later) | #26 Weather-aware watering for outdoor plants |

Guiding principle: as much as possible happens automatically (photo → species → care plan → calendar → one daily notification).

## Recently done

- #4 Home screen: plants that need attention today on top
- #28 Plant detail page
- #6 Watering interval and due-date logic
- #3 Create, edit and delete plants
- #2 Project setup: EN/DE localization, theme (light/dark), fonts, settings (theme + language), app icon

## Open decisions (user only)

- Plant identification (#15): which service (e.g. Pl@ntNet, Plant.id) – needs `INTERNET` and possibly an API key
- Android only, or iOS later?
- Plant database for #14: external database/API (decided) – which one is open; research in the Claude project (`plant-database-research.md`)
- Plant photo before the journal epic? CLAUDE.md currently allows camera/gallery only with the journal epic (#10)
- Weather for outdoor plants (#26, later): which service (e.g. Open-Meteo, Bright Sky / DWD, wetter.com API) – needs `INTERNET`, possibly an API key or paid plan; location entered manually or via GPS
