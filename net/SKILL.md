---
name: review-prs-net
description: >
  Main PR review skill for the Degreed .NET monolith (degreed/Degreed). Use when asked to review a pull request in that repo,
  or given a degreed/Degreed PR URL, even without the word "review". It holds no review rules itself: it routes the PR to the
  team's own skills in the repo (dg-pr-review for general changes, dg-maestro-review for Maestro/aicoach changes), wraps them with
  a fetch-once step, a mandatory-agents gate, citation verification and one comment-only post. Not for the frontend (review-prs)
  or the Python backends (review-prs-be).
argument-hint: "<PR_URL or number>"
allowed-tools: Bash Read Glob Grep Agent Skill
metadata:
  author: praveen-degreed
  version: "1.0"
---

# Review PRs (.NET monolith)

The main review skill for `degreed/Degreed`. The review rules belong to the .NET team and live in the repo:

| Team skill | When | How this skill runs it |
|---|---|---|
| `dg-pr-review` | any PR that is not Maestro | with the Skill tool, `<number> --analysis-only` (its documented mode for callers: returns the analysis, posts nothing) |
| `dg-maestro-review` | a changed path contains `maestro` or `aicoach` (case-insensitive) | it is user-invoked only, so you cannot call it; read its `SKILL.md` and follow its PR-mode workflow yourself (it composes the `dg-pr-review` domain agents) |

**Never copy or edit those skills.** They are the team's; this skill only chooses between them, feeds them, and checks what comes back.

**MANDATORY GATE (read before anything else).** You are the orchestrator, not a reviewer. Before you write any review text, the team skill's agents must have run (Agent tool calls made by `dg-pr-review`, or by you following `dg-maestro-review`). A review you wrote alone, with no agents, is invalid: say so and stop. Thinking "this PR is small, I can check it myself" is exactly the case this gate exists for. Reviewing yourself is allowed only in addition to the agents.

## Flow

### Phase 0 - Preflight
1. Parse the PR URL or number. Default repo `degreed/Degreed`.
2. `gh pr view <PR> --repo <repo> --json state,isDraft,author,isCrossRepository,baseRefName,headRefOid,changedFiles,title`. Stop and say why when the PR is not `OPEN`, is a draft, or is authored by a bot. Pin `headRefOid`; the review is of exactly that commit.
3. A fork PR (`isCrossRepository`) is analysed but **never posted**.

### Phase 1 - Fetch once and route (no model, read-only)
Run each as ONE command with its full absolute path, no `cd`, no variables, no pipes:
```
~/.claude/skills/review-prs-net/scripts/pr-worktree.sh create <number>       # only if the harness did not already give you a worktree
~/.claude/skills/review-prs-net/scripts/fetch-pr.sh <number> --repo <repo> --worktree <worktree dir>
~/.claude/skills/review-prs-net/scripts/digest.sh <fetch dir> --root <worktree dir>
~/.claude/skills/review-prs-net/scripts/triage.sh <fetch dir>
```
`triage.sh` prints `ROUTE maestro|general`, the file counts, and `CLAUDE_DIR yes|no`. If `CLAUDE_DIR yes`, the PR changes `.claude/` (skills, agents, hooks): the skills in this checkout could have been rewritten by the PR, so do NOT run them. Post nothing; reply that the PR needs a human review and why.
Read `checks.txt` (failing CI checks only; an empty file means nothing is failing).

### Phase 2 - Run the team skill for the route
- **ROUTE general:** call the Skill tool with `dg-pr-review` and the arguments `<number> --analysis-only`.
- **ROUTE maestro:** Read `.claude/skills/dg-maestro-review/SKILL.md` and the files it points to, then execute its PR-mode workflow with three overrides: **never post, never ask the user anything, never apply a fix.** Its agents are the `dg-pr-review` domain agents plus its Maestro agent; launch them as it says.
- Tell the agents (in what you pass them, where the team skill lets you add context) that `<fetch dir>/digest.txt` lists the symbols the diff touches and who uses them, and that `<fetch dir>/diffs/<file>.diff` is each file's diff: read those once instead of searching or re-reading the whole diff.
- Do not run `dotnet build`, tests, `sqlcmd` or anything from the PR: the review is read-only.

### Phase 3 - Verify what came back
1. List every `path:line` citation in the returned review.
2. Run `~/.claude/skills/review-prs-net/scripts/verify-citations.sh <fetch dir> 'path:line=token' ...` ONCE (one quoted argument per finding; `token` is the identifier the finding relies on). A finding whose line or token does not exist is re-located or dropped.
3. If `checks.txt` is not empty, run `~/.claude/skills/review-prs-net/scripts/ci-failures.sh <fetch dir>` and say why CI failed; never report red CI as green.
4. Put what you could not verify (tests not run, ticket unreadable, an agent that did not finish) under `Not verified`.

### Phase 4 - Output and post
- **Always comment-only.** Keep the team skill's assessment as text ("Reviewer's view: ..."), but never use `--approve` or `--request-changes`: a human decides.
- Footer: which team skill ran (`dg-pr-review` or `dg-maestro-review`), the route and why, which agents ran, what was skipped.
- Write the review to `<fetch dir>/review-body.md`. If the harness says **DRAFT MODE** (as Dex does for this repo), give the review as your final answer and stop: the harness posts it. Otherwise show it to the user and, only if they say so, post it with ONE command: `gh pr review <number> --repo <repo> --comment --body-file <fetch dir>/review-body.md` (never an inline multi-line `--body`).

### Phase 5 - Cleanup
`~/.claude/skills/review-prs-net/scripts/cleanup-pr.sh <fetch dir>` and `.../pr-worktree.sh cleanup <worktree dir>` (skip any the harness owns).

## Rules that never bend
- Agents are read-only and never call `gh`; only this skill's final step posts.
- No approve, no request-changes, no merge, no push, no commit.
- Cost follows the change: the team skills decide which of their agents run; never skip a planned agent to save money, and never add agents they did not ask for.
