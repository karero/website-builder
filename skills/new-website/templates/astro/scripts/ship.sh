#!/usr/bin/env bash
# Publish: promote the current preview (`main`) to the live site (`production`).
# Two-stage sites only. Validates BEFORE doing anything so a beginner can't half-publish.
set -euo pipefail

branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" != "main" ]; then
  echo "✗ Run this from 'main' (you're on '$branch'). Try: git checkout main"; exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "✗ You have unsaved changes. Save + upload them first:"
  echo "    git add -A && git commit -m \"...\" && git push"; exit 1
fi
git fetch -q origin
if ! git rev-parse --verify -q origin/production >/dev/null; then
  echo "✗ No 'production' branch on GitHub yet — this site isn't set up two-stage."; exit 1
fi
if [ "$(git rev-parse @)" != "$(git rev-parse '@{u}' 2>/dev/null || echo none)" ]; then
  echo "✗ Your latest changes aren't uploaded yet. Run: git push"; exit 1
fi

echo "→ Publishing main → production. This goes LIVE."
# Push main straight to the remote production branch — no local checkout, so a failure
# (rejected push, red pre-push gate, network) never strands the owner on production.
# Fast-forward only: if production has somehow diverged, this is rejected loudly rather
# than silently publishing the wrong thing.
if ! git push origin main:production; then
  echo ""
  echo "✗ Publish rejected — 'production' has commits that 'main' doesn't have."
  echo "  (e.g. it was published from elsewhere, or kept history from an older ship flow.)"
  echo "  Nothing was published and you're still safely on 'main'. Do NOT force-push —"
  echo "  ask for help to reconcile the two branches."
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
if [ -z "$site" ]; then
  echo "⚠ Couldn't read the site URL from astro.config.mjs — can't verify the deploy."
  echo "  Check it yourself in ~2 min: your live URL should show the change."
  exit 0
fi
echo "→ Verifying the live site serves this exact build (up to 4 min)…"
for i in $(seq 1 24); do
  sleep 10
  live="$(curl -sf -m 8 "$site/build.txt?cb=$RANDOM$i" 2>/dev/null | tr -d '[:space:]')" || true
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
