#!/usr/bin/env bash
# Regression guard for the analytics switch in src/config.ts:
#   ANALYTICS.enabled = process.env.CF_PAGES_BRANCH === PROD_BRANCH
#
# Base.astro emits the Plausible <script> only when that is true, and the build decides it:
# Cloudflare sets CF_PAGES_BRANCH when it builds, and a deploy-by-command owner sets it by
# hand (PUBLISHING.md: `CF_PAGES_BRANCH=<production-branch> npm run build` for the live
# site, `CF_PAGES_BRANCH= npm run build` for a preview). Both ways it fails silently: off on
# the live site, it counts no visitors and nothing says so; on for a preview, every look at
# the preview is counted as a real visitor. The Playwright suite cannot see either, since it
# builds once with whatever the shell had. So this builds the site four ways, the way the
# docs tell the owner to, and reads the built HTML.
#
# It runs `astro build`, the step of `npm run build` that renders the pages and so decides
# the tag, into a temporary folder: the site's own dist/ is left alone. The two post-build
# steps after it touch heading ids and dist/build.txt only.
#
# Needs `npm ci` first. Each build takes a few seconds.
set -euo pipefail
CDPATH= cd -- "$(dirname -- "$0")/.."

# The production branch as this site names it ('production', or 'main' on a single-stage
# site), read from the line the gate compares against.
prod="$(sed -n "s/^export const PROD_BRANCH = '\([^']*\)';.*/\1/p" src/config.ts)"
if [ -z "$prod" ]; then
  echo "✗ analytics gate: no \"export const PROD_BRANCH = '…';\" line in src/config.ts to test against."
  exit 1
fi
# A branch Cloudflare builds as a preview: main on a two-stage site.
preview=main
[ "$prod" != main ] || preview=preview

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail=0
checked=0

# build <case> <unset|set> [value] — one `astro build` into $work/<case>, with
# CF_PAGES_BRANCH unset or set to value (which may be empty). Every case sets or unsets
# it explicitly, so a value in the calling shell cannot leak into a case.
build() {
  local name="$1" how="$2" value="${3-}" rc=0
  if [ "$how" = unset ]; then
    env -u CF_PAGES_BRANCH npx astro build --outDir "$work/$name" >"$work/$name.log" 2>&1 || rc=$?
  else
    CF_PAGES_BRANCH="$value" npx astro build --outDir "$work/$name" >"$work/$name.log" 2>&1 || rc=$?
  fi
  if [ "$rc" -ne 0 ] || [ ! -f "$work/$name/index.html" ]; then
    echo "✗ analytics gate: the $name build failed (exit $rc). Its last lines:"
    tail -n 20 "$work/$name.log"
    exit 1
  fi
}

# The tag Base.astro writes: <script defer data-domain="…" src="<scriptHost>/js/script.js">.
expect_on() {
  local name="$1" what="$2"
  checked=$((checked + 1))
  if grep -q 'data-domain="[^"]*" src="[^"]*/js/script\.js"' "$work/$name/index.html"; then
    echo "✓ $what: analytics script in index.html"
  else
    echo "✗ $what: NO analytics script in index.html — the live site would count no visitors."
    fail=1
  fi
}

# Off means off on every page, not just the home page.
expect_off() {
  local name="$1" what="$2" hits rc=0
  checked=$((checked + 1))
  # grep: 0 found, 1 none, 2 an error, which must not read as "none".
  hits="$(grep -rlE --include='*.html' 'data-domain=|/js/script\.js' "$work/$name")" || rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "✗ $what: grep failed (exit $rc), so the build was not checked."
    fail=1
  elif [ "$rc" -eq 1 ]; then
    echo "✓ $what: no analytics script on any page"
  else
    echo "✗ $what: analytics script found — every visit to this build would be counted as real:"
    printf '%s\n' "$hits" | sed "s|^$work/$name/|    |"
    fail=1
  fi
}

build live set "$prod"
expect_on live "CF_PAGES_BRANCH=$prod (the live build)"

build unset unset
expect_off unset "CF_PAGES_BRANCH unset (a plain npm run build)"

build empty set ""
expect_off empty "CF_PAGES_BRANCH= (a preview by command)"

build preview set "$preview"
expect_off preview "CF_PAGES_BRANCH=$preview (a preview branch)"

if [ "$fail" -eq 0 ]; then
  echo "✓ analytics gate: $checked builds, on only when CF_PAGES_BRANCH is '$prod'"
fi
exit "$fail"
