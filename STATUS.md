# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-29

## In progress

- Nothing yet – the repo only contains the working rules, skill and CI.

## Up next

- “First start” from CLAUDE.md: create labels, epics and stories as issues,
  run the Scaffold workflow, refine the first story “Project setup”.

## Planned epics (no issue numbers yet)

| Epic | Stories (in order) |
|---|---|
| Foundation | Project setup (scaffold, green CI, theme, `pumpApp`) → Create, edit and delete plants → Plant list with “Due today” on top |
| Care and reminders | Watering interval and due-date logic → Reminders as notifications → Confirm care and history → Fertilizing and repotting |
| Growth journal | Photos and notes per plant → Timeline with before/after |
| Plant knowledge | Local catalog with care and light tips per species → Plant identification from photo (after decision) |
| Data safety | Backup and export |

## Recently done

- Repo created with CLAUDE.md, STATUS.md, Flutter skill and CI

## Open decisions (user only)

- Plant identification: which service (e.g. Pl@ntNet, Plant.id) – needs `INTERNET` and possibly an API key
- Android only, or iOS later?
