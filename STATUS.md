# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-10-17

## In progress

- Branch `epic/care-and-knowledge`: initiatives #148 and #149 complete (epics #204, #207, #210, #213, #216, #219) – waiting for your APK test, then merge to `main`

## Up next

- #111 Secure the release signing key – user task (store keystore and password separately)

## Backlog by initiative → epic

**#149 Plant knowledge and automation**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #213 Frost protection for outdoor plants | 2 of 2 closed (on the test branch) | #214 Frost sensitivity per species → #215 Frost warning for outdoor plants |
| #216 Plant health check | 2 of 2 closed (on the test branch) | #217 Check plant health from a photo → #218 Save health checks in the journal |
| #219 Right spot and right amount | 2 of 2 closed (on the test branch) | #220 Light check at a spot → #221 Water amount from pot size |

**#150 Data safety and multi-device**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #126 Shared household | 0 of 1 closed | #127 Share plants between phones (household sync) |

**#151 Release and platform**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #152 Signed, installable releases | 0 of 1 closed | #111 Secure the release signing key (user task) |
| #222 Published on Google Play | 0 of 4 closed | #223 Onboarding on first start → #224 Privacy policy and data safety → #225 Store listing and screenshots → #226 Signed app bundle and release track |
| #227 Green Friend on iPhone | 0 of 3 closed | #228 iOS build in CI → #229 iOS permissions, notifications and calendar → #230 TestFlight distribution |

**#148 Daily plant care**

| Epic | Progress | Stories (in order) |
|---|---|---|
| #204 Care at a glance on the home screen | 2 of 2 closed (on the test branch) | #205 Home-screen widget: care due today → #206 Mark care as done from the widget |
| #207 Plants cared for while I am away | 2 of 2 closed (on the test branch) | #208 Vacation mode pauses my reminders → #209 Share a care plan with a plant sitter |
| #210 Motivation through progress | 2 of 2 closed (on the test branch) | #211 Care statistics and streaks → #212 Growth time-lapse from journal photos |

Guiding principle: as much as possible happens automatically (photo → species → care plan → calendar → one daily notification).

## Recently done

- #219 Light check with the phone's light sensor (#220), water amount from pot size (#221) – test branch
- #216 Plant health check: plant.id health assessment with one-time credit consent (#217), saved to the journal (#218) – test branch
- #213 Frost protection: lowest temperature per species/plant (#214), frost warning card and 5 pm notification (#215) – test branch
- #210 Motivation: care statistics with streaks (#211), growth time-lapse as GIF (#212) – test branch
- #207 Vacation mode (#208) and plant-sitter plan via share (#209) – test branch

## Decisions

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

- APK test of `epic/care-and-knowledge` and OK to merge into `main`; afterwards the epics are closed and initiatives #148 and #149 can be closed (all epics done)
- Epics #152, #222, #227 (initiative #151) still to confirm
- Household sync (#127): which service (e.g. Firebase, Supabase, self-hosted) – needs `INTERNET`, an account, possibly costs; photos in the cloud
- iOS (epic #227): Android first, plugins iOS-ready (2026-10-14); start only after you decide (needs a Mac or macOS CI and an Apple developer account)
- Google Play (epic #222): developer account (one-off fee) and where to host the privacy policy
