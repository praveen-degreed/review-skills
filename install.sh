#!/usr/bin/env bash
# install.sh -- install the PR review skills (frontend and/or backend) from this repo.
#
# Usage:  install.sh [fe|be|all] [--global]       (default: all; skills install into ~/.claude, so --global is implied)
#   from GitHub:  gh api repos/praveen-degreed/review-skills/contents/install.sh -q .content | base64 -d | bash -s -- all
#   from a clone: REVIEW_SKILLS_SRC=/path/to/review-skills ./install.sh all
# Env: CLAUDE_HOME  where Claude Code keeps its config (default ~/.claude; set it to try an install without touching yours)
#
# What it installs (the shared scripts in common/scripts are COPIED into each skill, because a skill is a
# self-contained folder; the repo keeps one source, the install keeps one copy per skill):
#   fe  -> $CLAUDE_HOME/skills/review-prs     + the fe-* agents in $CLAUDE_HOME/agents
#   be  -> $CLAUDE_HOME/skills/review-prs-be  + the py-* agents in $CLAUDE_HOME/agents
# The previous install of a skill is kept once, in $CLAUDE_HOME/backup-review-skills/<skill>.
set -euo pipefail

REPO="praveen-degreed/review-skills"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
which_skills="all"
for arg in "$@"; do
  case "$arg" in
    fe | be | all) which_skills="$arg" ;;
    --global) ;;
    *) echo "Error: unknown argument '$arg'. Usage: install.sh [fe|be|all] [--global]" >&2; exit 1 ;;
  esac
done
case "$CLAUDE_HOME" in /?*) ;; *) echo "Error: CLAUDE_HOME must be an absolute path, got '$CLAUDE_HOME'" >&2; exit 1 ;; esac

info() { printf '[INFO] %s\n' "$1"; }

# Where the repo files come from: a local clone, or the main branch from GitHub.
tmp_src=""
if [ -n "${REVIEW_SKILLS_SRC:-}" ]; then
  SRC="$REVIEW_SKILLS_SRC"
else
  command -v gh >/dev/null 2>&1 || { echo "Error: gh CLI not found (brew install gh), or set REVIEW_SKILLS_SRC to a local clone" >&2; exit 1; }
  tmp_src=$(mktemp -d)
  trap '[ -n "$tmp_src" ] && [ -d "$tmp_src" ] && rm -rf -- "${tmp_src:?}"' EXIT
  gh api "repos/$REPO/tarball/main" >"$tmp_src/repo.tgz" || { echo "Error: cannot download $REPO (is gh authenticated and does it have access?)" >&2; exit 1; }
  tar -xzf "$tmp_src/repo.tgz" -C "$tmp_src"
  SRC=$(find "$tmp_src" -mindepth 1 -maxdepth 1 -type d | head -1)
fi
[ -d "$SRC/common/scripts" ] && [ -d "$SRC/fe" ] && [ -d "$SRC/be" ] || { echo "Error: '$SRC' does not look like the review-skills repo" >&2; exit 1; }

install_skill() { # <fe|be> <skill folder name> <agent prefix>
  local kind=$1 name=$2 prefix=$3
  local dest="$CLAUDE_HOME/skills/$name" backup_root="$CLAUDE_HOME/backup-review-skills"
  info "Installing $kind skill -> $dest"
  mkdir -p "$CLAUDE_HOME/skills" "$CLAUDE_HOME/agents" "$backup_root"
  if [ -d "$dest" ]; then
    local backup="$backup_root/$name"
    [ -d "$backup" ] && rm -rf -- "${backup:?}"   # one backup slot per skill, always under backup-review-skills/
    mv "$dest" "$backup"
    info "  previous install kept in $backup"
  fi
  mkdir -p "$dest/scripts"
  cp "$SRC/$kind/SKILL.md" "$dest/SKILL.md"
  [ -d "$SRC/$kind/references" ] && cp -R "$SRC/$kind/references" "$dest/references"
  [ -d "$SRC/$kind/evals" ] && cp -R "$SRC/$kind/evals" "$dest/evals"
  [ -f "$SRC/$kind/REVIEW.md.example" ] && cp "$SRC/$kind/REVIEW.md.example" "$dest/REVIEW.md.example"
  cp "$SRC"/common/scripts/*.sh "$dest/scripts/"
  cp "$SRC"/"$kind"/scripts/*.sh "$dest/scripts/"   # the skill's own scripts win over a shared one of the same name
  chmod +x "$dest"/scripts/*.sh
  local n=0
  for agent in "$SRC/$kind"/agents/"$prefix"*.md; do
    [ -f "$agent" ] || continue
    cp "$agent" "$CLAUDE_HOME/agents/$(basename "$agent")"; n=$((n + 1))
  done
  info "  $n agents -> $CLAUDE_HOME/agents, $(ls "$dest/scripts" | wc -l | tr -d ' ') scripts"
}

case "$which_skills" in fe | all) install_skill fe review-prs fe- ;; esac
case "$which_skills" in be | all) install_skill be review-prs-be py- ;; esac
info "Done. Restart Claude Code sessions that were open; a running review keeps the old files it already read."
