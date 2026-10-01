# Decision record: planning structure

**Levels:** Initiative → Epic → Story → Task · **Tool:** GitHub issues with sub-issues · **Date:** 2026-10-01

## Context

One developer, one autonomous Claude agent, all planning in GitHub issues, `STATUS.md` as the summary.
With three levels (Epic → Story → Task) epics were used as theme folders:

- Epic #16 “Data safety” was closed, then reopened by the agent to hang #111 under it; #5 was reopened the same way.
- The root cause was the rule “new ideas become a backlog story in the matching epic” – it leaves the agent a judgment call and does not forbid reopening.
- #128 “Calendar, pruning and more species” became a grab-bag because there was no permanent home for new work.

## Decision

1. Four levels: Initiative → Epic → Story → Task, linked via native sub-issues, told apart by labels (personal account, no issue types).
2. Initiatives are long-lived themes; without open epics they rest. Only the user creates and closes them.
3. Epics are finite and outcome-titled; closed when all stories are closed.
4. Closed stays closed on every level; new work is a new issue with “Related: #nr”.
5. No orphans: every story has one epic, every epic one initiative.
6. Every issue follows a template in `.github/ISSUE_TEMPLATE/` (what for, benefit, done when).

Rules in full: `CLAUDE.md`, section “Structure”.

## Adaptations to the original package

Reviewed by two independent agents (Fable and Opus) over two rounds; both: adopt with adaptations.

- English throughout; `STATUS.md` keeps its name.
- Each acceptance criterion is covered by **at least one** test (not exactly one – widget tests often cover several).
- User tasks without code (e.g. #111) are stories with “As the maintainer …”, a checklist as criteria, no tasks; only the user closes them.
- Task template gains `PR base:` (main or `epic/<name>`); epic “Done when” points to CLAUDE.md “Merging”.
- The agent never creates initiatives itself (project rule: the user makes product decisions); it may create epics and flags them in `STATUS.md`.
- No status words in titles (“(later)” removed from #31).
- Markdown templates instead of issue forms (forms are ignored when the agent creates issues via the API); no Gherkin (TDD tests already are given/when/then).

## Rejected alternatives

| Alternative | Why rejected |
|---|---|
| Epics as permanent clusters that reopen | Judgment call for the agent; “closed” loses its meaning, progress jumps back |
| Theme labels (`area:…`) on stories | Double bookkeeping next to the hierarchy |
| Stories without an epic | No order, no progress, easily lost |
| Successors named “v2” / “… II” | Says nothing about the goal |
| New epics only after asking | Blocks the autonomous agent; instead create and flag |

## Sources

- Atlassian – Epics, stories, themes: https://www.atlassian.com/agile/project-management/epics-stories-themes
- Linear – Initiatives: https://linear.app/docs/initiatives
- GitHub Docs – Sub-issues: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues
- GitHub Docs – Issue forms: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms
