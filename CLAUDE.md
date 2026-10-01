# Green Friend – How Claude works in this repo

Android app (Flutter) for houseplants: watering and fertilizing reminders, light and care tips, and a growth journal with photos.
Claude works in this repo **autonomously**. This file is binding.

## Language

- Everything in the repo is **English**: code, comments, UI texts, docs, issues,
  commit messages and PR descriptions (the app is meant to be marketable
  internationally).
- UI texts go through Flutter localization (`flutter_localizations` + ARB files,
  `app_en.arb` as the template) from day one, so more languages can be added later.
- Chat with the user may be in German; answer in the user's language.

## Product vision

Green Friend makes sure no houseplant dries out again. Every plant has its own
profile with watering and fertilizing intervals; the app reminds you on time and
you confirm with one tap. A growth journal with photos and notes shows how each
plant develops.
Guiding principle: as much as possible happens automatically. A photo identifies
the plant, its care profile comes from the plant database, the care tasks land in
the calendar, and the user only gets a notification like “Water these plants today”.
Domain terms:

- **Plant** – `Plant` – name, species, location, intervals, photo
- **Care task** – `CareTask` – water, fertilize, repot, prune (sealed class `CareKind`)
- **Care log** – `CareLog` – when which task was done
- **Journal entry** – `JournalEntry` – date, note, optional photo

## Structure: Initiative → Epic → Story → Task

Everything lives in GitHub issues, linked via sub-issues:

| Level | Label | Content |
|---|---|---|
| Initiative | `initiative` | Long-lived theme; epics as sub-issues |
| Epic | `epic` | Finite piece of work with an outcome; stories as sub-issues, order listed in the description |
| Story | `story` | User-visible feature (or a user task without code); tasks as sub-issues |
| Task | `task` | Exactly one PR, TDD, testable acceptance criteria |

Story status (label, exactly one; done = closed):
- `backlog` – idea, roughly described, **no tasks yet**
- `ready` – refined, tasks with acceptance criteria exist
- `in-progress` – currently being implemented (only one story at a time)

Rules:
- Tasks are only written when a story moves from `backlog` to `ready`.
- The user decides which story comes next; without guidance, take the next
  `ready` story in epic order.

### Initiatives

- Long-lived theme with a target picture: Why, Benefit, In scope / Out of scope,
  Epics, “Done when” (1–3 rough statements). Keep it short. No status label, no
  order, no progress value (GitHub's bar only counts direct children – ignore it).
- Without open epics an initiative is **resting** and stays open
  (`STATUS.md`: “Resting”).
- **Only the user creates and closes initiatives.** Claude proposes a new one, or
  closing one (all epics closed and “Done when” met), under “Open decisions” in
  `STATUS.md`.
- Follow-up work on a closed initiative = a **new** initiative with its own,
  outcome-based title (no “v2”) and “Related: #old”.

### Epics

- **Finite.** Outcome-based title, never “… II”, numbers or status words like
  “(later)” – status belongs in `STATUS.md`. Closed as soon as all its stories are
  closed; mention follow-up epics in the closing comment if any.
- **Exactly one initiative as parent**, chosen by main benefit. If an epic also
  fits a second one, write “See also: #nr” there. Attaching a closed epic to an
  open initiative is fine – it is not reopening.

### All levels

- **Closed stays closed.** Claude **never** reopens a closed issue – initiative,
  epic, story or task. New work on something done becomes a **new** issue with
  “Related: #nr”.
- **No orphans:** every story has exactly one epic, every epic exactly one
  initiative. Stories directly under an initiative are not allowed.
- **New idea:** `backlog` story in an **open** epic that pursues exactly this
  goal → otherwise a new epic in the matching initiative → otherwise propose a new
  initiative to the user. Claude creates stories and epics immediately (no
  blocking question) and lists every new epic in `STATUS.md` under “Open
  decisions” (“new – please confirm or re-sort”).

### Issue templates

Every issue says **what it is for**, **what it brings** and **when it is done**.
Templates: `.github/ISSUE_TEMPLATE/` (initiative, epic, story, task). Claude
writes issues via the API following the same outline.

- **Story:** Goal as “As a user I want …, so that …” (optional “Background:”),
  Description, Out of scope, **acceptance criteria from the user's view**
  (checkable when testing the APK; “When …, then …” for behaviour), Decisions,
  Tasks, `Epic: #nr`.
- **User task** (no code, e.g. storing a key): Goal “As the maintainer I want …”,
  the checklist is the acceptance criteria, Tasks “– (user task, no code)”.
  No `ready`/`in-progress` cycle; only the user closes it.
- **Task:** Purpose (which story criterion), Implementation, **technical
  acceptance criteria – each covered by at least one test whose name references
  it**, Depends on, `PR base:`, `Story: #nr`. Definition of done by reference, not copied.
- **Epic:** Outcome, Benefit, Scope / Out of scope, Stories (in order),
  “Done when” as a pointer to “Merging”, `Initiative: #nr`.
- No Gherkin (with TDD the tests are the given/when/then form).
- **Catching up:** backlog stories get the full template when they move to
  `ready`. Closed issues are never edited.

## Keeping the status (`STATUS.md`)

`STATUS.md` is the short summary of the project state. The user reads it as
context in a Claude project. It must always match the issues.

- Claude updates `STATUS.md` whenever any of it changes: a story changes status
  (`backlog`/`ready`/`in-progress`) or is closed, a new story, epic or initiative, order
  changes, a decision is made.
- Content: In progress · Up next · Backlog by initiative → epic (open epics
  with “x of y closed”, resting initiatives under “Resting”) · Recently done
  (max. 5, newest first) · Open decisions · “Last updated” date.
- When closing a story, the update belongs in the story's last PR. Pure status
  changes without a PR: direct commit to `main` (`docs: update status`).
- Keep it short: number + title, no task details.

## Workflow: Story → sub-issues

1. Every functional requirement is a **story** (issue with label `story`).
2. The story is split into **sub-issues** (label `task`), linked via GitHub's
   sub-issue feature. Each sub-issue is small enough for one PR and contains
   **acceptance criteria as testable statements**.
3. Independent sub-issues may be worked on in parallel (subagents).
   Dependencies are listed in the issue under “Depends on”.
4. The story is closed when all its sub-issues are closed.

## TDD per sub-issue (mandatory)

1. Branch `task/<issue-nr>-<short-name>` from the current `main`.
2. **Red:** First write tests for the acceptance criteria, commit
   (`test: … (#nr)`), push. CI must fail because of these tests.
3. **Green:** Write the minimal code until `flutter test` passes (`feat: … (#nr)`).
4. **Refactor:** Clean up, tests stay green (`refactor: … (#nr)`).
5. PR with `Closes #nr` in the body. Description: what, why, which tests.

## Merging

- Claude may **squash-merge PRs into `main` itself** once CI (analyze + test)
  is green. Never merge with red or running CI.
- Larger epics may be collected on a branch `epic/<name>`; it is merged into
  `main` only after green CI and a test by the user (APK on the phone).
- No direct push to `main` except for repo infrastructure (CI, issue templates, this file,
  `STATUS.md`).
- Delete the branch after merging.

## Tech

**Binding:** Before any work on `.dart` files, tests, `pubspec.yaml` or Android
configuration, load and follow the skill `.claude/skills/flutter-dart/SKILL.md`
(architecture, state, style, widgets, tests, definition of done).

- Flutter (stable), Dart, Android as the only target platform for now.
- Package name `green_friend`, organization `de.maestrodev`.
- Structure: `lib/domain` (pure Dart logic, no Flutter imports),
  `lib/data` (repositories, persistence, platform services), `lib/ui` (screens, widgets),
  `lib/l10n` (ARB files).
- Domain logic is pure Dart and covered by unit tests; UI by widget tests.
  Time is always passed in via an injectable `Clock`, never `DateTime.now()`
  directly in logic.
- Data access only through repository interfaces, so a backend or sync can be
  added later.
- Permissions: `POST_NOTIFICATIONS`; `SCHEDULE_EXACT_ALARM` only if needed; camera/gallery only with the journal epic.
- `flutter analyze` must report no issues.

## Environment note

Flutter cannot be installed in Claude's cloud environment (download servers
blocked). Tests therefore run via **GitHub Actions** (`.github/workflows/ci.yml`);
results are read via the GitHub API (on failure, CI posts the output as a
commit comment).

## Decisions made

- Plant database (#14): own curated care table, bundled offline (DE/EN), seeded from Open Plantbook (2026-09-30)
- Plant identification (#15): plant.id / Kindwise; API key entered by the user in the settings, never in the APK (2026-09-30)

## Open decisions (only the user decides)

- Household sync (#127): which service (e.g. Firebase, Supabase, self-hosted) – needs `INTERNET`, an account, possibly costs
- Android only, or iOS later?
- Weather for outdoor plants (#26, later): which service (e.g. Open-Meteo, Bright Sky / DWD, wetter.com API) – needs `INTERNET`, possibly an API key or paid plan; location entered manually or via GPS
