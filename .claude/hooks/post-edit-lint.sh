#!/usr/bin/env bash
# PostToolUse hook for Edit/Write/MultiEdit: format and lint the file that was
# just edited, so the agent sees a lint error at the edit instead of at the
# PR. Prettier writes; eslint reports; a newly added lint or type suppression
# is reported too (a suppression is a finding, not a fix). Exit 2 puts the
# text in front of the agent (the edit itself has already landed).
#
# Also marks this session as "edited code" so stop-gate.sh runs the full CI
# parity gates only in sessions that changed something.
#
# Works with ESLint 8 (eslintrc) and 9 (flat config): no version-specific
# flags, and the repo's own node_modules/.bin, so pnpm, npm and yarn repos
# all work. A repo without a tool is formatted or linted as far as it can
# be, never blocked.
#
# Synced from framework/agents/hooks — fix it there, not here.
set -uo pipefail
in="$(cat)"
root="${CLAUDE_PROJECT_DIR:-$PWD}"
read -r sid file < <(node -e '
  const i = JSON.parse(require("fs").readFileSync(0, "utf8"));
  console.log((i.session_id || "nosession") + " " + (i.tool_input?.file_path || ""))' <<<"$in")
mkdir -p "${TMPDIR:-/tmp}/claude-stop-gate" && : > "${TMPDIR:-/tmp}/claude-stop-gate/${sid}.edited"

[ -n "${file:-}" ] && [ -f "$file" ] || exit 0
case "$file" in *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs) ;; *) exit 0 ;; esac
cd "$root" || exit 0
rel="${file#"$root"/}"
out=""

# Lines this edit added (Write: lines not already in HEAD's copy of the file).
added="$(node -e '
  const i = JSON.parse(require("fs").readFileSync(0, "utf8")); const t = i.tool_input || {};
  const s = i.tool_name === "MultiEdit" ? (t.edits || []).map((e) => e.new_string || "").join("\n")
    : i.tool_name === "Write" ? (t.content || "") : (t.new_string || "");
  process.stdout.write(s)' <<<"$in")"
if node -e 'process.exit(JSON.parse(require("fs").readFileSync(0,"utf8")).tool_name === "Write" ? 0 : 1)' <<<"$in"; then
  added="$(grep -Fxv -f <(git show "HEAD:${rel}" 2>/dev/null || true) <<<"$added" || true)"
fi
if sup="$(grep -nE 'eslint-disable|@ts-(ignore|expect-error|nocheck)' <<<"$added")"; then
  out="This edit adds a lint or type suppression to ${rel}:
${sup}
Fix the finding instead, or justify the suppression in the PR."
fi

# The repo's own binaries, whatever installed them (pnpm, npm, yarn): a repo
# without node_modules, prettier or eslint is formatted or linted as far as
# it can be, never blocked.
if [ -x node_modules/.bin/prettier ]; then
  node_modules/.bin/prettier --log-level warn --write "$file" >/dev/null 2>&1 || true
fi
if [ -x node_modules/.bin/eslint ] && ! lint="$(node_modules/.bin/eslint "$file" 2>&1)"; then
  out="${out:+${out}

}eslint on ${rel}:
${lint}"
fi
[ -z "$out" ] && exit 0
printf '%s\n' "$out" >&2
exit 2
