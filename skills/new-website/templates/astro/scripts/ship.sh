#!/usr/bin/env bash
# Publish: promote the current preview (`main`) to the live site (`production`).
# Two-stage sites only. Validates BEFORE doing anything so a beginner can't half-publish.
#
# template-version: 0.21
#   The website-builder release this revision ships in. Sites get their copy at
#   scaffold time and then diverge, so this is how you tell whether a site is current:
#   `grep template-version scripts/ship.sh`. Bump it when this file changes, and keep
#   tests/check_ship_push.sh's marker in step — that test asserts the two agree.
set -euo pipefail

# The fetch below and the push further down have to answer the same question from git's
# own words — "was that the network?" — so it gets ONE definition. Two copies of this
# pattern would drift the first time a newly-seen failure is added to only one of them,
# and the drift would be invisible: both greps still look plausible on their own.
# The mirror of the function below, and just as load-bearing: these all END in
# "fatal: Could not read from remote repository", so without taking them out first the
# network pattern claims them and the owner is told to just run it again. Host-key
# failures are the case that makes this a security matter and not only an annoyance —
# a changed host key can mean a machine-in-the-middle, and "try again" is the worst
# possible advice for it. (Both classifiers pre-filtered, but with DIFFERENT lists,
# until an independent review pointed out the drift the shared function below was
# extracted to prevent.)
looks_like_local_or_auth_failure() { # <file holding git's stderr>
  # "Permission to <repo> denied to <user>" is GitHub's actual wording and does NOT
  # contain "Permission denied" — it fell through to the network test, matched the
  # generic "Could not read from remote repository" there, and was retried as a blip.
  # Caught by an independent review after this list had been copied into other repos,
  # which is exactly why it is one definition per repo and not one per call site.
  grep -qE 'does not appear to be a git repository|Permission denied|Permission to [^[:space:]]+ denied|Repository not found|could not read Username|Authentication failed|remote: Invalid username or password|Host key verification failed|REMOTE HOST IDENTIFICATION HAS CHANGED' "$1"
}

looks_like_network_failure() { # <file holding git's stderr>
  grep -qE '^(ssh: connect to host |Connection (closed|reset) by |fatal: Could not read from remote repository)' "$1" \
    || grep -qE '^fatal: unable to access .*(Could not resolve host|Failed to connect|Connection (timed out|refused|reset)|Operation timed out|Recv failure|Send failure|Empty reply)' "$1" \
    || grep -qE '^(error: RPC failed; curl [0-9]+|fatal: early EOF|send-pack: unexpected disconnect|fatal: [Tt]he remote end hung up)' "$1"
}

branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" != "main" ]; then
  echo "✗ Run this from 'main' (you're on '$branch'). Try: git checkout main"; exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "✗ You have unsaved changes. Save + upload them first:"
  echo "    git add -A && git commit -m \"...\" && git push"; exit 1
fi
# Everything below needs an up-to-date view of the remote: the origin/production
# existence check, the local-vs-GitHub comparison, and the divergence check further
# down, which answers a question about the REMOTE from a local ref. A stale ref would
# let those answer confidently and wrongly. `set -e` would abort here on its own, but
# with a raw git error and no guidance — the wrong ending for the most likely way a
# publish fails before it even starts.
#
# So capture git's stderr and read it: a network failure is retried once and, if it
# fails again, reported as a blip; anything else is printed in full and stops the
# publish immediately, because retrying a missing remote or a dead credential just
# adds five seconds to the same answer.
#
# One scratch file, reused by the push below, so there is a single EXIT trap rather
# than two that would silently replace each other.
git_log="$(mktemp)"
trap 'rm -f "$git_log"' EXIT
if ! git fetch -q origin 2>"$git_log"; then
  # Only a NETWORK failure is worth a silent retry. A missing remote or expired
  # credentials would fail again five seconds later, and calling that "a network blip"
  # is the same misdiagnosis this script exists to stop making — so say it at once,
  # with git's own error, instead of hiding it behind a wait.
  #
  # Order matters, exactly as it does in the push classifier below. A misconfigured
  # remote ALSO ends in "fatal: Could not read from remote repository" — `git fetch`
  # with a bad origin prints "does not appear to be a git repository" and then that
  # line — so the not-a-network cases have to be taken out first, or the transport
  # pattern claims them. (Caught by tests/check_ship_push.sh, not by inspection.)
  if looks_like_local_or_auth_failure "$git_log"; then
    fetch_is_network=0
  elif looks_like_network_failure "$git_log"; then
    fetch_is_network=1
  else
    # Unrecognised: don't retry. Same call the push classifier makes — an unknown
    # failure is not evidence of a blip, and a wrong retry costs a wait and a lie.
    fetch_is_network=0
  fi
  if [ "$fetch_is_network" = 1 ]; then
    echo "⚠ Couldn't reach GitHub — retrying once."
    sleep 5
    if ! git fetch -q origin; then
      echo ""
      echo "✗ Publish stopped — couldn't fetch from GitHub, so nothing was checked."
      echo "  Every check below this point needs a current view of what's on GitHub, so"
      echo "  continuing could publish against stale information."
      echo "  Nothing was published and you're still safely on 'main'."
      echo "  This is almost always a network blip. Try again:  npm run ship"
      exit 1
    fi
  else
    # Same stream as the explanation below it: an owner capturing `npm run ship > log`
    # to send to whoever is helping must not get "the error is printed just above"
    # with nothing above it.
    cat "$git_log"
    echo ""
    echo "✗ Publish stopped — 'git fetch' failed, and not for a network reason."
    echo "  git's own error is printed just above — that's the one to read. A missing"
    echo "  'origin' remote and expired credentials both land here, and neither is"
    echo "  fixed by trying again."
    echo "  Nothing was published and you're still safely on 'main'."
    exit 1
  fi
fi
if ! git rev-parse --verify -q origin/production >/dev/null; then
  echo "✗ No 'production' branch on GitHub yet — this site isn't set up two-stage."; exit 1
fi
# Your copy and GitHub's must match before publishing — but WHICH WAY they differ
# decides what to do about it, and a plain `!=` can't tell. Telling someone whose copy
# is BEHIND to "run git push" sends them to the one command that cannot help (and that
# git will then reject), so ask which side moved and say the matching thing.
upstream="$(git rev-parse '@{u}' 2>/dev/null || true)"
if [ -z "$upstream" ]; then
  echo "✗ This branch isn't connected to GitHub yet. Run: git push -u origin main"; exit 1
fi
if [ "$(git rev-parse @)" != "$upstream" ]; then
  if git merge-base --is-ancestor @ "$upstream"; then
    echo "✗ GitHub has changes that aren't on your computer yet — publishing now would"
    echo "  put an OLDER version of the site live. Get them first:  git pull"
  elif git merge-base --is-ancestor "$upstream" @; then
    echo "✗ Your latest changes aren't uploaded yet. Run: git push"
  else
    echo "✗ Your copy and GitHub's have BOTH changed since they last matched."
    echo "  Sort that out before publishing:  git pull --no-rebase"
    echo "  (--no-rebase because plain 'git pull' refuses to guess when both sides have"
    echo "  moved.) If it then mentions a 'conflict', ask for help rather than guessing."
    echo "  Once it's clean:  git push"
  fi
  exit 1
fi

echo "→ Publishing main → production. This goes LIVE."
# Push main straight to the remote production branch — no local checkout, so a failure
# (rejected push, red pre-push gate, network) never strands the owner on production.
#
# Whether the branches diverged is a question that can be answered LOCALLY, from the
# fetch above — so answer it before touching the network, instead of inferring it from
# a failed push. That order is the whole point: a push fails for plenty of reasons that
# have nothing to do with the branches, and reporting those as "production has commits
# main doesn't" sends the owner hunting a conflict that isn't there, while warning them
# off the one thing that actually works — running it again. Seen in production: an SSH
# timeout to github.com printed the divergence message while production was simply two
# commits behind main and cleanly fast-forwardable.
if ! git merge-base --is-ancestor origin/production main; then
  echo ""
  echo "✗ Publish blocked — 'production' has commits that 'main' doesn't have."
  echo "  (e.g. it was published from elsewhere, or kept history from an older ship flow.)"
  echo "  Nothing was published and you're still safely on 'main'. Do NOT force-push —"
  echo "  ask for help to reconcile the two branches."
  exit 1
fi
# Divergence is settled above, so what remains is either a transport failure or a red
# pre-push gate — and those don't want the same response. A dead network wants "run it
# again"; a red gate wants "read the test output"; a connection that dies mid-upload
# can't honestly be called either way. So read git's own words and say which it was.
# `tee` keeps every line — including the pre-push build and test output — on screen
# while capturing it; nothing git says is swallowed either way.
push_tries=2
kind=""
for attempt in $(seq 1 "$push_tries"); do
  if git push origin main:production 2>&1 | tee "$git_log"; then
    push_rc=0
  else
    # `tee` sits in this pipeline, so `pipefail` fires when TEE fails (a full temp
    # filesystem) on a push that actually succeeded — and "nothing was published" after
    # the site has gone live is the worst thing this script could say. Read git's own
    # status, not the pipeline's.
    push_rc="${PIPESTATUS[0]}"
  fi
  if [ "$push_rc" = 0 ]; then
    kind=ok
    break
  fi
  # Classify from git's own words, anchored on the LINES git actually emits rather than
  # on bare phrases: the pre-push gate (a full build plus the test suite) writes into
  # this same log, so a failing test that quotes "rejected"/"fetch first" — or one that
  # reports "timed out" — must not be read as a divergence or as a dead network.
  if grep -q '▶ pre-push gate' "$git_log" && ! grep -q '✓ pre-push gate passed' "$git_log"; then
    # FIRST, because it decides whether anything else in this log came from git at all.
    # The gate ran and did not pass, so the push never reached the network: every other
    # arm below is about what the REMOTE said, and the remote never got a word in.
    # Anchoring a pattern to the start of a line proves its shape, never its author —
    # this is the only check here that establishes provenance.
    kind=other
  elif grep -qE '^ *! \[rejected\].*\((non-fast-forward|fetch first|stale info)\)|^hint: Updates were rejected' "$git_log"; then
    # The check above ruled out a pre-existing divergence seconds ago, so this is the
    # narrow race it cannot cover: production moved WHILE this was publishing.
    kind=raced
  elif looks_like_local_or_auth_failure "$git_log"; then
    # An SSH key, host-key or access problem also ends in "Could not read from remote
    # repository", so take it out of the connectivity arms below: re-running changes
    # nothing, and "your network blipped" would be its own misdiagnosis.
    kind=other
  elif grep -qE '^(fatal: ([Tt]he remote end hung up|early EOF)|error: RPC failed; curl [0-9]+|send-pack: unexpected disconnect)' "$git_log"; then
    # Dropped MID-TRANSFER: the connection was alive, so GitHub may already have taken
    # the update. Note WHY this doesn't retry, because the obvious reason is wrong — a
    # repeated non-force push of the same ref IS idempotent (it lands, or says
    # "Everything up-to-date", or is rejected if someone else moved the branch), so a
    # retry would be safe. It is not free: the pre-push gate has already run by this
    # point, so retrying spends another full build and test run on a state nobody can
    # describe yet. Handing that call to the owner, with a re-run that self-diagnoses in
    # one line, costs less than guessing on their behalf.
    kind=dropped
  elif looks_like_network_failure "$git_log"; then
    kind=unreachable
  else
    kind=other
  fi
  # Only a failure at CONNECT time is worth retrying, and only that one is cheap: git
  # connects to the remote before it runs the pre-push hook, so the build and the tests
  # never ran. Every other case would fail the same way two minutes later.
  if [ "$kind" != unreachable ] || [ "$attempt" -ge "$push_tries" ]; then break; fi
  echo ""
  echo "⚠ Couldn't reach GitHub. Nothing was published — retrying in 5s ($((attempt+1))/$push_tries)…"
  sleep 5
done

if [ "$kind" != ok ]; then
  # EVERY message below says two things, and a new arm must say both: what went wrong,
  # and WHAT STATE YOU ARE IN NOW. The cause alone is only half an answer — someone who
  # has just been told "the connection dropped" still doesn't know whether their site
  # changed, whether anything needs undoing, or what is safe to run next.
  #
  # Better still, where it is possible: LEAVE NO STATE TO DESCRIBE. This script gets
  # that for free — it pushes main:production without checking anything out, so a
  # failure cannot leave a half-finished local merge behind. A deploy script that DOES
  # need a local merge should restore the branch to its pre-merge tip after a failed
  # push rather than explain the drift: a state that no longer exists needs no
  # explanation and cannot trip the next run. Prefer undoing to documenting; document
  # only what you cannot undo — which is why `dropped` below refuses to guess.
  echo ""
  case "$kind" in
    raced)
      echo "✗ 'production' moved while this was publishing, so GitHub refused the push."
      echo "  Nothing was published and you're still safely on 'main'. Do NOT force-push —"
      echo "  run it again, and the check at the start will look at the new state and tell"
      echo "  you where things stand:"
      echo "    npm run ship"
      ;;
    unreachable)
      echo "✗ Couldn't reach GitHub — a network or SSH problem, not a branch problem."
      echo "  Nothing was published and you're still safely on 'main' ($push_tries tries;"
      echo "  git's own error is printed above). Nothing to reconcile, nothing to fix —"
      echo "  wait a moment, then run it again:"
      echo "    npm run ship"
      ;;
    dropped)
      echo "✗ The connection to GitHub dropped part-way through the upload."
      echo "  git's own error is printed above. This one is genuinely unclear — the"
      echo "  upload may or may not have completed — so this script won't guess."
      echo "  Run it again:"
      echo "    npm run ship"
      echo "  If it already landed, git says 'Everything up-to-date' and the live-site"
      echo "  checks run as normal."
      ;;
    *)
      echo "✗ The push failed, for a reason this script can't name."
      echo "  git's own error is printed above — that's the one to read. A red pre-push"
      echo "  gate (the build or the tests) lands here too and prints its failure above."
      echo "  Nothing was published and you're still safely on 'main'."
      ;;
  esac
  exit 1
fi
echo "✓ Pushed. Cloudflare is building the live site now."

# Push ≠ live: Cloudflare can silently stop building (webhook auth lapse — seen in
# production 2026-07-02: two green pushes, no deploy for 40+ min). So VERIFY: the
# build writes its commit SHA to /build.txt (scripts/build-marker.mjs); poll the
# live site until it serves the SHA we just pushed. Cache-busted query so the edge
# cache can't show us a stale answer.
sha="$(git rev-parse main)"
site="$(grep -oE "site:[[:space:]]*['\"]https?://[^'\"]+" astro.config.mjs 2>/dev/null | sed -E "s/site:[[:space:]]*['\"]//" | head -1 || true)"
# Strip a trailing slash: a misconfigured SITE.url ('https://x.com/') would build
# 'https://x.com//build.txt' — NOT reliably safe (varies by host; some hosts
# 307-redirect a double slash). curl -L below now follows such redirects, but keep
# the normalization: same as the llms-coverage guard applies to SITE.url.
site="${site%/}"
if [ -z "$site" ]; then
  echo "⚠ Couldn't read the site URL from astro.config.mjs — can't verify the deploy."
  echo "  Check it yourself in ~2 min: your live URL should show the change."
  exit 0
fi
echo "→ Verifying the live site serves this exact build (up to 4 min)…"
for i in $(seq 1 24); do
  sleep 10
  # -L: follow 3xx so a domain-level redirect (naked → www) can't yield an empty
  # body and a false "old build" verdict; the exact-SHA match keeps the check honest.
  live="$(curl -sfL -m 8 "$site/build.txt?cb=$RANDOM$i" 2>/dev/null | tr -d '[:space:]')" || true
  if [ "$live" = "$sha" ]; then
    echo "✓ LIVE — verified: $site is serving build ${sha:0:12} (after $((i*10))s)."
    exit 0
  fi
done
echo ""
echo "⚠ Pushed OK, but after 4 minutes the live site still serves an OLD build."
echo "  This usually means Cloudflare didn't build (it can stop silently). Check:"
echo "  Cloudflare dashboard → Workers & Pages → your project → Deployments."
echo "    • A failed deployment for ${sha:0:12} → open its log, then 'Retry deployment'."
echo "    • NO deployment for it → Settings → Builds: unpause / re-connect the GitHub"
echo "      integration, then 'Create deployment' from 'production'."
echo "  (Brand-new site whose domain isn't connected yet? Then this is expected —"
echo "  verify via the project's *.pages.dev URL instead.)"
exit 1
