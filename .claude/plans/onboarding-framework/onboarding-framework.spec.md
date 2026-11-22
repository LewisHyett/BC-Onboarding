# onboarding-framework — Technical Specification

**Version:** 4 (rebuild, see section 00, which supersedes everything below where it differs)
**Complexity:** MEDIUM
**Status:** Approved
**Approval:** the user approved revision 2 together with architecture revision 3 in session on 2026-11-22. Revision 1 was approved on 2026-11-22 and is superseded by the changes in architecture revision 3 (blank install, templates, build yourself, one permission set)

> **Skills applied**: skill-events, skill-pages, skill-permissions, skill-testing
> **BCQuality**: not consulted (BCQuality plugin not installed)

## 00. Revision 4: rebuild (user decision, 2026-11-22). This supersedes §0 and §1–§12 wherever they differ

The user asked for a rebuild from scratch that keeps every earlier decision. The app now follows standard BC document patterns.

**Objects**
| Type | ID | Name | Purpose |
| --- | --- | --- | --- |
| Enum | 80000 | Onb. Task Type | Read, Test (extensible) |
| Enum | 80001 | Onb. Task Status | Not Started, In Progress, Completed, Not Applicable |
| Enum | 80002 | Onb. Document Type | Template, Onboarding |
| Table | 80000 | Onb. Template | Template header: Code, Description, Learn URL, Sequence (hidden; it orders the list), Source App ID/Name |
| Table | 80001 | Onb. Onboarding | Onboarding header: Code, Description, User ID (caption Onboarding For) |
| Table | 80002 | Onb. Line | Lines for both headers. PK (Document Type, Document Code, Line No.). Holds Description, Type, Indentation, Instructions, Learn URL, Task Code (provider id), Template Code + Template Line ID (where an onboarding line was copied from), Status, Completed By/At, Notes, Assigned To |
| Codeunit | 80000 | Onb. Template Registry | OnRegisterTemplates event; AddTemplateModule, AddTemplateTask, RefreshTemplates, ResetTemplate |
| Codeunit | 80001 | Onb. Std. Templates | NFP finance content (§4a: 9 templates, 40 lines) |
| Codeunit | 80002 | Onb. Line Mgt. | Tree logic, rollup, progress, Indent/Outdent, MoveBlock, CopyTemplates, Learn links |
| Codeunit | 80003 | Onb. Install | Loads the standard templates on install |
| Page | 80000–80002 | Onboarding List / Card / Subform | Onboardings |
| Page | 80003–80005 | Template List / Card / Subform | Templates |
| PermissionSet | 80000 | ONB ALL | RIMD on the 3 tables, plus X on every object |

**Rules**
- **The tree comes from line order and Indentation, as in Job Tasks.** A line's children are the lines straight after it with a higher Indentation. A line that has children is a group. Group status and progress are calculated, never stored. Indentation can't be edited directly: Indent and Outdent move a line together with the lines under it. A line can be at most one level deeper than the line above it, and at most 10 levels deep.
- **Order is the line order.** Subforms use AutoSplitKey, so New inserts a line where you are. A new line takes the level of the line next to it, or becomes the first sub-task when inserted directly below a group. Move Up/Down swaps a line (with its sub-tasks) with its neighbour at the same level. Lines keep their SystemId when moved. Users never see a sequence.
- **Templates:**
  - Every template and every template line can be edited, and users can add lines for a specific customer.
  - The standard templates are created on install, and with **Get Standard Templates** only for codes that don't exist yet. Existing templates are never overwritten.
  - **Reset to Standard** (on standard templates only) deletes the template and creates it again from its provider.
- **Onboardings:**
  - **Select Modules** takes the templates you pick from the template list and adds each one as a module. The module is a top-level line, with the template lines one level below it.
  - Running it again for a module that already exists adds only the template lines that are missing (matched by Template Line ID), each placed after the line copied from the template line before it. Status, Notes and lines the user added are never touched.
- **Several people:** create one onboarding per person (Onboarding For), or share one and use Assigned To. Assigning a group also assigns the tasks under it that were unassigned or assigned to the same person, and a new line inherits its parent's assignee. My Tasks filters to UserId.
- **Public API changes:** this is not released yet, so the API could change. `AddTemplateTask` no longer takes Sequence, and lines are added in call order. A blank ParentTaskCode now means the top level of the template. AddTemplateTask is ignored for templates that already existed before this refresh.
- **Removed from earlier revisions:** the Sequence and Parent Task Code columns, the Customized flag, provider read-only rows, the skip-on-conflict message, and the automatic refresh on Select Modules.

**Manual checks (all not-run)**
- R1: After install, Onboarding Templates lists GL..REP and Onboardings is empty.
- R2: A new onboarding card is empty. Select Modules GL+DIM shows modules with their trees fully expanded, and the message says 2 modules, 10 tasks added.
- R3: Complete one GL task, delete another, add your own task, then select GL again. Only the deleted task comes back, in its place, and the status and your task are unchanged.
- R4: Indent, Outdent and Move Up/Down on a group move its sub-tasks with it. Indenting past the line above gives an error.
- R5: Edit a GL template line and add a line, then press Get Standard Templates. Nothing changes. Reset to Standard restores the original.
- R6: Group status and Mark Complete on a group work as in rev 2 T05/T07.
- R7: Two onboardings select GL and keep independent statuses. Assigned To propagates down, and My Tasks filters to the user's tasks.
- R8: Learn URL 'http://x' gives an error. Open Learn falls back to the parent's link and then the template's.

## 0. Revision 3 change note (user decision, 2026-11-22)

The user asked for a single onboarding page, with modules shown as tasks and new tasks added in the same place, instead of one card per module. Where this note conflicts with sections 2–7, the note wins.

- **Data:** table 80000 `Onb. Module` is removed. A module is now a top-level row in `Onb. Task` (Parent Task Code is blank). `Onb. Task` drops `Module Code` and gains 17 `Source App ID` and 18 `Source App Name`. The PK is now (Template, "Task Code"), and Key2 is (Template, "Sort Path"). Task codes must be unique across the whole onboarding.
- **Pages:** pages 80000–80003 are replaced by one page, 80000 `Onb. Onboarding`. It is an editable List with ShowAsTree that starts collapsed. `SetTemplateMode(true)` turns the same page into **Onboarding Templates**. Its actions are Apply Template (replacing Copy from Template), Mark Complete, Open Learn, Onboarding Templates and Refresh Templates. An empty onboarding shows a notification pointing to Apply Template. Provider template rows are read-only and can't be deleted from the page.
- **Applying templates:** Apply Template refreshes the templates, commits, then opens the template page in lookup mode, showing top-level rows only. `CopyFromTemplate(var TemplateTask: Record "Onb. Task")` copies each selected module and its sub-tree, adding only codes that don't already exist live.
- **Learn links:** Open Learn falls back to the nearest parent that has a link.
- **Public contract:** `OnRegisterTemplates`, `AddTemplateModule` and `AddTemplateTask` keep their signatures. A module is registered as a top-level template task. A blank ParentTaskCode in AddTemplateTask now places the task under the module. Ownership is checked per code, and a conflicting module or task code is skipped and reported.
- **Progress:** the module FlowFields and Progress % are removed. Progress shows as Group Status on group rows.
- **Install:** install codeunit 80003 `Onb. Install` loads the templates on install.
- **Tests:** T02, T03, T08, T14, T15 and T17 must be re-read against the single page.
- **Onboarding list and card (user decision, which supersedes the single page and the "Onboarding For" key):**
  - **New table 80000 `Onb. Onboarding`:** Code (PK, NotBlank), Description, "User ID" (caption Onboarding For, optional, EUII), and FlowFields No. of Tasks, Completed Tasks and Not Applicable Tasks, which count live leaves with this Onboarding Code. OnDelete deletes its tasks. Rename is blocked. It has `GetProgressPct()`.
  - **`Onb. Task` changes:** it gains 19 `Onboarding Code` (Code[20], relation to the header, blank for templates), and the PK becomes (Template, "Onboarding Code", "Task Code"). Task codes must be unique within one onboarding. It also gains 20 `Assigned To` (Code[50], EUII, lookup to User). Assigning a row also assigns the descendants that were blank or held the previous assignee, and a new row inherits its parent's assignee.
  - **Pages:**
    - 80000 `Onb. Onboarding List` (Onboardings, searchable), with a navigation action to Onboarding Templates.
    - 80001 `Onb. Onboarding Card`: Code, Description, Onboarding For, Progress %, and a **Select Modules** action. Select Modules refreshes the templates, commits, opens a lookup of top-level templates, then runs `CopyFromTemplate(var TemplateTask; OnboardingCode)`.
    - 80002 `Onb. Onboarding Tasks`: a ListPart tree with SubPageLink Template = const(false) and Onboarding Code = field(Code). Its actions are Mark Complete, Open Learn and My Tasks.
    - 80003 `Onb. Template List` (Onboarding Templates, searchable) lists the template modules and is the Select Modules lookup. 80004 `Onb. Template Card` has the header fields, and part 80005 `Onb. Template Lines` shows the editable tree below the module, linked by new field 21 `Module Code` (top-level ancestor, maintained by UpdateHierarchy). New lines default to sitting under the module. Users can add their own lines to provider templates: those lines survive Refresh and are copied by Select Modules. Provider rows are read-only and can't be deleted.
  - **Several people:** create one onboarding per person (Onboarding For) or a shared one, and use Assigned To and My Tasks within a shared one.
  - **New tests:**
    - (a) Two onboardings each select GL, and their statuses stay independent.
    - (b) Assign GL to a user. The GL tasks follow, except those already assigned to someone else, and My Tasks filters to them.
    - (c) Deleting an onboarding deletes its tasks.
  - ONB ALL is RIMD on both tables.

## 1. Overview

This is a POC onboarding framework, installed in each new not-for-profit customer's Business Central tenant. It **starts blank**. Users either **copy modules from templates** or **build modules and nested tasks themselves**. A template is a module with **Template** ticked. The app ships a template set for the financial side of Business Central aimed at NFP customers (§4a). Third-party extensions add template modules through `OnRegisterTemplates`.

- **Architecture**: `.claude/plans/onboarding-framework/onboarding-framework.architecture.md`, **revision 3** (Approved). Covers TD-01..TD-09 and AC-01..AC-09.
- **Unit**: single spec, SPEC-01.
- **In scope**: all objects in §2.
- **Out of scope**: multi-customer tracking, per-user progress, reports, Role Center cue, translations, removing template rows that providers no longer register, and a split into Admin and User permission sets.
- **Human decisions carried over**: no Test app (Q-01, so all checks are manual and reported `not-run`); providers only write to their own modules (Q-02); the content in §4a is approved (Q-03); templates are a flag on the module header; Copy from Template lets the user pick modules; re-copy adds only missing tasks; one permission set.

| Dependency type | Predecessor / contract consumed | Required revision / actual approval reference | Availability and effect |
| --- | --- | --- | --- |
| None | — | — | Single unit |

| Shared resource / contract | Owner / approved allocation | Consumers | Change or coordination issue |
| --- | --- | --- | --- |
| App IDs 80000–80003 (range 80000–80100) | Architecture revision 3 §14 | SPEC-01 | None. The project has no AL objects yet |
| `OnRegisterTemplates`, `AddTemplateModule`, `AddTemplateTask` | SPEC-01 | Third-party apps | Public contract. After release, change it only by adding to it |

### Governing sources

- `${CLAUDE_PLUGIN_ROOT}/docs/templates/spec-template.md`
- `${CLAUDE_PLUGIN_ROOT}/rules/al-code-style.md`
- `${CLAUDE_PLUGIN_ROOT}/rules/al-error-handling.md`
- `${CLAUDE_PLUGIN_ROOT}/rules/al-events.md`
- `${CLAUDE_PLUGIN_ROOT}/rules/al-guidelines.md`
- `${CLAUDE_PLUGIN_ROOT}/rules/al-naming-conventions.md`
- `${CLAUDE_PLUGIN_ROOT}/rules/al-security.md`
- `${CLAUDE_PLUGIN_ROOT}/rules/al-testing.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/skill-events/SKILL.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/skill-pages/SKILL.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/skill-permissions/SKILL.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/skill-testing/SKILL.md`
- `app.json` (application 29.0.0.0, runtime 18.0, idRanges 80000–80100, NoImplicitWith)
- Learn: ShowAsTree, IndentationColumn and TreeInitialState properties; Designing Indented Hierarchy Lists
- Learn: NavApp.GetCallerModuleInfo, NavApp.GetCurrentModuleInfo, ModuleInfo data type

## 2. AL Object Inventory

| Project / app ID | Type | ID | Name | Repo-relative path | Extends / source | Purpose / decision |
| --- | --- | --- | --- | --- | --- | --- |
| App | Enum | 80000 | Onb. Task Type | `src/Task/OnbTaskType.Enum.al` | — | Read, Test. Extensible |
| App | Enum | 80001 | Onb. Task Status | `src/Task/OnbTaskStatus.Enum.al` | — | Not Started, In Progress, Completed, Not Applicable. Not extensible |
| App | Table | 80000 | Onb. Module | `src/Module/OnbModule.Table.al` | — | Live and template modules (TD-07) |
| App | Table | 80001 | Onb. Task | `src/Task/OnbTask.Table.al` | — | Nested tasks (TD-06) |
| App | Codeunit | 80000 | Onb. Module Registry | `src/Registry/OnbModuleRegistry.Codeunit.al` | — | Event and template upsert API (TD-01) |
| App | Codeunit | 80001 | Onb. Std. Modules Handler | `src/StandardContent/OnbStdModulesHandler.Codeunit.al` | Subscribes to `OnRegisterTemplates` | NFP finance templates (TD-05) |
| App | Codeunit | 80002 | Onb. Task Mgt. | `src/Task/OnbTaskMgt.Codeunit.al` | — | Hierarchy, rollup, branch completion, copying, Learn links |
| App | Page | 80000 | Onb. Module List | `src/Module/OnbModuleList.Page.al` | — | Live modules. Entry point through Search |
| App | Page | 80001 | Onb. Module Card | `src/Module/OnbModuleCard.Page.al` | — | Card for both live and template modules |
| App | Page | 80002 | Onb. Task Part | `src/Task/OnbTaskPart.Page.al` | — | Editable task tree |
| App | Page | 80003 | Onb. Template List | `src/Module/OnbTemplateList.Page.al` | — | Template modules, plus the multi-select lookup for copying |
| App | PermissionSet | 80000 | ONB ALL | `src/Permissions/OnbAll.PermissionSet.al` | — | The only set (TD-09) |

There is no Test app (Q-01).

## 3. Data Contracts

### Enums
80000 "Onb. Task Type" (Extensible = true): Read = 0, Test = 1.
80001 "Onb. Task Status" (Extensible = false): "Not Started" = 0, "In Progress" = 1, Completed = 2, "Not Applicable" = 3.

### Table 80000 "Onb. Module" (DataPerCompany; LookupPageId = Onb. Template List)
| Field | Type / relation | Classification | Validation / default | Observable error or outcome |
| --- | --- | --- | --- | --- |
| 1 Code | Code[20], PK2, NotBlank | CustomerContent | — | Standard blank-key error |
| 2 Description | Text[100] | CustomerContent | — | — |
| 3 Sequence | Integer, MinValue 0 | CustomerContent | 0 | — |
| 4 "Source App ID" | Guid | CustomerContent | Set only by the registry. Copying carries it over for information | — |
| 5 "Source App Name" | Text[250] | CustomerContent | Same as Source App ID | — |
| 6 "Learn URL" | Text[2048], ExtendedDatatype URL | CustomerContent | Blank, or starts with `https://` (case-insensitive) | `InvalidUrlErr`: "The link %1 must start with https://." |
| 7 Template | Boolean, **PK1** | CustomerContent | Set at insert | Changing it means a rename, which is blocked (see below) |
| 10 "No. of Tasks" | FlowField: Count(Onb. Task where Template = field(Template), "Module Code" = field(Code), "Is Group" = const(false)) | — | Not editable | Counts leaf tasks only |
| 11 "Completed Tasks" | FlowField: same filter, Status = const(Completed) | — | | |
| 12 "Not Applicable Tasks" | FlowField: same filter, Status = const("Not Applicable") | — | | |

- **Keys**: PK(Template, Code); Key2(Template, Sequence).
- **OnRename**: error `RenameNotAllowedErr`: "You can't rename module %1. Create a new module and copy or rebuild its tasks." Neither Template nor Code can change after insert.
- **OnDelete**: deletes all tasks with the same Template and Module Code.
- **Procedure `IsProviderTemplate(): Boolean`**: returns Template and not IsNullGuid("Source App ID"). Pages use it for read-only mode (R-07). This is a page-level guard, not a security boundary: the user holds RIMD, and the next refresh restores provider content anyway.

### Table 80001 "Onb. Task" (LookupPageId = Onb. Task Part)
| Field | Type / relation | Classification | Validation / default | Observable error or outcome |
| --- | --- | --- | --- | --- |
| 1 "Module Code" | Code[20], PK2, TableRelation "Onb. Module".Code where(Template = field(Template)) | CustomerContent | NotBlank | — |
| 2 "Task Code" | Code[20], PK3, NotBlank | CustomerContent | — | — |
| 3 "Parent Task Code" | Code[20], TableRelation "Onb. Task"."Task Code" where(Template = field(Template), "Module Code" = field("Module Code")) | CustomerContent | OnValidate → Task Mgt.UpdateHierarchy | Hierarchy errors (§4) |
| 4 Description | Text[250] | CustomerContent | — | — |
| 5 Sequence | Integer, 0..99999 | CustomerContent | OnValidate → UpdateHierarchy. If 0 at insert: highest sibling Sequence + 10 | — |
| 6 Type | Enum "Onb. Task Type" | CustomerContent | Ignored on group rows | — |
| 7 Instructions | Text[2048] | CustomerContent | — | — |
| 8 "Learn URL" | Text[2048], ExtendedDatatype URL | CustomerContent | https rule | `InvalidUrlErr` |
| 9 Status | Enum "Onb. Task Status" | CustomerContent | OnValidate. On a template row → `TemplateStatusErr`: "Status can't be set on template tasks." On a group row → `GroupStatusErr`: "The status of %1 is calculated from its sub-tasks and can't be changed." Unchanged → no-op. Completed → stamp. Any other value → clear the stamps | Errors as given |
| 10 "Completed By" | Code[50] | **EndUserIdentifiableInformation** | Set only by Status (UserId) | Not editable |
| 11 "Completed At" | DateTime | CustomerContent | Set only by Status (CurrentDateTime) | Not editable |
| 12 Notes | Text[2048] | CustomerContent | — | — |
| 13 Indentation | Integer 0..9 | CustomerContent | Maintained | Not editable |
| 14 "Is Group" | Boolean | CustomerContent | Maintained: true while any task names this one as its parent | Not editable |
| 15 "Sort Path" | Text[250] | CustomerContent | Maintained: parent Sort Path + `Format(Sequence, 0, '<Integer,5><Filler Character,0>') + '.'` | Not editable |
| 16 Template | Boolean, **PK1** | CustomerContent | Inherited from the module (from the part's SubPageLink, or set by code) | — |

- **Keys**: PK(Template, "Module Code", "Task Code"); Key2(Template, "Module Code", "Sort Path").
- **OnInsert**: applies the Sequence default, then calls UpdateHierarchy.
- **OnRename**: `RenameNotAllowedErr`, with task wording.
- **OnDelete**: deletes descendants (same Template and Module Code, Sort Path starting with this task's Sort Path), then recalculates the parent's Is Group.

**Invariants**
- **I-1**: A task's parent is in the same Template and Module, is not the task itself, and is not one of its descendants.
- **I-2**: Indentation ≤ 9 (at most 10 levels).
- **I-3**: Is Group is true exactly when the task has children. Group rows never have their Status validated.
- **I-4**: Neither copying nor template refresh changes Status, Notes, Completed By or Completed At on **live** rows. Template refresh touches template rows only.
- **I-5**: Sort Path and Indentation always match the parent chain and Sequence values.
- **I-6**: Template rows always have Status = Not Started and no stamps.

## 4. Procedure Contracts

Every error and message text is a `Label` with a Comment. URLs are `Locked = true` labels.

| Owning object / procedure | Inputs | Return / outputs | Preconditions | Side effects / errors | Consumers / acceptance |
| --- | --- | --- | --- | --- | --- |
| Registry 80000 `procedure RefreshTemplates()` | — | — | — | Clears the skipped-codes list, then raises `OnRegisterTemplates(this codeunit)`. No Commit inside. An error in a subscriber rolls back the refresh | Copy from Template, Refresh Templates. AC-01, AC-05 |
| Registry `procedure GetSkippedModules(): List of [Code[20]]` | — | Codes skipped in the last refresh | — | Read only | Template List and Copy action message |
| Registry `procedure AddTemplateModule(ModuleCode: Code[20]; Description: Text[100]; Sequence: Integer; LearnUrl: Text[2048]): Boolean` | by value | true when written, false when skipped | — | Gets the caller with `NavApp.GetCallerModuleInfo`, **called directly in this procedure body** (V-02). Template module missing → insert with Template = true and Source App ID = caller Id. Source App Name = `StandardSourceLbl` 'Business Central' when caller Id = current module Id, otherwise the caller's Name. Exists with the same Source App ID → update Description, Sequence and Learn URL. Exists with another or null Source App ID (another provider, or a user-built template) → **skip**: add the code to the skipped list and return false, with no error, so one conflict can't block every copy | AC-05, R-02 |
| Registry `procedure AddTemplateTask(ModuleCode: Code[20]; ParentTaskCode: Code[20]; TaskCode: Code[20]; Description: Text[250]; Sequence: Integer; TaskType: Enum "Onb. Task Type"; Instructions: Text[2048]; LearnUrl: Text[2048]): Boolean` | by value | true when written, false when skipped | Parent registered first | Caller check as above. Template module missing or not owned by the caller → return false (it's already in the skipped list, or `ModuleMissingErr` when it was never registered). Otherwise upsert the template task: insert, or update the descriptive fields and the parent. The hierarchy goes through UpdateHierarchy, so hierarchy errors raise (a provider bug) | AC-05 |
| Registry `[IntegrationEvent(false, false)] local procedure OnRegisterTemplates(var Registry: Codeunit "Onb. Module Registry")` | — | — | — | Subscribers call AddTemplateModule and AddTemplateTask on `Registry` | TD-01 |
| Task Mgt. 80002 `procedure UpdateHierarchy(var OnbTask: Record "Onb. Task")` | var | — | — | Parent missing → `ParentMissingErr`: "Parent task %1 doesn't exist in module %2." Breaks I-1 → `ParentCycleErr`: "Task %1 can't be placed under one of its own sub-tasks." Breaks I-2 → `TooDeepErr`: "Task %1 is nested more than 10 levels deep." Otherwise recalculates Indentation and Sort Path for the task and its descendants, sets the new parent's Is Group = true, and recalculates the old parent's Is Group | Table triggers, registry, copy. AC-07, AC-08 |
| Task Mgt. `procedure CopyFromTemplate(var TemplateModule: Record "Onb. Module")` | var: a filtered set (Template = true) | — | Every record has Template = true, else `NotTemplateErr` | For each module: live module (Template = false, same Code) missing → insert it, copying Description, Sequence, Learn URL, Source App ID and Name. Then walk the template tasks in Sort Path order (parents first). Live task with the same Task Code exists → skip it. Otherwise insert a copy with Status Not Started and no Notes or stamps, keeping the Parent Task Code, then run UpdateHierarchy. Ends with `CopyResultMsg`: "%1 modules copied. %2 tasks added, %3 already present." | AC-01, AC-06 (TD-08) |
| Task Mgt. `procedure GetRollupStatus(OnbTask: Record "Onb. Task"): Enum "Onb. Task Status"` | — | Status | — | Not a group → its own Status. A group → looks at the leaves under it (same Template and Module, Sort Path prefix, Is Group = false). All Completed or Not Applicable → Completed. Any leaf other than Not Started → In Progress. Otherwise → Not Started | AC-07 |
| Task Mgt. `procedure GetLeafProgress(OnbTask: Record "Onb. Task"; var Done: Integer; var Total: Integer)` | var outputs | Done = Completed leaves. Total = leaves that aren't Not Applicable | — | Read only | Task Part |
| Task Mgt. `procedure CompleteBranch(var OnbTask: Record "Onb. Task")` | var | — | Not a template row, else `TemplateStatusErr` | A leaf → Validate Status Completed and Modify, unless already Completed or Not Applicable. A group → does the same for every open leaf under it | Task Part |
| Task Mgt. `procedure OpenLearn(OnbTask: Record "Onb. Task")` | — | — | — | Opens the task's URL with Hyperlink, otherwise the module's URL, otherwise `NoLearnLinkErr`: "No Microsoft Learn link is set for %1." | AC-02 |
| Std. Modules Handler 80001, subscriber on `OnRegisterTemplates` | `var Registry: Codeunit "Onb. Module Registry"`, matching the publisher exactly | — | — | Registers §4a, each parent before its children. No Commit | AC-01 |

### 4a. Standard template content (NFP finance)

L = `https://learn.microsoft.com/en-us/dynamics365/business-central/`. Every URL below returned **HTTP 200 on 2026-11-22** (curl, following redirects). Codes are Code[20]. The parent column is blank for top-level tasks. Sequence is the order shown, multiplied by 10.

| Module (Seq) | Task code | Parent | Type | Description | Learn path (after L) |
| --- | --- | --- | --- | --- | --- |
| **GL** General ledger (10) | — | — | — | module | `finance` |
| GL | GL-10 | | (group) | Chart of accounts | `finance-setup-chart-accounts` |
| GL | GL-11 | GL-10 | Read | Account types, categories and totalling for fund accounting | `finance-setup-chart-accounts` |
| GL | GL-12 | GL-10 | Test | Create a G/L account for a new restricted fund | `finance-setup-chart-accounts` |
| GL | GL-20 | | (group) | General journals | `ui-work-general-journals` |
| GL | GL-21 | GL-20 | Read | Journal templates and batches | `ui-work-general-journals` |
| GL | GL-22 | GL-20 | Test | Post a journal with fund and grant dimensions | `finance-how-post-transactions-directly` |
| GL | GL-23 | GL-20 | Test | Reverse a posted journal | `finance-how-reverse-journal-posting` |
| **DIM** Funds, grants and dimensions (20) | — | — | — | module | `finance-dimensions` |
| DIM | DIM-10 | | Read | How dimensions track funds, grants and programmes | `finance-dimensions` |
| DIM | DIM-20 | | Test | Set default fund dimensions on G/L accounts | `finance-dimensions` |
| DIM | DIM-30 | | Test | Analyse expenditure by fund and programme | `finance-dimensions` |
| **BUD** Budgets and allocations (30) | — | — | — | module | `finance-how-create-budgets` |
| BUD | BUD-10 | | (group) | Budgets | `finance-how-create-budgets` |
| BUD | BUD-11 | BUD-10 | Read | G/L budgets with dimensions | `finance-how-create-budgets` |
| BUD | BUD-12 | BUD-10 | Test | Create a grant budget and compare it with actuals | `finance-how-create-budgets` |
| BUD | BUD-20 | | (group) | Cost allocations | `finance-allocate-revenue-costs` |
| BUD | BUD-21 | BUD-20 | Read | Fixed and variable allocation accounts | `finance-allocate-revenue-costs` |
| BUD | BUD-22 | BUD-20 | Test | Allocate shared support costs across programmes | `finance-allocate-revenue-costs` |
| BUD | BUD-30 | | Read | Deferring multi-period grant income | `finance-how-defer-revenue-expenses` |
| **AP** Payables (40) | — | — | — | module | `payables-manage-payables` |
| AP | AP-10 | | Read | Vendor setup | `purchasing-how-register-new-vendors` |
| AP | AP-20 | | Test | Post a purchase invoice with fund dimensions | `purchasing-how-record-purchases` |
| AP | AP-30 | | (group) | Vendor payments | `payables-make-payments` |
| AP | AP-31 | AP-30 | Test | Suggest and post vendor payments | `payables-how-suggest-vendor-payments` |
| AP | AP-32 | AP-30 | Test | Apply a payment to an invoice manually | `payables-how-apply-purchase-transactions-manually` |
| **AR** Receivables, donors and funders (50) | — | — | — | module | `receivables-manage-receivables` |
| AR | AR-10 | | Read | Set up donors and funders as customers | `sales-how-register-new-customers` |
| AR | AR-20 | | Test | Invoice a grant claim | `sales-how-invoice-sales` |
| AR | AR-30 | | Test | Post and apply a receipt | `receivables-how-apply-sales-transactions-manually` |
| AR | AR-40 | | Read | Collect outstanding balances | `receivables-collect-outstanding-balances` |
| **BANK** Cash management (60) | — | — | — | module | `bank-manage-bank-accounts` |
| BANK | BANK-10 | | Test | Set up a bank account | `bank-how-setup-bank-accounts` |
| BANK | BANK-20 | | Test | Reconcile a bank account | `bank-how-reconcile-bank-accounts-separately` |
| **FA** Fixed assets (70) | — | — | — | module | `fa-manage` |
| FA | FA-10 | | Read | Fixed asset setup and posting groups | `fa-how-setup-general` |
| FA | FA-20 | | Read | Depreciation books | `fa-how-setup-depreciation` |
| FA | FA-30 | | Test | Acquire a fixed asset | `fa-how-acquire` |
| **VAT** VAT (80) | — | — | — | module | `finance-setup-vat` |
| VAT | VAT-10 | | Read | VAT setup, including exempt and partially exempt activity | `finance-setup-vat` |
| VAT | VAT-20 | | Test | Prepare a VAT return | `finance-how-report-vat` |
| **REP** Reporting and year end (90) | — | — | — | module | `bi` |
| REP | REP-10 | | (group) | Financial reporting | `bi-how-work-account-schedule` |
| REP | REP-11 | REP-10 | Read | Financial reports and account categories | `bi-how-work-account-schedule` |
| REP | REP-12 | REP-10 | Test | Run an income and expenditure report by fund | `bi-how-work-account-schedule` |
| REP | REP-13 | REP-10 | Read | Statistical accounts for non-financial measures | `bi-use-statistical-accounts` |
| REP | REP-20 | | (group) | Period and year-end close | `year-close-years-periods` |
| REP | REP-21 | REP-20 | Read | Accounting periods and fiscal year close | `year-close-years-periods` |
| REP | REP-22 | REP-20 | Test | Run Close Income Statement in a test company | `year-close-years-periods` |

That makes 9 modules and 40 tasks, of which 33 are bottom-level (leaves). "(group)" rows are registered with Type = Read; their Type is ignored (I-3). Each task row also gets an Instructions text of 1–2 sentences, which the Implementer writes from the description. Module descriptions are the bold names.

These rows are registered as **template** modules and tasks (Template = true). Nothing from §4a exists as live data until a user runs Copy from Template.

## 5. Event Contracts

| Target/version / publisher / event | Definition source and verification | Fields consumed | Intended effect | Order / state / persistence proof or pending check |
| --- | --- | --- | --- | --- |
| This app / Codeunit 80000 / `OnRegisterTemplates` (new) | Declared in §4. Subscribers must match its signature exactly | `var Registry` | Providers upsert their template modules and tasks | No order between subscribers. Each provider registers parents before children. A conflicting code is skipped rather than raised. Pending manual checks T09 and T10 |
| Standard BC events | none | — | — | — |

## 6. UI, Permissions and API Contracts

### Page 80000 "Onb. Module List" (live modules)
- **Setup**: PageType List. SourceTableView = where(Template = const(false)), sorted by (Template, Sequence). Caption 'Onboarding Modules'. UsageCategory Lists, ApplicationArea All. Editable = false. CardPageId = Onb. Module Card. New and Delete are allowed (New opens the card; Delete removes the module and its tasks).
- **Columns**: Code, Description, Source App Name, No. of Tasks, Completed Tasks, Not Applicable Tasks, and Progress % (a page variable). Progress % = Completed ÷ (No. of Tasks − Not Applicable) × 100, or 100 when the divisor is 0. It shows as `Favorable` when it is 100 and No. of Tasks > 0.
- **Actions**:
  - `CopyFromTemplate` (Caption 'Copy from Template', Image Copy, promoted). Runs Registry.RefreshTemplates, then **Commit**: the next step opens a page with RunModal, and BC doesn't allow that during an open write transaction. Then runs Onb. Template List in LookupMode. On OK: `SetSelectionFilter` on the selected template modules, then Task Mgt.CopyFromTemplate. If the refresh skipped any codes, a `SkippedMsg` message lists them.
  - `OpenLearn`.
- **No OnOpenPage seeding** (AC-01).

### Page 80003 "Onb. Template List" (template modules)
- **Setup**: PageType List. SourceTableView = where(Template = const(true)), sorted by (Template, Sequence). Caption 'Onboarding Templates'. UsageCategory Lists. Editable = false. CardPageId = Onb. Module Card. New is allowed: a new record must get Template = true (V-06). Multi-select works in LookupMode.
- **Columns**: Code, Description, Source App Name, No. of Tasks.
- **Action**: `RefreshTemplates` runs Registry.RefreshTemplates and shows `SkippedMsg` if anything was skipped.

### Page 80001 "Onb. Module Card"
- **Setup**: PageType Card, opened from either list.
- **Fields**: Template, Code, Description, Sequence, Learn URL, Source App Name (read-only), and Progress % (hidden when Template is ticked).
- **Editability**:
  - Template and Code can be edited only on a new record (page variable IsNew, set in OnNewRecord and cleared in OnAfterGetCurrRecord once the record exists).
  - A new record takes Template from the list it was opened from (V-06).
  - The whole card is read-only when `Rec.IsProviderTemplate()` (R-07).
  - The Tasks part's Editable follows the same expression.
- **Tasks FastTab**: part Onb. Task Part, with SubPageLink Template = field(Template), "Module Code" = field(Code), and UpdatePropagation = Both.

### Page 80002 "Onb. Task Part"
- **Setup**: PageType ListPart, sorted by (Template, "Module Code", "Sort Path"). Insert, modify and delete are allowed. The repeater has `ShowAsTree = true`, `IndentationColumn = Indentation`, `TreeInitialState = ExpandAll`.
- **Columns**, in order:

| Column | Editable | Row behaviour |
| --- | --- | --- |
| Description (first, because the tree indents the left-most column) | yes | `Strong` on group rows |
| Task Code | on a new row only | — |
| Parent Task Code | yes (lookup filtered to the same module) | — |
| Sequence | yes | — |
| Type | yes | HideValue on group rows |
| Status | on live leaf rows only | HideValue on template and group rows. Leaf styles: Completed `Favorable`, In Progress `Ambiguous`, Not Applicable `Subordinate` |
| Group Status (page variable) | no | Shown only on live group rows: `<rollup> (<Done>/<Total>)` |
| Notes | on live leaf rows only | HideValue on template and group rows |
| Completed By, Completed At | no | HideValue on template rows |
| Instructions, Learn URL | yes | Visible = false by default |

- **Actions**: `MarkComplete` (Task Mgt.CompleteBranch, then CurrPage.Update(false)) is enabled only on live rows. `OpenLearn`.
- **OnDeleteRecord**: on a group row, ask `DeleteGroupQst`: "Delete %1 and all of its sub-tasks?" Cancelling stops the delete.
- After Parent Task Code or Sequence changes: CurrPage.Update(false), so the tree re-sorts.

### Permission set 80000 "ONB ALL" (Assignable)
- tabledata Onb. Module = RIMD, tabledata Onb. Task = RIMD.
- table, page and codeunit objects 80000–80003 = X, each named explicitly, no wildcards.
- This is the only set (TD-09).

### API
None.

## 7. Tests — Given / When / Then

**Manual sandbox checks only** (Q-01: no Test app). Every one is reported `not-run` until someone performs it. T09 and T10 need a throwaway sample extension that subscribes to `OnRegisterTemplates`. It isn't part of this app.

| Test | Acceptance / decision | Given | When | Then | Check and owner |
| --- | --- | --- | --- | --- | --- |
| T01 | AC-01 | Fresh install | Open Onboarding Modules, then Onboarding Templates → Refresh | The module list is empty. The template list shows 9 NFP modules (GL..REP) with Source 'Business Central' | Manual |
| T02 | AC-01, TD-08 | T01 | Copy from Template, select GL and DIM | Live GL (7 tasks) and DIM (3 tasks) exist with matching trees. Every status is Not Started. The message reads "2 modules copied. 10 tasks added, 0 already present." | Manual |
| T03 | AC-06, I-4 | Live GL: GL-22 Completed with Notes, GL-23 deleted, GL-99 added by the user | Copy GL again | GL-23 is back under GL-20. GL-22 is still Completed with its Notes. GL-99 is kept. The message reports 1 added and 6 already present | Manual |
| T04 | AC-03 | Live leaf DIM-10 | Set Completed, then Not Started | Stamped, then cleared | Manual |
| T05 | AC-07 | Live BUD-10 with 2 leaves | Leaves set to: none started / one In Progress / Completed + Not Applicable | Group Status shows Not Started / In Progress / Completed | Manual |
| T06 | I-3, I-6 | A group row, and a template leaf | Try to set Status (column hidden: validate through code or the inspection page) | GroupStatusErr / TemplateStatusErr | Manual |
| T07 | CompleteBranch | Live AP-30 with AP-31 Not Applicable and AP-32 Not Started | Mark Complete on AP-30 | AP-32 is Completed and stamped. AP-31 is unchanged | Manual |
| T08 | AC-04 | Live GL from T02 | View the list | No. of Tasks = 5 (leaves only). Progress % follows | Manual |
| T09 | AC-05, V-02 | Sample extension registers template TESTMOD with 3 levels | Refresh Templates | TESTMOD is listed with the sample's Source App Name. Copying it builds a 3-level live tree | Manual. **This is the proof for V-02** |
| T10 | R-02, skip rule | A user-built template TESTMOD exists before the sample is installed | Refresh Templates | TESTMOD is skipped and named in the message. The user's template is unchanged. The NFP templates still refresh | Manual |
| T11 | AC-08, I-1, I-2 | A live user-built module | Enter tasks by hand: a child under a parent, a parent typed in that doesn't exist, a cycle, an 11th level | Tree builds correctly / ParentMissingErr / ParentCycleErr / TooDeepErr | Manual |
| T12 | AC-08, I-5 | A user-built tree | Change a sibling's Sequence, and move a task with children to another parent | Order updates. The child moves with the task. The old parent stops being a group when it has no children left | Manual |
| T13 | §3 OnDelete | A group with 2 children | Delete the group (confirm) / delete the module | The children are deleted / all tasks are deleted | Manual |
| T14 | AC-09, TD-07 | Onboarding Templates | New → module MYTPL with 2 tasks → back in Onboarding Modules, Copy from Template | MYTPL is listed and copies correctly. Template can't be edited on an existing record | Manual |
| T15 | R-07 | The NFP template GL | Open its card | Card and tasks are read-only. A user-built template is editable | Manual |
| T16 | Security | — | Learn URL 'http://x' / blank | Error / accepted | Manual |
| T17 | AC-02, AC-07 UI | Live GL | Collapse GL-20, then Open Learn on a task with no URL | The tree collapses. The module's link opens | Manual |

## 8. Verification and Open Questions

| Claim / contract | State | Source or actual result | Materiality | Missing check / owner |
| --- | --- | --- | --- | --- |
| V-01 ShowAsTree on an editable ListPart | Verified definition | Learn: Designing Indented Hierarchy Lists | Bounded | T17 |
| V-02 `GetCallerModuleInfo` returns the subscriber's app | Verified definition, behaviour pending | Learn: GetCallerModuleInfo. It holds only if called directly in the public procedure | Material for ownership | T09 |
| V-03 Learn URLs in §4a | Observed: HTTP 200 for all 33 paths on 2026-11-22 | curl | Bounded | Re-check before release |
| V-04 Another app can subscribe to a `local` IntegrationEvent | Verified definition | skill-events | Bounded | T09 |
| V-05 Sort Path format | Design | §3 | Bounded | T11, T12 |
| V-06 A New record opened from a list filtered with SourceTableView `const` inherits Template | Pending. It is commonly observed BC behaviour but has no source checked here | — | Bounded: the Implementer sets it explicitly when the filter is single-valued | T14 |
| V-07 RunModal after RefreshTemplates needs a Commit | Pending. It is the known BC write-transaction rule for modal runs, but no source was checked here | — | Bounded: the spec puts the Commit in the page action, not in a subscriber | T02 |

**Human decisions:** Q-01..Q-03 as in revision 1. On 2026-11-22 the user also decided: a Template flag on the header, pick-modules copy, add missing tasks only, one permission set. Nothing is open.

## 9. Implementation Boundary

**Fixed:** IDs, names, field numbers and types, the primary keys including Template, procedure and event signatures, error conditions, the skip-on-conflict rule, copy semantics, the rollup rule, depth ≤ 10, the Sort Path format, permission contents, and the §4a content.

**Left to the Implementer:** how descendants are re-pathed, label names, the Instructions wording, action images, and how page variables are calculated.

There are no HIGH risks.

## 10. AL-Go / CI Considerations

- IDs 80000–80003 come from the range 80000–80100.
- No dependencies beyond the base and system apps.
- No telemetry, no translations, no Test app.
- CodeCop, UICop and PerTenantExtensionCop are recommended; configuring them belongs to the setup owner.
- Downstream: compile, check that the permission set covers every object, then T01–T17 by hand.
- Nothing here has been compiled or run.

## 11. Acceptance Criteria

- AC-01..AC-09 (architecture revision 3), mapped in §7.
- **Negative cases**: T06, T10, T11, T16.
- **Unchanged behaviour**: no standard BC object is touched or subscribed to.

### Review criteria (BCQuality)

| Object | Knowledge path | What the reviewer checks | Layer |
|---|---|---|---|
| — | not available (BCQuality not installed) | ALDC native review checks only | — |

## 12. Human Review and Next Step

**Complete:** all the contracts for revision 2.

**Changes since revision 1:**
- Blank install, with Copy from Template.
- Template flag in the primary key.
- Pages allow building content by hand, and there is a new Template List page (80003).
- The event and procedures are renamed to the Template forms.
- Skip-on-conflict instead of an error.
- ONB VIEW dropped, ONB ALL is RIMD.
- Tests T01–T17 rewritten.

**Approved:** architecture revision 3 and spec revision 2 (user, 2026-11-22).

**Next step after approval:** `/aldc:develop` with this spec and architecture revision 3, then `/aldc:review`. The Conductor doesn't fit, because there are no tests (Q-01).
