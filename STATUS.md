# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-10-23

## In progress

- #223 Onboarding on first start (epic #222, branch `epic/google-play`)

## Up next

- #225 Store listing and screenshots
- Blocked by your decisions: #224 privacy policy (hosting), #226 release track (Play account), #111 signing key (user task)

## Backlog by initiative → epic

**#150 Data safety and multi-device**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #126 Shared household | 0 of 1 closed | #127 Share plants between phones (household sync) |

**#151 Release and platform**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #152 Signed, installable releases | 0 of 1 closed | #111 Secure the release signing key (user task) |
| #222 Published on Google Play | 0 of 4 closed (#223 in progress) | #223 Onboarding on first start → #224 Privacy policy and data safety → #225 Store listing and screenshots → #226 Signed app bundle and release track |
| #227 Green Friend on iPhone | 0 of 3 closed | #228 iOS build in CI → #229 iOS permissions, notifications and calendar → #230 TestFlight distribution |

Guiding principle: as much as possible happens automatically (photo → species → care plan → calendar → one daily notification).

## Recently done

- Initiatives #148 and #149 merged into `main` (#283): widget, vacation, statistics, time-lapse, frost, health check, light check, water amount; review fixes #276

## Decisions

- 2026-10-23: `epic/care-and-knowledge` merged after test and review; next epic #222 Google Play (onboarding first, branch `epic/google-play`)
- 2026-10-17: next: initiative #148, then #149, on one test branch; time-lapse as GIF (#212); sitter plan as text (#209); health check may use credits after one confirmation (#217)
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

- Close initiatives #148 Daily plant care and #149 Plant knowledge and automation? All their epics are done (only you close initiatives)
- Epics #152 and #227 (initiative #151) still to confirm
- Household sync (#127): which service (e.g. Firebase, Supabase, self-hosted) – needs `INTERNET`, an account, possibly costs; photos in the cloud
- iOS (epic #227): Android first, plugins iOS-ready (2026-10-14); start only after you decide (needs a Mac or macOS CI and an Apple developer account)
- Google Play (epic #222): developer account (one-off fee) and where to host the privacy policy
