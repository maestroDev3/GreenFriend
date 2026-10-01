# Green Friend – texts to copy

## GitHub repository

- **Repository name:** `GreenFriend`
- **Description:** Plant care companion: watering reminders, care tips and a growth journal.
- **Topics:** `flutter` `dart` `android` `tdd` `greenfriend`

## Claude project

**Project name:** 🌿 Green Friend

**Project description:**
Android app (Flutter) for houseplants: watering and fertilizing reminders, light and care tips, and a growth journal with photos.

**Project instructions (custom instructions):**

```
This project belongs to the app “Green Friend” – Plant care companion: watering reminders, care tips and a growth journal.
Repository: github.com/maestroDev3/GreenFriend

- CLAUDE.md (working rules) and STATUS.md (current state) in the repo are authoritative.
  Read STATUS.md at the start of every conversation.
- Everything in the repo is English (code, UI, docs, issues, commits). You may talk
  to me in German.
- Planning runs through GitHub issues: Initiative → Epic → Story → Task (sub-issues),
  status labels backlog / ready / in-progress. New ideas become a backlog story in an
  open epic with exactly that goal, otherwise a new epic. Closed issues are never reopened.
- Implementation strictly TDD (red → green → refactor), one PR per task, squash-merge
  when CI is green.
- For Dart/Flutter work, the skill .claude/skills/flutter-dart/SKILL.md applies.
- Keep answers short and concrete. Never make the open decisions listed in STATUS.md
  yourself – present them to me.
```

**Project knowledge:** upload this ZIP (or `CLAUDE.md` and `STATUS.md`).

## First message to Claude (session with the repo attached)

```
The attached ZIP contains the starter files for Green Friend. Extract its contents
into the root of github.com/maestroDev3/GreenFriend (create the repo if it does not exist yet,
private, default branch main), commit ("chore: add working rules, skill and CI")
and push to main.
Then run the "First start" from CLAUDE.md: create labels, create epics and stories
from STATUS.md as issues (with sub-issues), run the Scaffold workflow, get CI green,
refine the first story and update STATUS.md with the issue numbers.
```
