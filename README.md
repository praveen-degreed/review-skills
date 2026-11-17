# review-skills

The PR review skills for Claude Code, in one repo: **`review-prs`** (frontend, Angular/TypeScript) and **`review-prs-be`** (backend, Python/FastAPI: Coach Builder and degreed-assistant).

Both do the same job in the same way: fetch the PR once, work out what the change does, run only the reviewers that change needs, verify every finding against the code, and post one review. The no-model steps (fetch, digest, citation check, CI failures, worktree) are shared; the language-specific parts (triage rules, agents, patterns) are per skill.

## Layout
```
common/scripts/    shared by both skills (edit here once)
  fetch-pr.sh        fetch the PR once: diff, stats, failing checks, changed files (--worktree copies them from the PR worktree)
  digest.sh          per-file diffs + a digest of the symbols the diff touches and who uses them
  verify-citations.sh  drop a finding whose cited line or token does not exist
  ci-failures.sh     why CI failed (Jest/Angular and pytest/ruff)
  pr-worktree.sh     a throwaway worktree of the PR head   cleanup-pr.sh   remove the fetch dir
fe/                review-prs: SKILL.md, agents/ (fe-*), references/, scripts/ (triage, split, scan, lint, find-endpoint), evals/
be/                review-prs-be: SKILL.md, agents/ (py-*), references/ (incl. the degreed-assistant repo profile), scripts/triage.sh
install.sh         installs one or both skills
```

## Install
```
gh api repos/praveen-degreed/review-skills/contents/install.sh -q .content | base64 -d | bash -s -- all     # or: fe | be
REVIEW_SKILLS_SRC=$PWD ./install.sh all                                                                   # from a clone
CLAUDE_HOME=/tmp/try ./install.sh all                                                                     # try it without touching ~/.claude
```
The installer **copies** the shared scripts into each skill's own folder (`~/.claude/skills/review-prs/scripts`, `.../review-prs-be/scripts`), because a skill must be a self-contained folder. The repo keeps one source; each install keeps one copy per skill. A skill's own script of the same name wins over a shared one. The previous install of a skill is kept once in `~/.claude/backup-review-skills/`. It installs from `main` on GitHub: a change takes effect only after it is merged and the installer is re-run.

## Changing the skills (contributing)
- A fix to a shared step goes in `common/scripts` once and reaches both skills on the next install.
- Rules that differ by language stay in `fe/` or `be/`. `triage.sh` is per skill on purpose (different file types and risks).
- After changing scripts, run `fe/evals/run-script-evals.sh`. Dex (the Slack reviewer bot) has its own permission check, `tests/check_permissions.py` in the Dex repo, to run after a script is added or renamed.
- Agents must never post to GitHub; only the orchestrating skill does, with `gh pr review --body-file`.

## History
Replaces `fe-claude-skills/review-prs` and `be-claude-skills/review-prs`. `dev-guard` (the development-time coding standards skill) stays in `fe-claude-skills`.
