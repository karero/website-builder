#!/usr/bin/env bash
#
# test_git_stand_hook.sh — drives the site template's Claude Code sync hook
# (skills/new-website/templates/claude/hooks/git-stand.mjs) against throwaway repos.
#
# Why it exists: AGENTS.md §1 tells Claude Code to use the hook's report instead of
# fetching itself, so a hook that reports wrong ("nothing new" when there was news, a
# silent failure, a retry that never comes) makes a session work on a stale state without
# anyone knowing. Every case here was first found by hand or by a reviewer (PR #166 and
# karero/pur-architekten-v2#28); this pins them. It also checks that the settings template
# registers exactly the script the template ships, since a copied settings file without
# the script fails at every session start.
#
# Needs git and node; skips (exit 0) without them, and says so.
# Usage: bash scripts/test_git_stand_hook.sh
set -u
for t in git node; do
  command -v "$t" >/dev/null 2>&1 || { echo "SKIP: test_git_stand_hook.sh needs $t"; exit 0; }
done
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TPL="$HERE/../skills/new-website/templates/claude"
HOOK="$TPL/hooks/git-stand.mjs"
T="$(mktemp -d "${TMPDIR:-/tmp}/git-stand-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_SSH_COMMAND
git="git -c user.name=t -c user.email=t@t -c init.defaultBranch=main -c commit.gpgsign=false"
fails=0
check() { if [ "$2" = "$3" ]; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s (expected %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }
has() { case "$2" in *"$3"*) check "$1" yes yes ;; *) check "$1" "text '$3'" "$(printf '%s' "$2" | head -c 160)" ;; esac; }
# Set a file's mtime N minutes into the past, portably (no GNU touch -d).
age() { node -e 'const f=process.argv[1],t=new Date(Date.now()-process.argv[2]*60000);require("fs").utimesSync(f,t,t)' "$1" "$2"; }
# Run the hook: hook <mode> [stdin-json] — prints its stdout; field <json> <path> extracts.
START='{"source":"startup"}'   # a plain variable: bash 3.2 (macOS stock) parses it the same way
hook() { (cd "$T/work" && printf '%s' "${2:-$START}" | CLAUDE_PROJECT_DIR="$T/work" node "$HOOK" "$1"); }
field() { printf '%s' "$1" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{if(!s){console.log("<silent>");return}const j=JSON.parse(s);console.log(process.argv[1].split(".").reduce((o,k)=>o?.[k],j)??"")})' "$2"; }

# The settings template registers exactly the shipped script, for both events.
cmds="$(node -e 'const s=require(process.argv[1]);console.log(["SessionStart","UserPromptSubmit"].map(e=>s.hooks[e][0].hooks[0].command).join("\n"))' "$TPL/settings.json")"
check "settings: SessionStart runs the shipped hook in start mode" 'node "$CLAUDE_PROJECT_DIR/.claude/hooks/git-stand.mjs" start' "$(printf '%s\n' "$cmds" | sed -n 1p)"
check "settings: UserPromptSubmit runs it in prompt mode" 'node "$CLAUDE_PROJECT_DIR/.claude/hooks/git-stand.mjs" prompt' "$(printf '%s\n' "$cmds" | sed -n 2p)"
node --check "$HOOK" 2>/dev/null; check "hook parses" 0 $?

# A remote with main, a clone on a feature branch.
$git init -q --bare "$T/remote.git"
$git clone -q "$T/remote.git" "$T/seed" 2>/dev/null
(cd "$T/seed" && $git commit -q --allow-empty -m first && $git push -q origin main)
$git clone -q "$T/remote.git" "$T/work" 2>/dev/null
(cd "$T/work" && $git switch -q -c feat)
M="$T/work/.git/claude-git-stand"
push() { (cd "$T/seed" && $git commit -q --allow-empty -m "$1" && $git push -q origin main); }

out="$(hook start)"
check "start: event name" SessionStart "$(field "$out" hookSpecificOutput.hookEventName)"
has "start: first run lists the latest changes" "$(field "$out" systemMessage)" "Latest changes on main"
check "prompt within 2 h: silent" "<silent>" "$(field "$(hook prompt)" systemMessage)"

push "news one"; age "$M" 180
out="$(hook prompt)"
check "prompt after 2 h: event name" UserPromptSubmit "$(field "$out" hookSpecificOutput.hookEventName)"
has "prompt after 2 h: reports the new commit" "$(field "$out" systemMessage)" "news one"
has "prompt after 2 h: tells the assistant to relay it" "$(field "$out" hookSpecificOutput.additionalContext)" "Before the actual answer"

age "$M" 180
out="$(hook prompt)"
has "nothing new: says so" "$(field "$out" systemMessage)" "Nothing new on main since the last report"
check "nothing new: does not interrupt the assistant" "Automatic sync with GitHub: nothing new on main, no action needed." "$(field "$out" hookSpecificOutput.additionalContext)"

# Someone else fetched first: the commit is still reported (baseline = last report).
push "news two"; (cd "$T/work" && git fetch -q); age "$M" 180
has "after a manual fetch: still reported" "$(field "$(hook prompt)" systemMessage)" "news two"

# Offline: reported, and the next check comes in about 10 minutes, not 2 hours.
(cd "$T/work" && git remote set-url origin "http://127.0.0.1:9/none.git"); age "$M" 180
has "offline: failure reported" "$(field "$(hook prompt)" systemMessage)" "Sync with GitHub failed"
mins="$(node -e 'console.log(Math.round((Date.now()-require("fs").statSync(process.argv[1]).mtimeMs)/60000))' "$M")"
check "offline: retry due in about 10 minutes (marker set back 110)" 110 "$mins"
(cd "$T/work" && git remote set-url origin "$T/remote.git"); age "$M" 121
has "back online after the retry window: checks again" "$(field "$(hook prompt)" systemMessage)" "Checked again"

# A compaction is not a session start: inside 2 h it stays quiet.
check "compaction inside 2 h: silent" "<silent>" "$(field "$(hook start '{"source":"compact"}')" systemMessage)"

(cd "$T/work" && git checkout -q --detach)
has "detached HEAD: gets its own note" "$(field "$(hook start)" hookSpecificOutput.additionalContext)" "Detached HEAD"
(cd "$T/work" && git checkout -q feat)

echo x > "$T/work/x.txt"
has "unsaved changes at start: stop-and-ask note" "$(field "$(hook start)" hookSpecificOutput.additionalContext)" "Per AGENTS.md §1.1: stop"
rm "$T/work/x.txt"

mkdir "$T/nogit"
out="$(cd "$T/nogit" && printf '{}' | node "$HOOK" start)"; rc=$?
check "not a repository, outside a project: silent, exit 0" "0:" "$rc:$out"

[ "$fails" -eq 0 ] && echo "test_git_stand_hook: all passed" || { echo "test_git_stand_hook: $fails failed"; exit 1; }
