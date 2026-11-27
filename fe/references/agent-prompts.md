# Agent Prompts

Tiny PRs (plan lists `fe-combined-reviewer`): use Agent 0, plus Agent 6 only if routed. Larger PRs: the specialists below.

0. fe-combined-reviewer - all selected passes in one agent (tiny PRs)
1. fe-code-reviewer - Angular patterns, TypeScript, security, i18n, dead code
2. fe-logic-reviewer - Logic, edge cases, cleanup/leaks, signals
3. fe-test-analyzer - Test quality, Jest/Spectator
4. fe-simplifier - Simplification suggestions (non-blocking)
5. fe-architecture-reviewer - Architecture, WCAG 2.2 AA, Apollo, Nx
6. fe-impact-analyzer - Regression, blast radius, usage validation, reuse/precedent search, API contract check

## Budget preamble (orchestrator prepends ONCE to every agent prompt)

```
Tool-call budget: {N} (failed calls do not count). When reached, stop and return partial findings.
Max {M} findings, highest severity first. Return file:line + one sentence per finding.
Context lives in the fetch dir <FETCH_DIR>: pr.diff, files.txt, meta.json, checks.txt,
head/<path> (full changed files at the PR head). Read from it. No gh calls, no git checkout.
Start with <FETCH_DIR>/digest.txt (symbols the diff touches and who uses them, already searched: do not search for those callers again), then read the `diffs/<file>.diff` of the files you review, not the whole pr.diff. Read each diff ONCE and keep notes; every extra read puts it in your context again and you pay for it on every later turn. Re-open only a small part with offset/limit.
Cite head/<path> line numbers you opened; lines found by searching the local checkout are labelled
"local checkout", never mixed in unlabelled. Never cite a line you did not open. A line number comes
from a Read or `grep -n` of head/<path>, never an offset into pr.diff (those do not exist in the file).
Use Grep or bash grep (Grep tool may be unavailable; quote globs: --include='*.ts'). Never cat/head whole files, use Read with offset/limit. Do not paste file contents.
Fix samples carry no comments except one one-line trap comment when genuinely needed.
From references/passes.md read only the sections for your Passes, plus Severity, Kind, Domain ownership, Review method and Placement (not the whole file). That is in addition to the standards below, not instead of them.
PRIORITY when the budget runs short (the budget cannot cover everything on a large file): 1) your files and their diffs, 2) the repo standards for YOUR passes (the PASSES column of standards.txt; skip the files that name none of your passes; read a file under about 120 lines in one call), 3) the reuse ledger, 4) the scan leads. Never drop 1 or 2 to afford 3 or 4; if a file is too large to read whole within budget, say which ranges you read in `Opened:`.
Read the lines of <FETCH_DIR>/scan.txt for your files (reuse, constants, helpers, security, CLASSBIND, COMMENT, DGAT, IME, CAST and ANGULAR leads) when it exists: confirm each lead by opening the cited line and the existing code it names; a lead alone is never a finding. A CLASSBIND? lead that holds (stacked [class.x] bindings repeating one condition) and a COMMENT? lead that holds (3+ added comments restating the code) are mandatory-fix Medium Rules, not suggestions: report ONE finding per file listing every spot (passes.md Styling and Comments sections).
Read <FETCH_DIR>/standards.txt when it exists and then the repo standards it lists for your passes, in the Checkout (whole-file ones whole; a11y.md and design.md by heading, found through kb/repo-instructions/INDEX.md). Judge the code against what the team wrote down, like a human reviewer who has read the team's guidelines. A finding that breaks a repo standard cites it as `Source: kb/repo-instructions/standards/<file>.md:<line>` and names the rule; if it disagrees with passes.md, the repo standard wins and you say so. A finding with no written rule behind it is judgement: say so and rate it Low or make it a Suggestion. End your report with `Standards read: <the standards files you opened>` (the orchestrator asks for a follow-up when it is missing).
REUSE LEDGER (mandatory for Quality, Angular and impact passes): for every new function, method, type, constant, pipe, component or service in your files that is exported or longer than about 10 lines, search the repo ONCE by behaviour (the verb and noun, plus two or three synonyms, the shared libs `@degreed/core/*`, the feature's siblings, kb/SOURCE-MAP.md) before you accept it. Search case-insensitively (`git grep -n -i -E 'a|b|c'`): a case-sensitive search for `stick` misses `shouldStickToBottom`. Reserve at least 4 of your tool calls for this: reading a file whole does not replace the search. End your report with `Reuse checked:` one line per symbol: `name -> existing <symbol> at <path:line> (use it)` or `name -> none found (searched: <terms>)`. An existing equivalent is a reuse finding with both locations (passes.md Review method step 5); never claim "nothing to reuse" without the ledger line.
If the brief says `Skip: <pass>`, another agent owns that pass: do not review or report it.
If the brief lists CI failures in your files, explain each one: read the spec and the CI excerpt and say why it fails, or what you could not determine. An unexplained failing test is a High finding.
Read head/<path> whole for every changed non-spec file you report on or judge clean; a diff-only read is not accepted. End your report with `Opened: <the head/<path> files you read>`.
Report only findings that need action; omit "checked, no action" items and anything inaccurate-but-fine.
"No findings" is a valid result; do not pad. On a deletion-only diff, check only that nothing
left behind (callers, comments, imports, tests) is now wrong.
Report only your own domain (passes.md ownership table). Never report unchanged lines (e.g. an
explicit OnPush on an unchanged line), except a context line this diff makes wrong; scope beats checklist items.
Do NOT re-raise issues marked FIXED in the review history unless the fix is incomplete.

Review history:
<REVIEW_CONTEXT_SUMMARY>
```

---

---

## Agent 0: fe-combined-reviewer

Role prompt: `agents/fe-combined-reviewer.md` (installed to the agents directory by `install.sh`).

## Agent 1: fe-code-reviewer

Role prompt: `agents/fe-code-reviewer.md` (installed to the agents directory by `install.sh`).

## Agent 2: fe-logic-reviewer

Role prompt: `agents/fe-logic-reviewer.md` (installed to the agents directory by `install.sh`).

## Agent 3: fe-test-analyzer

Role prompt: `agents/fe-test-analyzer.md` (installed to the agents directory by `install.sh`).

## Agent 4: fe-simplifier

Role prompt: `agents/fe-simplifier.md` (installed to the agents directory by `install.sh`).

## Agent 5: fe-architecture-reviewer

Role prompt: `agents/fe-architecture-reviewer.md` (installed to the agents directory by `install.sh`).

## Agent 6: fe-impact-analyzer

Role prompt: `agents/fe-impact-analyzer.md` (installed to the agents directory by `install.sh`).
