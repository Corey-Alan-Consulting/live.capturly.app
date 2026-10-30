#!/usr/bin/env bash
# Stop hook: refuse "done" while the CI-parity gates fail — the same three
# scripts /pr-check and the PR checks run (lint, type-check, test), through
# whichever package manager the lockfile names — at most 3 times per
# session, the implement-spec harness's rule. Exit 2 blocks the
# stop and puts the failure tails in front of the agent.
#
# Cheap by design: it runs only in a session that edited code (marker from
# post-edit-lint.sh), and a tree that already passed is an immediate exit 0.
#
# Synced from framework/agents/hooks — fix it there, not here.
set -uo pipefail
in="$(cat)"
root="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$root" || exit 0
sid="$(node -e 'const i=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(i.session_id||"nosession")' <<<"$in")"
state="${TMPDIR:-/tmp}/claude-stop-gate/${sid}"
[ -f "${state}.edited" ] || exit 0
n="$(cat "${state}.denials" 2>/dev/null || echo 0)"
[ "$n" -ge 3 ] && exit 0

deny() {
  echo $((n + 1)) >"${state}.denials"
  echo "$1" >&2
  exit 2
}
# Package manager from the lockfile; the gate runs only the scripts the
# repo defines. A repo with no package.json has no gates here.
[ -f package.json ] || exit 0
pm=pnpm; install="pnpm install --frozen-lockfile"
if [ ! -f pnpm-lock.yaml ]; then
  if [ -f yarn.lock ]; then pm=yarn; install="yarn install --frozen-lockfile"
  else pm=npm; install="npm ci"; fi
fi
has_script() { node -e 'process.exit((require("./package.json").scripts||{})[process.argv[1]] ? 0 : 1)' "$1"; }
has_script lint || has_script type-check || has_script test || exit 0
[ -d node_modules ] || deny "You are not done: the CI-parity gates could not run because node_modules is missing. Run ${install}, then finish."

# Content hash of the tree (untracked included) without touching the index.
tree="$(GIT_INDEX_FILE="${state}.index" git add -A . >/dev/null 2>&1 && GIT_INDEX_FILE="${state}.index" git write-tree 2>/dev/null || echo none)"
[ "$tree" != none ] && [ "$tree" = "$(cat "${state}.pass" 2>/dev/null)" ] && exit 0

! has_script db:generate || "$pm" run db:generate >"${state}.gen.log" 2>&1 || true
fails=""
! has_script lint || "$pm" run lint >"${state}.lint.log" 2>&1 || fails="${fails} lint"
! has_script type-check || "$pm" run type-check >"${state}.types.log" 2>&1 || fails="${fails} type-check"
if has_script test; then
  # --passWithNoTests is a jest/vitest flag (turbo forwards it to them); a
  # node --test or mocha script would choke on it.
  flag=""
  node -e 'process.exit(/jest|vitest|turbo/.test(require("./package.json").scripts.test) ? 0 : 1)' && flag="--passWithNoTests"
  # Only npm needs `--` to pass args to the script (it strips one). pnpm and
  # yarn forward them as-is, so a `--` reaches the script literally: jest then
  # reads `--passWithNoTests` as a test-path PATTERN, matches nothing and
  # exits 1, failing a green suite. Turbo scripts already end in `--`.
  if [ "$pm" = npm ]; then npm test ${flag:+-- "$flag"} >"${state}.test.log" 2>&1 || fails="${fails} test"
  else "$pm" test ${flag:+"$flag"} >"${state}.test.log" 2>&1 || fails="${fails} test"; fi
fi
if [ -z "$fails" ]; then
  echo "$tree" >"${state}.pass"
  exit 0
fi
{
  echo "You are not done: these gates FAIL:${fails}. Fix them before finishing (never weaken a gate). Failure tails:"
  for g in lint types test; do
    f="${state}.${g}.log"
    [ -s "$f" ] && { echo "--- ${g}"; tail -n 25 "$f"; }
  done
} >"${state}.reason"
deny "$(cat "${state}.reason")"
