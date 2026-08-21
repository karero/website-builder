#!/usr/bin/env bash
# Regression guard for the push classifier in scripts/ship.sh.
#
# Nothing else exercises ship.sh — its only real workout is an actual publish, which
# is exactly why its failure messages were wrong three times before this existed. The
# worst of them: a transient `ssh: connect to host github.com port 22: Operation timed
# out` was reported as "'production' has commits that 'main' doesn't have … Do NOT
# force-push", sending the owner hunting for a divergence that did not exist, when the
# right move was simply to run it again. Every scenario below is a failure someone
# actually hit, or one a review of the fix found hiding inside it.
#
# Divergence itself is now decided locally, before the network, by
# `git merge-base --is-ancestor origin/production main` — deterministic, so it needs
# no test beyond "it blocks and never pushes". What is still prose-matching is the
# TRANSPORT half behind it, and that is exactly the kind of code that rots silently:
# an edited regex still runs, still exits, and only lies the next time a publish
# fails. This drives the real ship.sh with a stubbed `git` on PATH and
# asserts, per scenario, the exit code, how many pushes were attempted (the retry
# is only correct for connect-time failures) and which message the owner gets.
#
# The scratch cwd deliberately has no astro.config.mjs: that stops ship.sh right
# after the push, before it polls the live site, so the success cases stay offline.
#
# template-version: 0.21   (keep in step with scripts/ship.sh's marker)
set -euo pipefail
cd "$(dirname "$0")/.."
ship="$PWD/scripts/ship.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/teefail" "$work/cwd" "$work/cases"

# Stub git: canned answers for ship.sh's pre-flight checks, scripted push outcomes.
# Every push is logged so a scenario can assert the refspec as well as the count.
cat > "$work/bin/git" <<'STUB'
#!/bin/bash
SHA=1111111111111111111111111111111111111111
UP="$(cat "$FAKE_DIR/upstream" 2>/dev/null || echo "$SHA")"
case "$1" in
  rev-parse)
    case "$*" in
      *"--abbrev-ref HEAD"*) echo main ;;
      # `@{u}` is the branch's GitHub counterpart: absent on a branch never pushed,
      # and a DIFFERENT commit when the two have moved apart.
      *"@{u}"*) [ -f "$FAKE_DIR/noupstream" ] && exit 1; echo "$UP" ;;
      *"--verify -q origin/production"*) [ -f "$FAKE_DIR/noprod" ] && exit 1; echo "$SHA" ;;
      *) echo "$SHA" ;;
    esac ;;
  status) ;;
  fetch)
    n=$(( $(cat "$FAKE_DIR/fetches" 2>/dev/null || echo 0) + 1 ))
    echo "$n" > "$FAKE_DIR/fetches"
    if [ -s "$FAKE_DIR/fetchfail" ] && [ "$n" -le "$(cat "$FAKE_DIR/fetchfail")" ]; then
      # Default to a transport failure; a scenario can supply another reason instead,
      # because WHY the fetch failed decides whether retrying makes any sense.
      if [ -f "$FAKE_DIR/fetcherr" ]; then
        cat "$FAKE_DIR/fetcherr" >&2
      else
        echo "ssh: connect to host github.com port 22: Operation timed out" >&2
      fi
      exit 1
    fi ;;
  merge-base)
    # The argument ORDER carries the meaning here: reversing the two refs inverts the
    # check and would let a diverged production be published. A stub that answers any
    # invocation would keep this gate green through exactly that edit, so refuse
    # anything else loudly instead of answering it.
    case "$*" in
      "merge-base --is-ancestor origin/production main")
        [ -f "$FAKE_DIR/diverged" ] && exit 1 || exit 0 ;;
      "merge-base --is-ancestor @ "*)      # is your copy an ancestor of GitHub's? (behind)
        [ -f "$FAKE_DIR/behind" ] && exit 0 || exit 1 ;;
      "merge-base --is-ancestor "*" @")    # is GitHub's an ancestor of yours? (ahead)
        [ -f "$FAKE_DIR/ahead" ] && exit 0 || exit 1 ;;
      *) echo "STUB: unexpected merge-base invocation: git $*" >&2; exit 3 ;;
    esac ;;
  push)
    echo "$*" >> "$FAKE_DIR/pushes"
    n="$(wc -l < "$FAKE_DIR/pushes" | tr -d ' ')"
    [ -f "$FAKE_DIR/$n.out" ] || n=1
    cat "$FAKE_DIR/$n.out" >&2
    exit "$(cat "$FAKE_DIR/$n.code")" ;;
  *)
    # No silent success for a subcommand nobody taught this stub. An unmatched `case`
    # exits 0 with empty output, which is exactly the "still runs, still exits, only
    # lies" rot this file exists to catch — so refuse loudly instead.
    echo "STUB: unexpected git invocation: git $*" >&2; exit 3 ;;
esac
STUB
chmod +x "$work/bin/git"

# Stub sleep: the retry path waits 5s, which this gate should not pay for.
printf '#!/bin/sh\nexit 0\n' > "$work/bin/sleep"; chmod +x "$work/bin/sleep"

# Stub curl: this gate must never touch the network. Today the success cases stop
# before ship.sh's live-site poll only because the scratch cwd has no astro.config.mjs
# — an implicit property of how ship.sh looks up the URL, not something this test
# controls. Make it explicit: if that lookup ever becomes repo-relative or gains a
# default, this stub is what stops 24 no-delay requests hitting the production site on
# every push, and turns it into a loud failure instead.
printf '#!/bin/sh\necho "STUB: curl must not run in this gate: $*" >&2\nexit 7\n' > "$work/bin/curl"; chmod +x "$work/bin/curl"

# Stub tee: passes input through but writes no file, as a full temp filesystem would.
printf '#!/bin/sh\ncat\nexit 1\n' > "$work/teefail/tee"; chmod +x "$work/teefail/tee"

mark() { # mark <case> <marker> [count]; sets up a pre-flight condition
  # Defaults to 1 rather than empty: the fetch stub gates on a NON-EMPTY marker, so an
  # omitted count would leave the scenario passing without ever failing a fetch.
  mkdir -p "$work/cases/$1"
  printf '%s' "${3:-1}" > "$work/cases/$1/$2"
}

attempt() { # attempt <case> <n> <exit-status>; git's output for that attempt on stdin
  mkdir -p "$work/cases/$1"
  cat > "$work/cases/$1/$2.out"
  echo "$3" > "$work/cases/$1/$2.code"
}

fail=0

# The marker exists so a site can check whether its copy is current with one grep. Two
# files carry it, so assert they agree rather than trusting a comment to keep them so.
# The SAME extraction on both sides: written differently, a trailing comment on one
# marker line would make the two "disagree" over no real drift. And both must be
# non-empty, or deleting both markers would satisfy the check that exists to prove
# they are there.
version_of() { sed -n 's/^# template-version: *\([^ ]*\).*/\1/p' "$1" | head -1; }
ship_version="$(version_of "$ship")"
gate_version="$(version_of "$0")"
if [ -z "$ship_version" ] || [ -z "$gate_version" ]; then
  echo "✗ ship push gate: a template-version marker is missing (ship.sh: '$ship_version',"
  echo "  this file: '$gate_version'). The marker is how a site checks whether its copy"
  echo "  is current; without it that check silently answers nothing."
  fail=1
elif [ "$ship_version" != "$gate_version" ]; then
  echo "✗ ship push gate: template-version disagrees — ship.sh says '$ship_version',"
  echo "  this file says '$gate_version'. Bump both, or a site grepping either one gets"
  echo "  a different answer about how current it is."
  fail=1
fi

checked=0
expect() { # expect <case> <exit> <pushes> <message-fragment> [extra-PATH-dir]
  checked=$((checked + 1))
  local name="$1" want_exit="$2" want_pushes="$3" marker="$4" extra="${5:-}"
  local dir="$work/cases/$name" log="$work/$name.log" path="$work/bin:$PATH" got_exit pushes
  [ -n "$extra" ] && path="$extra:$path"
  rm -f "$dir/pushes" "$dir/fetches"; : > "$dir/pushes"
  ( cd "$work/cwd" && FAKE_DIR="$dir" PATH="$path" bash "$ship" > "$log" 2>&1 ) && got_exit=0 || got_exit=$?
  pushes="$(wc -l < "$dir/pushes" | tr -d ' ')"
  if [ "$got_exit" != "$want_exit" ]; then
    echo "✗ ship push gate [$name]: exit $got_exit, expected $want_exit"; fail=1
  fi
  if [ "$pushes" != "$want_pushes" ]; then
    echo "✗ ship push gate [$name]: $pushes push attempt(s), expected $want_pushes"
    echo "  (the automatic retry is only correct for a failure at connect time —"
    echo "   anything later has already paid for a full build and test run.)"; fail=1
  fi
  # The wording matters: this script exists because the WRONG message was printed on a
  # publish that failed for another reason. But these fragments are English, and this
  # template is meant to be translated — SKILL.md calls a German-only site a normal
  # answer. So the check stays hard by default and names its own escape hatch, rather
  # than leaving a translated site with permanently red CI and no clue why.
  # Anything but empty/0/false/no counts as "skip": someone reaching for this has
  # already read a failure telling them to set it, and `=true` should not silently
  # produce the identical red build a second time.
  local skip_wording=0
  case "${SHIP_GATE_SKIP_WORDING:-}" in ''|0|false|no) skip_wording=0 ;; *) skip_wording=1 ;; esac
  if ! grep -qF "$marker" "$log" && [ "$skip_wording" = 0 ]; then
    echo "✗ ship push gate [$name]: the owner was not told \"$marker\". Got:"
    sed -n -E '/^(✗|⚠)/,$p' "$log" | sed 's/^/    /'
    echo "  (Translated ship.sh's messages? Update the fragments in this file, or run"
    echo "   with SHIP_GATE_SKIP_WORDING=1 to check behaviour only. Exit codes and push"
    echo "   counts are asserted either way.)"
    fail=1
  fi
  # Whatever the verdict, git's own words must reach the owner — they are the one
  # part of the output that is never a guess.
  for fixture in "$dir/1.out" "$dir/fetcherr"; do
    # fetcherr as well as the push output: checking only the push fixtures left the
    # non-network fetch path free to stop printing git's error with this guard green.
    if [ -f "$fixture" ] && ! grep -qF "$(head -1 "$fixture")" "$log"; then
      echo "✗ ship push gate [$name]: git's own error was swallowed ($(basename "$fixture"))."; fail=1
    fi
  done
  # B10: the success cases stay offline because the scratch cwd has no astro.config.mjs
  # — an emergent property of ship.sh's URL lookup, not a contract. Assert the poll
  # never starts, so a future change that reaches it fails here rather than issuing
  # real requests at the live site, whatever tool it reaches for.
  if [ "$want_exit" = 0 ] && grep -q "Verifying the live site" "$log"; then
    echo "✗ ship push gate [$name]: the live-site poll started — this gate must stay offline."; fail=1
  fi
}

# --- the fetch that everything below depends on -----------------------------------
# Every check that follows reads the remote through a local ref, so a failed fetch must
# stop the publish rather than let them answer confidently from stale information.
mark fetchfail fetchfail 2
expect fetchfail 1 0 "couldn't fetch from GitHub"

# ...and a fetch that only blipped must NOT stop it: that is what the retry is for.
mark fetchblip fetchfail 1
attempt fetchblip 1 0 <<'EOF'
To github.com:you/your-site.git
   1111111..2222222  main -> production
EOF
expect fetchblip 0 1 "✓ Pushed"
# ...and exactly one retry, not more: the push scenarios pin their attempt count for the
# same reason, since "how many times do we try" is a deliberate decision either way.
if [ "$(cat "$work/cases/fetchblip/fetches")" != 2 ]; then
  echo "✗ ship push gate [fetchblip]: $(cat "$work/cases/fetchblip/fetches") fetch attempt(s), expected 2"
  fail=1
fi

# ...but a fetch that failed for a NON-network reason must stop at once. Retrying a
# missing remote or expired credentials just adds a 5s wait to the same failure, and
# announcing it as a network blip is the very misdiagnosis this script exists to stop.
mark fetchbroken fetchfail 2
mkdir -p "$work/cases/fetchbroken"
cat > "$work/cases/fetchbroken/fetcherr" <<'EOF'
fatal: 'origin' does not appear to be a git repository
fatal: Could not read from remote repository
EOF
expect fetchbroken 1 0 "not for a network reason"
if [ "$(cat "$work/cases/fetchbroken/fetches")" != 1 ]; then
  echo "✗ ship push gate [fetchbroken]: $(cat "$work/cases/fetchbroken/fetches") fetch attempt(s), expected 1 (no retry)"
  fail=1
fi

# ...and a fetch failure the classifier does NOT recognise stops too. An unknown
# failure is not evidence of a blip, so it must not buy a retry — this is the branch
# that decides an unfamiliar git error is reported rather than waited on.
mark fetchweird fetchfail 2
mkdir -p "$work/cases/fetchweird"
cat > "$work/cases/fetchweird/fetcherr" <<'EOF'
error: cannot lock ref 'refs/remotes/origin/main': is at 1111111 but expected 2222222
EOF
expect fetchweird 1 0 "not for a network reason"
if [ "$(cat "$work/cases/fetchweird/fetches")" != 1 ]; then
  echo "✗ ship push gate [fetchweird]: $(cat "$work/cases/fetchweird/fetches") fetch attempt(s), expected 1 (no retry)"
  fail=1
fi

# --- your copy vs GitHub's: WHICH WAY they differ decides the advice ---------------
# A plain `!=` cannot tell, and telling someone who is BEHIND to "git push" sends them
# to the one command that cannot help. These three assert the direction is read.
mark behind upstream 2222222222222222222222222222222222222222
mark behind behind
expect behind 1 0 "GitHub has changes that aren't on your computer yet"

mark ahead upstream 2222222222222222222222222222222222222222
mark ahead ahead
expect ahead 1 0 "Your latest changes aren't uploaded yet"

mark bothmoved upstream 2222222222222222222222222222222222222222
expect bothmoved 1 0 "BOTH changed"

# --- a brand-new site whose branch has never been pushed --------------------------
mark noupstream noupstream
expect noupstream 1 0 "isn't connected to GitHub yet"

# --- a two-stage site that isn't set up as one: the guard must be able to fire ----
mark noprod noprod
expect noprod 1 0 "isn't set up two-stage"

# --- a changed host key is a SECURITY signal, never a blip to retry ---------------
# Both of these end in "fatal: Could not read from remote repository", so without the
# pre-filter the network arm claims them and tells the owner to just run it again —
# which for a possible machine-in-the-middle is the worst advice available.
attempt hostkey 1 1 <<'EOF'
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Host key verification failed.
fatal: Could not read from remote repository.
EOF
expect hostkey 1 1 "can't name"

# --- an HTTPS credential failure: the fetch path filtered it, the push path did not
attempt httpsauth 1 1 <<'EOF'
fatal: Authentication failed for 'https://github.com/you/your-site.git/'
fatal: Could not read from remote repository.
EOF
expect httpsauth 1 1 "can't name"

# --- provenance: a line's SHAPE is not its AUTHOR --------------------------------
# The gate's output shares this log with git's. Anchoring proves a line looks like a
# transport error or a rejection; only the gate's own markers prove who wrote it. If
# the gate ran and did not pass, the push never reached the network.
attempt gatequotesssh 1 1 <<'EOF'
▶ pre-push gate: tests…
  ✘ 7 [chromium] › tests/links.spec.ts:9:3 › the docs page's git troubleshooting block renders
    Error: expected page to contain the sample error, got:
ssh: connect to host github.com port 22: Operation timed out
  42 tests, 1 failed
error: failed to push some refs to 'github.com:you/your-site.git'
EOF
expect gatequotesssh 1 1 "can't name"

attempt gatequoteshint 1 1 <<'EOF'
▶ pre-push gate: tests…
  ✘ 8 [chromium] › tests/tone.spec.ts:52:3 › no banned phrasing on /blog/git-for-beginners
    Error: banned phrase found. Page text was:
hint: Updates were rejected because the tip of your current branch is behind
  42 tests, 1 failed
error: failed to push some refs to 'github.com:you/your-site.git'
EOF
expect gatequoteshint 1 1 "can't name"

# --- a genuine divergence: answered locally, so NO push is attempted ------------
# This is the case the scary message is written for, and the check that decides it
# runs off the fetch above — before the network, so a transport failure can never be
# mistaken for it. Zero push attempts is the assertion that matters here.
mkdir -p "$work/cases/diverged"; : > "$work/cases/diverged/diverged"
expect diverged 1 0 "Publish blocked"

# --- production moves DURING the publish: the race the local check can't cover ---
attempt raced 1 1 <<'EOF'
To github.com:you/your-site.git
 ! [rejected]        main -> production (non-fast-forward)
error: failed to push some refs to 'github.com:you/your-site.git'
hint: Updates were rejected because the tip of your current branch is behind
EOF
expect raced 1 1 "moved while this was publishing"

# --- the 2026-08-20 incident, verbatim: must NOT read as a divergence -----------
attempt sshtimeout 1 1 <<'EOF'
ssh: connect to host github.com port 22: Operation timed out
fatal: Could not read from remote repository.
EOF
expect sshtimeout 1 2 "not a branch problem"

# --- a blip that clears: the retry is the whole point of classifying it ---------
attempt sshthenok 1 1 <<'EOF'
ssh: connect to host github.com port 22: Operation timed out
fatal: Could not read from remote repository.
EOF
attempt sshthenok 2 0 <<'EOF'
To github.com:you/your-site.git
   16bf04a..5e78e56  main -> production
EOF
expect sshthenok 0 2 "✓ Pushed"

# --- the retry connects, and then the gate goes red: `kind` must be reassigned ---
# The only path where the classification changes between loop iterations. Getting it
# wrong means a red test suite reported as "couldn't reach GitHub, run it again".
attempt blipthengate 1 1 <<'EOF'
ssh: connect to host github.com port 22: Operation timed out
fatal: Could not read from remote repository.
EOF
attempt blipthengate 2 1 <<'EOF'
▶ pre-push gate: tests…
  Error: page.goto: Timeout 30000ms exceeded. Navigation timed out.
  42 tests, 1 failed
error: failed to push some refs to 'github.com:you/your-site.git'
EOF
expect blipthengate 1 2 "can't name"

# --- other transports, same verdict --------------------------------------------
attempt kexclosed 1 1 <<'EOF'
kex_exchange_identification: Connection closed by remote host
Connection closed by 140.82.121.4 port 22
fatal: Could not read from remote repository.
EOF
expect kexclosed 1 2 "not a branch problem"

attempt dnsfail 1 1 <<'EOF'
fatal: unable to access 'https://github.com/you/your-site.git/': Could not resolve host: github.com
EOF
expect dnsfail 1 2 "not a branch problem"

# --- dropped MID-transfer: the ref may already have landed, so no guessing ------
# and no retry — by this point the pre-push gate has already run for real.
attempt dropped 1 1 <<'EOF'
Writing objects: 100% (7/7), 640 bytes | 640.00 KiB/s, done.
error: RPC failed; curl 56 Recv failure: Connection reset by peer
fatal: the remote end hung up unexpectedly
EOF
expect dropped 1 1 "may or may not have completed"

# --- a red pre-push gate is not a network problem and not a divergence ----------
attempt hookfail 1 1 <<'EOF'
▶ pre-push gate: tests…
  Error: page.goto: Timeout 30000ms exceeded. Navigation timed out.
  42 tests, 1 failed
error: failed to push some refs to 'github.com:you/your-site.git'
EOF
expect hookfail 1 1 "can't name"

# --- and a red gate whose OUTPUT quotes git advice still isn't a divergence -----
# This is why the patterns are anchored to the lines git itself emits: the gate's
# build and test output lands in the same log the classifier reads.
attempt gatequotesgit 1 1 <<'EOF'
▶ pre-push gate: tests…
  ✘ 12 [chromium] › tests/tone.spec.ts:52:3 › tone — no banned phrasing on /blog/git-for-beginners
    Error: banned phrase found. Page text was:
      "…if your push is rejected, fetch first, then push again…"
error: failed to push some refs to 'github.com:you/your-site.git'
EOF
expect gatequotesgit 1 1 "can't name"

# --- an access problem: real, but "run it again" would be its own misdiagnosis --
attempt nokey 1 1 <<'EOF'
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
EOF
expect nokey 1 1 "can't name"

# --- GitHub's ACTUAL permission wording, which says neither "Permission denied" ---
# nor anything network-ish. It ends in "Could not read from remote repository" like
# every other access failure, so before the auth list covered it the network arm
# claimed it and retried. Found by review after the list was in four repos.
attempt permdenied 1 1 <<'EOF'
ERROR: Permission to you/your-site.git denied to someone-else.
fatal: Could not read from remote repository.
EOF
expect permdenied 1 1 "can't name"

# --- mid-transfer disconnects, one alternative per fixture so either breaking shows
attempt rpconly 1 1 <<'EOF'
Enumerating objects: 12, done.
error: RPC failed; curl 92 HTTP/2 stream 5 was not closed cleanly
EOF
expect rpconly 1 1 "may or may not have completed"

attempt sendpackonly 1 1 <<'EOF'
Writing objects: 100% (7/7), done.
send-pack: unexpected disconnect while reading sideband packet
EOF
expect sendpackonly 1 1 "may or may not have completed"

# --- "error: RPC failed" is an UMBRELLA: HTTP 401/403 wear it too, and they are not
# transient. Requiring curl's own error number after the semicolon tells them apart.
# 413 rather than 403 on purpose: a 403 also prints "Authentication failed", which the
# auth arm catches anyway, so it would not isolate this. A payload-too-large has no auth
# line at all — with the umbrella pattern it read as a mid-transfer drop.
attempt rpc413 1 1 <<'EOF'
error: RPC failed; HTTP 413 curl 22 The requested URL returned error: 413
EOF
expect rpc413 1 1 "can't name"

# --- a persistent protocol fault is a configuration problem, not a blip -----------
attempt protocolfault 1 1 <<'EOF'
fatal: protocol error: bad line length character: Inva
EOF
expect protocolfault 1 1 "can't name"

# --- the credential wording that had no fixture. It guards the arm rather than proving
# the new alternative: "Authentication failed" on the next line already matched.
attempt badcreds 1 1 <<'EOF'
remote: Invalid username or password.
fatal: Authentication failed for 'https://github.com/you/your-site.git/'
fatal: Could not read from remote repository.
EOF
expect badcreds 1 1 "can't name"

# --- a clean publish -----------------------------------------------------------
attempt okpush 1 0 <<'EOF'
To github.com:you/your-site.git
   16bf04a..5e78e56  main -> production
EOF
expect okpush 0 1 "✓ Pushed"

# ...and the same push when tee fails. `tee` sits in the pipeline, so pipefail
# reports a SUCCESSFUL push as a failure unless git's own status is read.
# Announcing "nothing was published" after the site has gone live is the worst
# lie this script can tell, so it gets its own case.
expect okpush 0 1 "✓ Pushed" "$work/teefail"

# --- nothing but main:production may ever be pushed to the live branch ----------
if [ "$(cat "$work/cases/okpush/pushes")" != "push origin main:production" ]; then
  echo "✗ ship push gate: ship.sh pushed '$(cat "$work/cases/okpush/pushes")',"
  echo "  expected exactly 'push origin main:production' — a local checkout of"
  echo "  production is what the no-checkout push exists to avoid."
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "✓ ship push gate: $checked publish outcomes classified correctly (fetch, ahead/behind, divergence, race, network, mid-transfer drop, red gate, access, clean)"
fi
exit "$fail"
