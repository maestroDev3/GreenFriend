# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-30

## In progress

- #14 Plant database: care profile per species, applied automatically

## Up next

- #111 Secure the release signing key – user task (store keystore and password separately)
- #15 Identify a plant from a photo (plant.id, key in the settings)

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| #1 Foundation | – (all done) |
| #5 Care and reminders | – (all done) |
| #13 Plant knowledge and automatic care plans | #15 Identify a plant from a photo and set up its care plan automatically → #112 Seasonal care adjustment → #30 Tip of the day |
| #10 Growth journal | – (all done) |
| #16 Data safety | #111 Secure the release signing key (user task) |
| #31 Outdoor plants and weather (later) | #26 Weather-aware watering for outdoor plants |

Guiding principle: as much as possible happens automatically (photo → species → care plan → calendar → one daily notification).

## Recently done

- #17 Backup and export (zip with data and photos; share sheet / file picker)
- #12 Timeline with before/after (journal epic done)
- #11 Photos and notes per plant (journal)
- #29 App navigation: bottom bar (Foundation epic done)
- #25 Care calendar

## Decisions (2026-09-30)

- #14 care data: own curated offline table (DE/EN), seeded from Open Plantbook
- #15 identification: plant.id (Kindwise); API key entered by the user in the settings (private use for now)
- Camera/gallery allowed (journal epic done)

## Open decisions (user only)

- Android only, or iOS later?
- Weather for outdoor plants (#26, later): which service (e.g. Open-Meteo, Bright Sky / DWD, wetter.com API) – needs `INTERNET`, possibly an API key or paid plan; location entered manually or via GPS
