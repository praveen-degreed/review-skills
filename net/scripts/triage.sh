#!/usr/bin/env bash
# Routing for the .NET monolith review (no model, read-only). Decides which team skill reviews a PR.
# Usage: triage.sh <fetch-dir>        (fetch-dir from fetch-pr.sh: files.txt, stats.txt)
# Env:   MAESTRO_PATHS  regex of paths that make it a Maestro PR (default: maestro|aicoach, case-insensitive)
# Prints:
#   ROUTE   maestro | general     maestro = dg-maestro-review (it also dispatches the dg-pr-review domain agents); general = dg-pr-review
#   FILES   <N> changed, <M> match the Maestro paths
#   KINDS   cs=<n> sql=<n> other=<n>
#   CLAUDE_DIR  yes | no          yes = the PR changes .claude/ (skills, agents, hooks): do not run the repo's skills from this PR
set -u
dir=${1:-}; [ -f "$dir/files.txt" ] || { echo "triage: usage: triage.sh <fetch-dir> (files.txt missing)" >&2; exit 2; }
pat=${MAESTRO_PATHS:-maestro|aicoach}
n=$(grep -c . "$dir/files.txt")
m=$(grep -E -i -c "$pat" "$dir/files.txt")
cs=$(grep -E -c '\.cs$' "$dir/files.txt"); sql=$(grep -E -c '\.sql$' "$dir/files.txt")
claude=no; grep -q '^\.claude/' "$dir/files.txt" && claude=yes
route=general; [ "$m" -gt 0 ] && route=maestro
echo "ROUTE $route"
echo "FILES $n changed, $m match '$pat'"
echo "KINDS cs=$cs sql=$sql other=$((n - cs - sql))"
echo "CLAUDE_DIR $claude"
