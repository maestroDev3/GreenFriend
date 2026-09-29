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
plant develops. Later: plant identification from a photo.
Domain terms:

- **Plant** – `Plant` – name, species, location, intervals, photo
- **Care task** – `CareTask` – water, fertilize, repot (sealed class `CareKind`)
- **Care log** – `CareLog` – when which task was done
- **Journal entry** – `JournalEntry` – date, note, optional photo

## Structure: Epic → Story → Task

Everything lives in GitHub issues, linked via sub-issues:

| Level | Label | Content |
|---|---|---|
| Epic | `epic` | Big goal; stories as sub-issues, order listed in the description |
| Story | `story` | User-visible feature; tasks as sub-issues |
| Task | `task` | Exactly one PR, TDD, testable acceptance criteria |

Story status (label, exactly one; done = closed):
- `backlog` – idea, roughly described, **no tasks yet**
- `ready` – refined, tasks with acceptance criteria exist
- `in-progress` – currently being implemented (only one story at a time)

Rules:
- Tasks are only written when a story moves from `backlog` to `ready`.
- New ideas from the user become a `backlog` story in the matching epic.
- The user decides which story comes next; without guidance, take the next
  `ready` story in epic order.

## First start (once)

While there are no issues yet:
1. Create labels: `epic`, `story`, `task`, `backlog`, `ready`, `in-progress`.
2. Create the epics and stories from `STATUS.md` (“Planned epics”) as issues,
   stories as sub-issues of their epic, all stories `backlog`.
3. Run the **Scaffold** workflow (`.github/workflows/scaffold.yml`) via
   `workflow_dispatch` → generates the Flutter project. CI must be green afterwards.
4. Refine the first story of the “Foundation” epic to `ready`.
5. Update `STATUS.md` with the real issue numbers.

## Keeping the status (`STATUS.md`)

`STATUS.md` is the short summary of the project state. The user reads it as
context in a Claude project. It must always match the issues.

- Claude updates `STATUS.md` whenever any of it changes: a story changes status
  (`backlog`/`ready`/`in-progress`) or is closed, a new story or epic, order
  changes, a decision is made.
- Content: In progress · Up next · Backlog by epic · Recently done (max. 5,
  newest first) · Open decisions · “Last updated” date.
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
- No direct push to `main` except for repo infrastructure (CI, this file,
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

## Open decisions (only the user decides)

- Plant identification: which service (e.g. Pl@ntNet, Plant.id) – needs `INTERNET` and possibly an API key
- Android only, or iOS later?
