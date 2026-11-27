#!/usr/bin/env bash
# standards.sh <fetch-dir> [<checkout-dir>]
# Writes <fetch-dir>/standards.txt: which of the repo's OWN standards apply to the changed files, so the review checks the
# code against what the team wrote down (kb/repo-instructions/standards/*.md, CLAUDE.md), not only this skill's copy.
# Reads the PR-pinned checkout. If the repo has no such files, says so and exits 0 (the review adds a Not verified line).
set -u

die() { echo "standards: $*" >&2; exit 1; }
dir=${1:-}; co=${2:-}
[ -n "$dir" ] && [ -f "$dir/files.txt" ] || die "usage: standards.sh <fetch-dir> [<checkout-dir>]"
out="$dir/standards.txt"
: >"$out"

root=""
[ -n "$co" ] && [ -d "$co/kb/repo-instructions/standards" ] && root="$co"
if [ -z "$root" ]; then
  echo "NONE: no kb/repo-instructions/standards in the checkout; review against passes.md only and add 'Not verified: repo standards (not found)'" >"$out"
  cat "$out"; exit 0
fi

std="kb/repo-instructions/standards"
has() { grep -E -q "$1" "$dir/files.txt"; }
line() { printf '%s\n' "$*" >>"$out"; }
size() { wc -l <"$root/$1" 2>/dev/null | tr -d ' '; }
add() { # add <file> <why> : list a standards file once with its size and how to read it
  local f="$std/$1"
  [ -f "$root/$f" ] || return 0
  grep -q "^STD $f " "$out" 2>/dev/null && return 0
  local n; n=$(size "$f")
  if [ "${n:-0}" -gt 120 ]; then line "STD $f ($n lines; too big to read whole: grep the section named in kb/repo-instructions/INDEX.md with -A 30) - $2"
  else line "STD $f ($n lines; read whole) - $2"; fi
}

line "standards: the repo's own written standards for the changed files (checkout: $root)."
line "Rules: read each STD file listed for your passes BEFORE judging; when a finding breaks one, cite it as Source: \`$std/<file>.md:<line>\` and say which rule. When this skill's passes.md and the repo standard disagree, the repo standard wins: say so in the finding."
line ""

has '\.(html)$|inline|\.component\.ts$' && {
  add a11y.md "every template: controls, labels, keyboard, live regions"
  add design.md "Tailwind classes, Apollo components, tokens, icons, presentational components"
  add i18n.md "every user-facing string, label, aria text, placeholder, error text; keys, defaults, one i18n object per class"
}
has '\.ts$' && {
  add angular.md "component/service patterns, signals, subscription cleanup, lazy loading"
  add quality.md "size limits, hygiene, comments (one line; delete restating comments), data-dgat on EVERY interactive element in new or changed templates, error handling"
  add performance.md "lazy loading, bundle, timers, @for track, computed"
  add security.md "innerHTML, tokens, storage, redirects, user input"
  add nx.md "imports, library boundaries, barrels, secondary entry points, path aliases"
}
has '\.(html|ts)$' && add quality.md "data-dgat contract on interactive elements; comment standard"
has '\.spec\.ts$' && add testing.md "spec conventions: Spectator, mocks, timers, what to assert"
has 'tsconfig|project\.json|\.eslintrc|eslint\.config|nx\.json' && add nx.md "path aliases, project config, module boundaries"

line ""
[ -f "$root/kb/repo-instructions/INDEX.md" ] && line "INDEX kb/repo-instructions/INDEX.md - says which file AND section holds a rule; look a topic up here before deciding there is no standard"
[ -f "$root/kb/SOURCE-MAP.md" ] && line "MAP kb/SOURCE-MAP.md - feature -> source paths; use it to find EXISTING code before saying something new is needed (reuse)"
[ -f "$root/CLAUDE.md" ] && line "ROOT CLAUDE.md - repo rules (accessibility is non-negotiable; Writing style for comment text)"
n=$(grep -c '^STD ' "$out")
line ""
line "standards: $n file(s) apply"
cat "$out"
