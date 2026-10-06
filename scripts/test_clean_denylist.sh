#!/usr/bin/env bash
#
# test_clean_denylist.sh — drives scripts/check_clean.sh's private-name check against a
# throwaway repo with a linked worktree.
#
# Why it exists: the name list is a gitignored file in the main checkout, so a linked
# worktree has no copy of it, and the check skipped itself there and still printed OK.
# Commits are made in worktrees, so the check was off exactly where it mattered: a client
# name reached main that way (2026-09-27). These cases pin that a worktree uses the main
# checkout's list, that a copy with no git still skips (and says so, on its OK line too),
# that CI's masked mode (CLEAN_MASK_NAMES=1) fails on a name without printing it,
# that scripts/ is scanned for names without the list matching itself, and that this repo's
# own short name in an issue or PR reference is not a leak. The names are made up; the
# real list never appears in this repo.
#
# Usage: bash scripts/test_clean_denylist.sh
set -u
if ! command -v git >/dev/null 2>&1; then
  echo "SKIP: test_clean_denylist.sh needs git (it builds a throwaway repo and worktree)"
  exit 0
fi
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/clean-denylist-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
git="git -c user.name=t -c user.email=t@t -c init.defaultBranch=main -c commit.gpgsign=false -c core.hooksPath=/dev/null"
fails=0
# expect <label> <exit code wanted> <text the output must contain, or ""> <dir>
expect() {
  local out rc
  out="$(cd "$4" && bash scripts/check_clean.sh 2>&1)"; rc=$?
  if [ "$rc" -eq "$2" ] && { [ -z "$3" ] || printf '%s' "$out" | grep -qF -- "$3"; }; then
    printf 'ok   %s\n' "$1"
  else
    printf 'FAIL %s (exit %s, wanted %s)\n%s\n' "$1" "$rc" "$2" "$out" | sed '2,$s/^/     /'
    fails=$((fails+1))
  fi
}

R="$T/repo"; W="$T/worktree"; N="$T/nogit"
mkdir -p "$R/scripts" "$R/skills" "$R/docs"
cp "$HERE/check_clean.sh" "$R/scripts/"
for f in README.md THIRD-PARTY-LICENSES.md SECURITY.md Makefile LICENSE; do : >"$R/$f"; done
printf 'plain notes\n' >"$R/docs/notes.md"
printf '# a skill\n' >"$R/skills/SKILL.md"
printf 'scripts/.clean-denylist\n' >"$R/.gitignore"
$git init -q "$R"; $git -C "$R" add -A; $git -C "$R" commit -qm base
printf '# made-up names\nzorblequux\nkarero\n' >"$R/scripts/.clean-denylist"
$git -C "$R" worktree add -q --detach "$W"

# The list itself sits in the scanned scripts/ folder and holds every name; it must not
# report itself.
expect "main checkout, clean: passes, and says names were checked" 0 "OK — no private names in:" "$R"
expect "worktree, clean: passes without skipping the list" 0 "OK — no private names in:" "$W"
if (cd "$W" && bash scripts/check_clean.sh 2>&1) | grep -q 'denylist skipped'; then
  printf 'FAIL worktree still reports the list as skipped\n'; fails=$((fails+1))
fi

printf 'ran the live check on zorblequux\n' >>"$W/docs/notes.md"
expect "worktree, a listed name: fails" 1 "zorblequux" "$W"

# Scripts ship in the handoff zip, and a client name once sat unnoticed in a script's
# comment because the name check skipped scripts/ along with the generic checks.
printf '#!/usr/bin/env bash\n# first tried on the zorblequux site\n' >"$R/scripts/tool.sh"
expect "a listed name in a scripts/*.sh comment: fails" 1 "scripts/tool.sh" "$R"
rm "$R/scripts/tool.sh"

# In the main checkout, where the list is read either way, so only the self-reference
# allowance decides these cases.
printf 'fixed in karero/website-builder#131\nsee https://github.com/karero/website-builder.\ngit clone https://github.com/karero/website-builder.git\nkarero/website-builder karero/website-builder,karero/website-builder\n' >"$R/docs/notes.md"
expect "this repo's own name in a reference: passes" 0 "OK —" "$R"
printf 'ran zorblequux; fixed in karero/website-builder#131\n' >"$R/docs/notes.md"
expect "a listed name beside a self-reference: still fails" 1 "zorblequux" "$R"
# The org name is split so this file, which the real check scans, holds no bare copy of it.
org="kar""ero"
printf 'see %s/website-builder-private\n' "$org" >"$R/docs/notes.md"
expect "a longer name that starts like this repo: fails" 1 "website-builder-private" "$R"
printf 'see other-%s/website-builder\n' "$org" >"$R/docs/notes.md"
expect "a longer name that ends like this repo: fails" 1 "other-$org" "$R"
printf 'plain notes\n' >"$R/docs/notes.md"
# GNU grep (CI's) reports a matching binary file on stderr, which the check used to discard.
printf 'ran zorblequux\0\n' >"$R/docs/blob.bin"
expect "a listed name in a binary file: fails" 1 "blob.bin" "$R"
rm "$R/docs/blob.bin"
printf 'ran zorblequux\n' >"$R/docs/notes:old.md"
expect "a listed name in a file whose name holds a colon: fails" 1 "zorblequux" "$R"
rm "$R/docs/notes:old.md"
# Hits in gitignored files are dropped; a file whose name only starts like an ignored path
# is not ignored, and was dropped too when the name was cut at its first colon.
printf 'docs/scratch\n' >>"$R/.gitignore"
printf 'ran zorblequux\n' >"$R/docs/scratch"
expect "a listed name in a gitignored file: passes" 0 "OK —" "$R"
printf 'ran zorblequux\n' >"$R/docs/scratch:notes.md"
expect "a listed name in a file named like an ignored path plus a colon: fails" 1 "scratch:notes.md" "$R"
rm "$R/docs/scratch" "$R/docs/scratch:notes.md"
# A pattern grep cannot compile is a scan error, which must fail the run, not read as clean.
cp "$R/scripts/.clean-denylist" "$T/list.bak"; printf 'zorble(\n' >>"$R/scripts/.clean-denylist"
expect "a broken pattern in the list: fails as a scan error" 1 "scan error" "$R"
# A list of nothing but comments checks no names, so it must not earn the names-checked OK.
printf '# no names yet\n' >"$R/scripts/.clean-denylist"
expect "a list with no names: the OK line says so" 0 "private-name check SKIPPED: scripts/.clean-denylist lists no names" "$R"
cp "$T/list.bak" "$R/scripts/.clean-denylist"

# CI runs with CLEAN_MASK_NAMES=1 and its logs are public: a hit must still fail the run,
# and no listed name may appear in the output, in any case, in the text or a file name.
# masked <label> <exit code wanted> <text the output must contain> [PATH prefix]
masked() {
  local out rc
  out="$(cd "$R" && PATH="${4:+$4:}$PATH" CLEAN_MASK_NAMES=1 bash scripts/check_clean.sh 2>&1)"; rc=$?
  if [ "$rc" -eq "$2" ] && printf '%s' "$out" | grep -qF -- "$3" && ! printf '%s' "$out" | grep -qi zorblequux; then
    printf 'ok   %s\n' "$1"
  else
    printf 'FAIL %s (exit %s, wanted %s)\n%s\n' "$1" "$rc" "$2" "$out" | sed '2,$s/^/     /'
    fails=$((fails+1))
  fi
}
printf 'ran ZorbleQuux and zorblequux\n' >"$R/docs/notes.md"
masked "masked: a listed name fails, and is not printed" 1 "docs/notes.md:1:ran [private name] and [private name]"
printf 'plain notes\n' >"$R/docs/notes.md"; printf 'ran zorblequux\n' >"$R/docs/zorblequux-notes.md"
masked "masked: a listed name in a file name is not printed either" 1 "docs/[private name]-notes.md:1:"
rm "$R/docs/zorblequux-notes.md"
# Masking must not undo the gitignore filter, which needs the real file name.
printf 'docs/*-scratch\n' >>"$R/.gitignore"; printf 'ran zorblequux\n' >"$R/docs/zorblequux-scratch"
masked "masked: a listed name in a gitignored file named after it: passes" 0 "OK — no private names in:"
rm "$R/docs/zorblequux-scratch"
# A name inside a word (`_`, digits) and a name that trips a generic check too (an email
# domain, a home path) printed in clear when only the name report was masked.
printf 'met zorblequux and the zorblequux_team, zorblequux2026\nwrite to bob@zorblequux.de\nsee /Users/zorblequux/x\n' >"$R/docs/zorblequux_notes.md"
masked "masked: names inside words, emails and home paths, and file names with _: not printed" 1 "✗ email address"
rm "$R/docs/zorblequux_notes.md"
# Masking the hits before report() filtered them again turned this hit into a pass: the
# masked name no longer existed, and its gitignored prefix did.
printf 'ran zorblequux\n' >"$R/docs/scratch:zorblequux.md"
masked "masked: a file named like an ignored path plus a colon and a name: still fails" 1 "personal/site identifier"
rm "$R/docs/scratch:zorblequux.md"
# perl's errors quote the whole pattern, every name in it: if perl fails, nothing is printed,
# and the run still fails.
mkdir -p "$T/badperl"; printf '#!/bin/sh\necho "Nested quantifiers in regex; m/zorblequux <-- HERE/" >&2\nexit 255\n' >"$T/badperl/perl"; chmod +x "$T/badperl/perl"
printf 'ran zorblequux\n' >"$R/docs/notes.md"
masked "masked: perl failing withholds everything and still fails" 1 "output is withheld" "$T/badperl"
# The same, with a clean tree: a masking failure must not pass either.
printf 'plain notes\n' >"$R/docs/notes.md"
masked "masked: perl failing on a clean tree: still fails" 1 "output is withheld" "$T/badperl"
# A pattern perl reads differently from grep leaves the name in place; grep finds it in the
# masked text, so the output is withheld. \< \> are word edges to grep, plain < > to perl.
printf 'a zorblequux b\n' >"$R/docs/notes.md"; printf '\\<zorblequux\\>\n' >"$R/scripts/.clean-denylist"
masked "masked: a pattern perl reads differently: output withheld" 1 "output is withheld"
cp "$T/list.bak" "$R/scripts/.clean-denylist"; printf 'plain notes\n' >"$R/docs/notes.md"

# A main checkout whose git data lives elsewhere (--separate-git-dir): git records no path to
# that checkout (it names the git folder instead), so the list cannot be found from a linked
# worktree. What matters is that the check never gives a bare OK: it finds the name (should
# git ever record that path) or says it skipped the list.
S="$T/sep"; SW="$T/sep-worktree"
mkdir -p "$S/scripts" "$S/skills" "$S/docs"
cp "$R/scripts/check_clean.sh" "$R/.gitignore" "$S/scripts/" 2>/dev/null; mv "$S/scripts/.gitignore" "$S/"
for f in README.md THIRD-PARTY-LICENSES.md SECURITY.md Makefile LICENSE; do : >"$S/$f"; done
printf '# a skill\n' >"$S/skills/SKILL.md"; printf 'plain notes\n' >"$S/docs/notes.md"
$git init -q --separate-git-dir "$T/sep.git" "$S"; $git -C "$S" add -A; $git -C "$S" commit -qm base
printf 'zorblequux\n' >"$S/scripts/.clean-denylist"
$git -C "$S" worktree add -q --detach "$SW"
printf 'ran the live check on zorblequux\n' >>"$SW/docs/notes.md"
out="$(cd "$SW" && bash scripts/check_clean.sh 2>&1)"; rc=$?
if { [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -qF zorblequux; } ||
   { [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -qF 'denylist skipped'; }; then
  printf 'ok   worktree of a --separate-git-dir checkout: finds the name or says it skipped\n'
else
  printf 'FAIL worktree of a --separate-git-dir checkout: a bare OK (exit %s)\n' "$rc"; fails=$((fails+1))
fi

# `make push-denylist` copies the list into the CLEAN_DENYLIST secret, through a fake gh that
# records what it was asked to send. It refuses a list CI would fail on or could not mask.
if command -v make >/dev/null 2>&1; then
  cp "$HERE/../Makefile" "$R/Makefile"; cp "$HERE/../Makefile" "$W/Makefile"
  mkdir -p "$T/fakegh"; cat >"$T/fakegh/gh" <<FAKE
#!/bin/sh
case "\$1 \$2" in
  "repo view") echo owner/repo ;;
  "secret set") { echo "args: \$*"; cat; } >"$T/gh.log" ;;
esac
FAKE
  chmod +x "$T/fakegh/gh"
  push() { # <label> <dir> <exit code wanted (make exits 2 when the recipe fails)> <text the output or the gh log must contain>
    local out rc; rm -f "$T/gh.log"
    out="$(cd "$2" && PATH="$T/fakegh:$PATH" make -s push-denylist 2>&1)"; rc=$?
    if [ "$rc" -eq "$3" ] && { printf '%s' "$out"; cat "$T/gh.log" 2>/dev/null; } | grep -qF -- "$4"; then
      printf 'ok   %s\n' "$1"
    else
      printf 'FAIL %s (exit %s, wanted %s)\n%s\n' "$1" "$rc" "$3" "$out" | sed '2,$s/^/     /'; fails=$((fails+1))
    fi
  }
  push "push-denylist: sends the list to the repo gh names" "$R" 0 "args: secret set CLEAN_DENYLIST --repo owner/repo"
  if [ "$(sed -n '2p' "$T/gh.log" 2>/dev/null)" != "# made-up names" ]; then
    printf 'FAIL push-denylist: the secret is not the list as written\n'; fails=$((fails+1))
  fi
  push "push-denylist: in a worktree, sends the main checkout's list" "$W" 0 "zorblequux"
  printf '# none yet\n' >"$R/scripts/.clean-denylist"
  push "push-denylist: refuses a list with no names" "$R" 2 "lists no names"
  printf 'zorblequux**\n' >"$R/scripts/.clean-denylist"
  push "push-denylist: refuses a pattern perl cannot read" "$R" 2 "perl cannot read"
  [ -f "$T/gh.log" ] && { printf 'FAIL push-denylist: gh was called for a refused list\n'; fails=$((fails+1)); }
  cp "$T/list.bak" "$R/scripts/.clean-denylist"; : >"$R/Makefile"; : >"$W/Makefile"
else
  echo "SKIP: push-denylist cases need make"
fi

# The workflow step that writes the list from the secret, run as written in clean.yml. The
# handoff zip carries no .github/, so there it is skipped, and says so.
WF="$HERE/../.github/workflows/clean.yml"
if [ -f "$WF" ]; then
  awk '/name: Write the private-name list/{f=1} f&&/run: \|/{r=1;next} r&&/^      [#-]/{exit} r{sub(/^          /,"");print}' "$WF" >"$T/step.sh"
  step() { # <label> <secret> <NO_SECRETS> <exit code wanted> <text the output must contain, or "">
    local out rc; rm -f "$T/stepdir/scripts/.clean-denylist"; mkdir -p "$T/stepdir/scripts"
    out="$(cd "$T/stepdir" && CLEAN_DENYLIST="$2" NO_SECRETS="$3" bash -e "$T/step.sh" 2>&1)"; rc=$?
    if [ "$rc" -eq "$4" ] && { [ -z "$5" ] || printf '%s' "$out" | grep -qF -- "$5"; }; then
      printf 'ok   %s\n' "$1"
    else
      printf 'FAIL %s (exit %s, wanted %s)\n%s\n' "$1" "$rc" "$4" "$out" | sed '2,$s/^/     /'; fails=$((fails+1))
    fi
  }
  step "CI step: a secret with names is written" "$(printf '# x\r\nzorblequux\r')" false 0 ""
  if [ "$(cat "$T/stepdir/scripts/.clean-denylist")" != "$(printf '# x\nzorblequux')" ]; then
    printf 'FAIL CI step: the list is not written as the secret holds it, less carriage returns\n'; fails=$((fails+1))
  fi
  step "CI step: a secret with no names fails" "# none yet" false 1 "lists no names"
  step "CI step: no secret where secrets exist fails" "" false 1 "secret is missing"
  step "CI step: no secret on a fork or Dependabot run warns" "" true 0 "::warning::"
else
  echo "SKIP: CI step cases need .github/workflows/clean.yml (not in the handoff zip)"
fi

mkdir -p "$N"; (cd "$W" && tar -cf - --exclude .git .) | tar -xf - -C "$N"
printf 'ran the live check on zorblequux\n' >>"$N/docs/notes.md"
expect "no git, no list: skips the list and says so" 0 "denylist skipped" "$N"
# CI has no list either. Its OK line is all a reader of the green run sees, so the skip
# must be there, not only in the earlier line.
expect "no git, no list: the OK line says names were skipped" 0 "private-name check SKIPPED: no scripts/.clean-denylist" "$N"
# With no git, check-ignore cannot drop the list's own lines; only the exclusion by path can.
printf 'plain notes\n' >"$N/docs/notes.md"; cp "$R/scripts/.clean-denylist" "$N/scripts/"
expect "no git, list present: the list does not report itself" 0 "OK — no private names in:" "$N"
# That exclusion is for the list's own path only: a file of the same name elsewhere ships.
cp "$R/scripts/.clean-denylist" "$N/docs/"
expect "no git, a copy of the list in docs/: fails" 1 "docs/.clean-denylist" "$N"
rm "$N/docs/.clean-denylist"
# grep prints file:line:text, so this file's lines start like the list's own.
printf 'ran zorblequux\n' >"$N/scripts/.clean-denylist:1:notes"
expect "no git, a file named like the list plus a colon: fails" 1 "zorblequux" "$N"
rm "$N/scripts/.clean-denylist:1:notes"

[ "$fails" -eq 0 ] && { echo "test_clean_denylist: all passed"; exit 0; }
echo "test_clean_denylist: $fails failed"; exit 1
