# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-10-01

## In progress

- Nothing – next: the user picks from “Up next”

## Up next

- #111 Secure the release signing key – user task (store keystore and password separately)
- #15 Identify a plant from a photo (plant.id, key in the settings)

## Backlog by initiative → epic

**#149 Plant knowledge and automation**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #13 Plant knowledge and automatic care plans | 1 of 4 closed | #15 Identify a plant from a photo and set up its care plan automatically → #112 Seasonal care adjustment → #30 Tip of the day |
| #31 Outdoor plants and weather (deliberately last) | 0 of 1 closed | #26 Weather-aware watering for outdoor plants |

**#150 Data safety and multi-device**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #126 Shared household | 0 of 1 closed | #127 Share plants between phones (household sync) |

**#151 Release and platform**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #152 Signed, installable releases | 0 of 1 closed | #111 Secure the release signing key (user task) |

**Resting**

- #148 Daily plant care – all epics done (#1, #5, #10, #128)

Guiding principle: as much as possible happens automatically (photo → species → care plan → calendar → one daily notification).

## Recently done

- #124 More species: bonsai, balcony plants, herbs and vegetables (now 109)
- #123 Pruning as a care task
- #125 Calendar month and year view
- #14 Plant database: pick a species, care intervals prefilled (71 houseplants, offline)
- #17 Backup and export (zip with data and photos; share sheet / file picker)

## Decisions

- 2026-10-01: planning structure Initiative → Epic → Story → Task (see `docs/planning-structure.md`)
- 2026-09-30: #14 care data: own curated offline table (DE/EN), seeded from Open Plantbook
- 2026-09-30: #15 identification: plant.id (Kindwise); API key entered by the user in the settings (private use for now)
- 2026-09-30: camera/gallery allowed (journal epic done)

## Open decisions (user only)

- Initiatives #148–#151 and epic #152 are new (migration) – please confirm or re-sort
- Household sync (#127): which service (e.g. Firebase, Supabase, self-hosted) – needs `INTERNET`, an account, possibly costs; photos in the cloud
- Android only, or iOS later? (home: #151)
- Weather for outdoor plants (#26, later): which service (e.g. Open-Meteo, Bright Sky / DWD, wetter.com API) – needs `INTERNET`, possibly an API key or paid plan; location entered manually or via GPS
