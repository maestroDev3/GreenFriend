# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-10-14

## In progress

- #161 Extend the plant database (Epic #13), then #26 Weather-aware watering (Epic #31) – on `epic/plant-knowledge-automation`
- Epics #13, #175 and #184 are waiting for your test: pre-release **epic-test** APK from `epic/plant-knowledge-automation` (#15, #112, #30, #170, #176, #177, #185). Merged into `main` after your OK.

## Up next

- #111 Secure the release signing key – user task (store keystore and password separately)

## Backlog by initiative → epic

**#149 Plant knowledge and automation**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #13 Plant knowledge and automatic care plans | 5 of 6 closed | #161 Extend the plant database with commonly identified species (ready) |
| #31 Outdoor plants and weather | 0 of 1 closed | #26 Weather-aware watering for outdoor plants (ready) |

**#150 Data safety and multi-device**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #126 Shared household | 0 of 1 closed | #127 Share plants between phones (household sync) |

**#151 Release and platform**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #152 Signed, installable releases | 0 of 1 closed | #111 Secure the release signing key (user task) |

**#148 Daily plant care**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #175 Care done in one tap | 2 of 2 closed (on the epic branch) | – |
| #184 Care plan in the phone calendar | 1 of 1 closed (on the epic branch) | – |

Guiding principle: as much as possible happens automatically (photo → species → care plan → calendar → one daily notification).

## Recently done

- #185 Care tasks in the phone calendar (auto sync, calendar picked in the app, 60 days, all-day)
- #177 Reminder buttons: mark care as done right in the notification (one reminder per plant)
- #176 Care buttons show "Water" until done, then "✓ Watered"
- #170 Robust identification errors and winter-rest edge cases (review findings) – on the epic branch
- #30 Tip of the day (48 curated tips EN/DE, home card) – on the epic branch

## Decisions

- 2026-10-14: #161 as proposed (local list of missing species + about 30 more species)
- 2026-10-14: #26 weather from Open-Meteo (no key), place entered manually; rain ≥ 5 mm counts as watering, heat ≥ 30 °C as hint
- 2026-10-14: winter rest stays on for existing plants
- 2026-10-14: #185 phone calendar: automatic sync, calendar chosen in the app, all care tasks all-day for 60 days, no alarms; plugin `device_calendar_plus` (Android now, Apple calendar ready)
- 2026-10-01: planning structure Initiative → Epic → Story → Task (see `docs/planning-structure.md`)
- 2026-10-02: #15 top 3 candidates; unknown species → same-genus template, else manual intervals (#161 extends the database)
- 2026-10-02: #112 winter rest Nov–Feb, watering × 1.5, no fertilizer, switch per plant
- 2026-10-02: #30 curated tips (EN/DE) offline, card on the home screen, dismissable
- 2026-09-30: #14 care data: own curated offline table (DE/EN), seeded from Open Plantbook
- 2026-09-30: #15 identification: plant.id (Kindwise); API key entered by the user in the settings (private use for now)
- 2026-09-30: camera/gallery allowed (journal epic done)

## Open decisions (user only)

- Epics #13, #175 and #184: test the epic-test APK (photo identification needs your plant.id key under More → Settings); then OK to merge into `main`?
- Initiatives #148–#151 and epics #152, #175, #184 are new – please confirm or re-sort
- Household sync (#127): which service (e.g. Firebase, Supabase, self-hosted) – needs `INTERNET`, an account, possibly costs; photos in the cloud
- iOS: Android first, plugins chosen iOS-ready (2026-10-14); an iOS build becomes its own epic in #151 when you decide (needs a Mac or macOS CI and an Apple developer account)
