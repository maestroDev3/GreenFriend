# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-10-02

## In progress

- #30 Tip of the day (Epic #13) – branch `epic/plant-knowledge-automation`, tasks #159–#160

## Up next

- #111 Secure the release signing key – user task (store keystore and password separately)

## Backlog by initiative → epic

**#149 Plant knowledge and automation**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #13 Plant knowledge and automatic care plans | 3 of 5 closed | #30 Tip of the day → #161 Extend the plant database with commonly identified species |
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

- #112 Winter rest Nov–Feb (watering × 1.5, no fertilizer, switch per plant) – on the epic branch
- #15 Identify a plant from a photo (plant.id, top 3, genus fallback) – on the epic branch, not in `main` yet
- #124 More species: bonsai, balcony plants, herbs and vegetables (now 109)
- #123 Pruning as a care task
- #125 Calendar month and year view

## Decisions

- 2026-10-01: planning structure Initiative → Epic → Story → Task (see `docs/planning-structure.md`)
- 2026-10-02: #15 top 3 candidates; unknown species → same-genus template, else manual intervals (#161 extends the database)
- 2026-10-02: #112 winter rest Nov–Feb, watering × 1.5, no fertilizer, switch per plant
- 2026-10-02: #30 curated tips (EN/DE) offline, card on the home screen, dismissable
- 2026-09-30: #14 care data: own curated offline table (DE/EN), seeded from Open Plantbook
- 2026-09-30: #15 identification: plant.id (Kindwise); API key entered by the user in the settings (private use for now)
- 2026-09-30: camera/gallery allowed (journal epic done)

## Open decisions (user only)

- Initiatives #148–#151 and epic #152 are new (migration) – please confirm or re-sort
- Household sync (#127): which service (e.g. Firebase, Supabase, self-hosted) – needs `INTERNET`, an account, possibly costs; photos in the cloud
- Android only, or iOS later? (home: #151)
- Weather for outdoor plants (#26, later): which service (e.g. Open-Meteo, Bright Sky / DWD, wetter.com API) – needs `INTERNET`, possibly an API key or paid plan; location entered manually or via GPS
