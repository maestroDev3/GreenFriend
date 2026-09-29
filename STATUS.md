# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-29

## In progress

- Nothing yet.

## Up next

- #2 Project setup (`ready`) – Epic #1 Foundation

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| #1 Foundation | #2 Project setup (`ready`) → #3 Create, edit and delete plants → #4 Plant list with “Due today” on top |
| #5 Care and reminders | #6 Watering interval and due-date logic → #7 Reminders as notifications → #8 Confirm care and history → #9 Fertilizing and repotting → #25 Care calendar: what is due when and where → #26 Weather-aware watering for outdoor plants |
| #10 Growth journal | #11 Photos and notes per plant → #12 Timeline with before/after |
| #13 Plant knowledge | #14 Local catalog with care and light tips per species → #15 Plant identification from photo (after decision) |
| #16 Data safety | #17 Backup and export |

## Recently done

- First start: labels, epics and stories as issues, Flutter project scaffolded, CI green
- Repo created with CLAUDE.md, STATUS.md, Flutter skill and CI

## Open decisions (user only)

- Plant identification: which service (e.g. Pl@ntNet, Plant.id) – needs `INTERNET` and possibly an API key
- Android only, or iOS later?
- Weather for outdoor plants (#26): which service (e.g. Open-Meteo, Bright Sky / DWD, wetter.com API) – needs `INTERNET`, possibly an API key or paid plan; location entered manually or via GPS
