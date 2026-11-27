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
add() { # add <file> <passes> <why> : list a standards file once with its size, the passes that own it and how to read it
  local f="$std/$1"
  [ -f "$root/$f" ] || return 0
  grep -q "^STD $f " "$out" 2>/dev/null && return 0
  local n; n=$(size "$f")
  if [ "${n:-0}" -gt 120 ]; then line "STD $f ($n lines; too big to read whole: grep the section named in kb/repo-instructions/INDEX.md with -A 30) PASSES: $2 - $3"
  else line "STD $f ($n lines; read whole) PASSES: $2 - $3"; fi
}

line "standards: the repo's own written standards for the changed files (checkout: $root)."
line "Rules: read ONLY the STD files whose PASSES column names one of YOUR passes (Logic, Styling, Angular, A11y, Security, Quality, Test, Apollo), BEFORE judging; reading all of them costs budget you need for the code. When a finding breaks one, cite it as Source: \`$std/<file>.md:<line>\` and say which rule. When this skill's passes.md and the repo standard disagree, the repo standard wins: say so in the finding. End your report with Standards read: <the files you opened>."
line ""

has '\.(html)$|inline|\.component\.ts$' && {
  add a11y.md "A11y, Styling" "every template: controls, labels, keyboard, live regions, contrast"
  add design.md "Styling, Apollo, A11y" "Tailwind classes, Apollo components, tokens, colour contrast (4.5:1 text, 3:1 UI), icons, presentational components"
  add i18n.md "Quality, Angular" "every user-facing string, label, aria text, placeholder, error text; keys, defaults, one i18n object per class, prose inputs on shared components"
}
has '\.ts$' && {
  add angular.md "Angular, Logic, Quality" "component/service patterns, signals, afterRenderEffect for focus, @let for repeated template expressions, subscription cleanup, method calls in templates"
  add quality.md "Quality" "size limits, hygiene, comments (one line; delete restating comments), data-dgat on EVERY interactive element in new or changed templates, error handling"
  add performance.md "Logic, Security, Angular" "lazy loading, bundle, timers, repeated API calls, @for track, computed"
  add security.md "Security" "innerHTML, tokens, storage, redirects, user input, console.* and debugger before merge"
  add nx.md "Quality, Angular" "imports, library boundaries, barrels, secondary entry points, path aliases, file naming"
}
has '\.(html|ts)$' && add quality.md "Quality" "data-dgat contract on interactive elements; comment standard"
has '\.spec\.ts$' && add testing.md "Test" "spec conventions: Spectator, mocks, timers, what to assert, no type-assertion casts"
has 'tsconfig|project\.json|\.eslintrc|eslint\.config|nx\.json' && add nx.md "Quality, Angular" "path aliases, project config, module boundaries"

line ""
[ -f "$root/kb/repo-instructions/INDEX.md" ] && line "INDEX kb/repo-instructions/INDEX.md - says which file AND section holds a rule; look a topic up here before deciding there is no standard"
[ -f "$root/kb/SOURCE-MAP.md" ] && line "MAP kb/SOURCE-MAP.md - feature -> source paths; use it to find EXISTING code before saying something new is needed (reuse)"
[ -f "$root/CLAUDE.md" ] && line "ROOT CLAUDE.md - repo rules (accessibility is non-negotiable; Writing style for comment text)"
n=$(grep -c '^STD ' "$out")
line ""
line "standards: $n file(s) apply"
cat "$out"
