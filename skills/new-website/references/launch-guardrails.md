# Launch guardrails — announcing deploys and protecting the edge cache

Read from SKILL.md §4's "Deploy-time guardrails" pointer. Two standing rules for
every deploy on a kit-built site: how to announce preview vs live to the owner,
and why a brand-new page must never be requested on the live domain before its
build is Active.

## Always say whether it's PREVIEW or LIVE (two-stage)

A non-technical owner cannot tell a preview URL from the live site. So **every time** you
push to `main` (or they do), state it explicitly — never let a preview read as live:

> ✅ Your changes are on the **preview**: `https://main.<project>.pages.dev` — **this is NOT
> live yet.** When it looks right, run `npm run ship` to publish to `<live-domain>`.

Only after `npm run ship` (or the merge into `production`) **and** the Cloudflare production
build finishes is it actually live at `<live-domain>` — confirm that separately ("✅ now
live at …"). On a **single-stage** site there is no preview: say plainly that the push **is
going live now**.

**Which URL to quote.** Prefer the **memorable `pages.dev` alias** — the branch alias
`main.<project>.pages.dev` (or the project alias `<project>.pages.dev`) — over the random
per-deploy hash URL `<hash>.<project>.pages.dev`. The hash URL is ugly but **immutable**, so
keep it as a **backup**: when an alias looks **stale** (cache/propagation lag, or it's still
serving an older build), the hash URL pins the exact fresh deployment and confirms the new
build is up. Whichever you quote, **open it and confirm it loads** rather than reporting it
blind — and note it for the project. (A `pages.dev` URL is also the signal you deployed to
**Pages**, not a Worker — see `CLOUDFLARE_FIRST_DEPLOY.md`.)

## Never request a page on the live domain before its build is Active

The edge caches whatever it first sees. If anyone — you, the owner's browser, a link
checker — requests a brand-new path on the live domain while the production build is still
running, a zone cache rule (Cache Everything on HTML) will cache the **404**, and a cached
404 does not reliably self-heal: observed surviving `cf-cache-status: HIT` more than 90
minutes past a 30-minute `max-age`, immune to plain re-requests. Only a **manual dashboard
purge** clears it (Cloudflare dashboard → the zone → Caching → Purge Cache → custom purge by
URL; wrangler's OAuth token has `zone (read)` only and cannot purge programmatically). So:

- Until the production deployment shows **Active**, verify new pages ONLY on the hash
  deployment URL (`<hash>.<project>.pages.dev`) — pre-Active the live domain still serves
  the *previous* deployment, so a brand-new path 404s there no matter how you request it.
  Check Active status without touching the live domain: `wrangler pages deployment list`,
  the `<project>.pages.dev` alias (Cloudflare's own domain, outside the zone cache), or
  ask the owner — NEVER poll the live custom domain to see whether the build is done.
  Once Active, check the live domain with a `?cb=<anything>` cache-bust first (under
  default cache settings that is a distinct cache key, so it cannot poison the bare URL).
- Touch the **bare canonical URL last**, after Active — and only then tell the owner the
  link is safe to open. Announcing a URL before Active invites the owner to click it —
  and that first request makes the edge cache the 404 for everyone.
- The same applies to GSC **Request Indexing**: Googlebot is served the same edge cache, so
  requesting indexing while a stale 404 is cached shows Google exactly the wrong thing.
- If a 404 does get cached anyway: ask the owner to run the single-URL purge in the
  Cloudflare dashboard (a human-only step — the agent has no dashboard access; path above),
  then re-verify.
