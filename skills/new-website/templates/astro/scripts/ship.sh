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
git push origin main:production
echo "✓ Published. Cloudflare is building the live site now (live in ~1 minute)."
