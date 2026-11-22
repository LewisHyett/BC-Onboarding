# Project Memory

## 2026-11-22 — onboarding-framework architecture approved
- POC onboarding extension installed in each customer tenant. The Module and Task tables are per company, with one shared status per task.
- Extensibility comes from the `OnRegisterModules` integration event plus the public, idempotent `AddModule` and `AddTask` procedures. The standard BC modules, with Microsoft Learn URLs, are seeded through the same event.
- Guided Experience/Checklist was rejected. Single spec. IDs are allocated in 80000-80100.
- Architecture: `.claude/plans/onboarding-framework/onboarding-framework.architecture.md`

## 2026-11-22 — onboarding-framework revision 2 approved (nested tasks)
- `Onb. Task` gains a self-referencing `Parent Task Code`, plus Indentation and Sort Path, so the tasks part can use ShowAsTree. Nesting depth is unlimited.
- Group status is calculated from bottom-level tasks and never stored. Progress counts only bottom-level tasks. Mark Complete on a group completes the whole branch.
- `AddTask` now takes ParentTaskCode, and the parent must be registered first. New codeunit 80002 `Onb. Task Mgt.` handles the rollup and branch completion. A stored `Is Group` flag lets the module FlowFields count only bottom-level tasks.
- Mockup: https://claude.ai/artifact/7frbd882NZ5CHYY6Q1SDgM

## 2026-11-22 — onboarding-framework arch rev 3 and spec rev 2 approved
- Content is NFP finance only: 9 template modules (GL, DIM, BUD, AP, AR, BANK, FA, VAT, REP) with Learn links checked on 2026-11-22.
- Install starts blank. `Template` is part of the PK on Onb. Module and Onb. Task. Copy from Template refreshes the templates, the user picks modules, and only missing tasks are added. Users can also build modules and tasks themselves.
- The event is `OnRegisterTemplates`, and `AddTemplateModule`/`AddTemplateTask` skip a code owned by someone else. There is one permission set, ONB ALL (RIMD). There is no Test app, so checks T01–T17 are manual.
- Next: /aldc:develop, then /aldc:review (the Conductor isn't used because there are no tests).

## 2026-11-22 — onboarding-framework implemented (spec rev 2)
- All 12 objects in spec §2 are under `src/`. The app compiles with CodeCop, UICop and PerTenantExtensionCop with no errors or warnings. T01–T17 have not been run.
- Deviation from the spec: descendants, rollup, branch completion and delete find children through `Parent Task Code` recursion, not a Sort Path prefix. Siblings that share a Sequence get the same Sort Path, so a prefix match would mix their sub-trees, and a prefix delete could remove another task's children.
- `RefreshTemplates` passes `this` through a local codeunit variable, because AL can't pass `this` as a var argument (AL0130).
- Next: deploy to a sandbox, run the manual checks T01–T17, then /aldc:review.
- Added on 2026-11-22 at the user's request: install codeunit 80003 `Onb. Install` calls `RefreshTemplates` in `OnInstallAppPerCompany`. This loads the template modules on install, while live modules still start empty. T01 now expects the templates to be there without pressing Refresh. ONB ALL includes the new codeunit.

## 2026-11-22 — single onboarding page (spec rev 3 note)
- At the user's request, the Module table and the 4 pages were replaced. Modules are now top-level `Onb. Task` rows, and page 80000 `Onb. Onboarding` is a single editable tree (SetTemplateMode turns it into the template view). The public registry API is unchanged. The details are in spec §0. The app compiles with no warnings, and the checks have not been run.
- Superseded the same day: the user wants a **list of onboardings and a card per onboarding**. Table 80000 `Onb. Onboarding` is the header. `Onb. Task` is keyed by (Template, Onboarding Code, Task Code) and keeps Assigned To. The pages are Onboarding List 80000, Card 80001, Tasks part 80002 and Template Tasks 80003. Select Modules on the card applies templates. The details are in spec §0. The app compiles with no warnings, and the checks have not been run.
- Later on 2026-11-22: templates now have their own list and card. 80003 `Onb. Template List` shows top-level template rows and is also the Select Modules lookup. 80004 `Onb. Template Card` has the header, and 80005 `Onb. Template Lines` is a ListPart tree linked by the new `Onb. Task` field 21 `Module Code`, which UpdateHierarchy maintains as the top-level ancestor. Users can add their own lines under provider templates. Those lines have no Source App ID, survive Refresh and are copied by Select Modules. Provider rows stay read-only on the page. The old tree page `Onb. Template Tasks` is removed.
- Ordering decision on 2026-11-22: Sequence stays as an internal field (tree Sort Path and the public API need it) but is hidden on every page (Visible = false). Users order lines with Move Up/Down, on both the template lines and the onboarding tasks; provider template lines can't be moved. New places a line next to the selected one (same parent, through `GetInsertSequence`); with no gap it falls back to the end of that level. `MoveTask` reuses `GetInsertSequence` and only swaps when there is no gap.
- 2026-11-22: the provider read-only guard (R-07) is dropped at the user's request. Every template line and header can now be edited. Field 22 `Customized` is set by `Onb. Task` OnModify when a provider row is changed (the registry uses Modify(false), so its own updates never set it). Refresh then leaves customized rows alone. Provider rows still can't be deleted, because Refresh would re-add them.

## 2026-11-22 — rebuilt from scratch (spec section 00, revision 4)
- The user was unhappy with the incremental version and asked for a rebuild that keeps every decision. The old source is backed up in `.snapshots/src-before-rebuild-2026-11-22.tgz`.
- The new model uses BC document patterns: Template and Onboarding header tables plus one shared `Onb. Line` table with Document Type. The tree comes from line order and Indentation (Job Task style), with AutoSplitKey, Indent/Outdent and Move Up/Down (MoveBlock keeps SystemId).
- Standard templates are created only when missing. After that they belong to the customer and are fully editable, and Reset to Standard recreates one. Select Modules copies templates as modules and only adds missing lines, matched by Template Line ID.
- The app compiles with no warnings. Checks R1–R8 have not been run. The sandbox needs its data cleared because the schema is new.
- 2026-11-22: the user couldn't add template lines. Suspected cause is the collapsible tree view (ShowAsTree), which appears to block inline inserts, though Learn doesn't confirm it either way. Both line parts now use fixed indentation (IndentationColumn + IndentationControls = Description), like BC's Job Task lines. This loses expand/collapse. Not yet confirmed in the sandbox.
- 2026-11-22: `Onb. Line` gained 25 "Planned Start Date" and 26 "Planned End Date". The end date can't be before the start date. They show on the onboarding subform only and aren't copied from templates. They're meant as the data source for a future Gantt chart control add-in, which isn't built yet.
- 2026-11-22: two planning additions.
  - Group and module dates are calculated, not stored: `GetPlannedDates` returns the earliest start and latest end of the tasks below.
  - `Onb. Line` field 27 "Duration (Days)" is shown on template and onboarding lines and copied by Select Modules. The onboarding header gained 4 "Start Date". **Plan Dates** (on the onboarding card) overwrites the dates of every task. Modules run in parallel from the Start Date, and tasks inside a module run sequentially. It uses calendar days with a minimum of 1 per task, and no base calendar.
- 2026-11-22: Gantt chart added. Controladdin `Onb. Gantt` (`src/Gantt/js`, plain SVG, no external libraries, read-only) sits on CardPart 80006 `Onb. Gantt Part`, shown as part "Plan" on the onboarding card. Tasks are coloured by status, groups get thin dark bars spanning their tasks, and a dashed line marks today. Data is resent in the part's OnAfterGetCurrRecord. Clicking or dragging bars is not built.
- 2026-11-22: Gantt fixes. The chart measured a width of 0 before layout, so it was drawn small with overlapping labels. It now uses the window width as a fallback, redraws after 200ms and on resize, fills the width, and spaces its labels. The panel height is 520. New page 80007 `Onb. Plan` shows the chart full screen through the card action "Plan (Full Screen)". The Gantt data builder moved to `Onb. Line Mgt.`.GetGanttData.
- 2026-11-22: the Gantt got a zoom toolbar (Fit / Days 40px / Weeks 14px / Months 4px per day) and a scroll area sized from window.innerHeight, so long plans scroll both ways. The user's plan was only about a week long because no durations were set (every task counts as 1 day, and modules run in parallel).
- 2026-11-22: the full-screen plan page 80007 `Onb. Plan` is now PageType UserControlHost (runtime 15+). The client gives it all available space, but it allows no actions, no Refresh and only one usercontrol. The card passes the onboarding code with `SetOnboardingCode` and then calls Run. The chart toolbar has a "Full screen" button that uses the browser Fullscreen API. It only shows when `document.fullscreenEnabled` is true, which depends on BC's iframe allowing it.
