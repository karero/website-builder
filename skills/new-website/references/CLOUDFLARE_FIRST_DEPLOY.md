# First deploy to Cloudflare Pages — getting the site online the first time

`PUBLISHING.md` covers the **ongoing** `commit → push → rebuild` loop. This covers the
**one-time bootstrap**: creating the Cloudflare Pages project, the first deploy, and
(optionally) attaching the custom domain + turning on IndexNow. For someone who has never
touched Cloudflare, this is the hardest, most nerve-wracking part — so **offer to do it for
them** rather than handing over a dashboard tour.

> **Assistant: present the three options below and recommend (A) for anyone new to
> Cloudflare.** (B) and (C) are perfectly fine and stay on offer — they just cost the owner
> more time and patience. State the deploy-model tradeoff in (A) before they mint anything.

---

## A. Token-assisted bootstrap — RECOMMENDED for Cloudflare newcomers

The owner mints **one scoped, expiring API token**; you (the agent) run Wrangler to
create the project and deploy — **no dashboard for the deploy itself**. Two things the
token/Wrangler **cannot** do (confirmed against current Cloudflare docs, June 2026):
attach a custom domain (Wrangler has no Pages custom-domain command —
[workers-sdk#11772](https://github.com/cloudflare/workers-sdk/issues/11772) is open) and
enable Crawler Hints/IndexNow (it has [no API at all](https://community.cloudflare.com/t/how-do-i-enable-crawler-hints-through-the-api/384104)).
So this is the fastest path to "my site is live"; the custom domain and IndexNow are a
short dashboard visit afterwards (or the browser-assisted path in C).

**Tradeoff — state this up front:** this uses Wrangler's **direct-upload** deploy model.
Ongoing deploys are then `wrangler pages deploy`, **not** Cloudflare's git-push auto-build
that `PUBLISHING.md` assumes. A direct-upload project and a Git-connected project are
*different Pages project types* — pick (A) **or** (B), not both. If the owner wants
push-to-deploy afterwards, prefer (B). (A) is the right call when the priority is getting
live fast with zero dashboard time.

### The token — least-privilege, never the Global API Key

1. Dashboard → **My Profile → API Tokens → Create Token → Create Custom Token**.
2. **Permissions** — add only what the chosen steps need:
   - **Account › Cloudflare Pages › Edit** — create the project + deploy. *(required — the
     only permission the deploy itself needs.)*
   - **Zone › DNS › Edit**, scoped to the **one** zone — only if you'll attach the custom
     domain via the Cloudflare **REST API**. If you'll attach the domain in the dashboard
     instead (simpler), skip this. *(optional)*
   - *(There is no Crawler Hints permission — it has no API. Enable IndexNow via the single
     dashboard toggle in `search-console-setup`, whichever deploy path you pick.)*
3. **Account Resources:** include only the owner's account. **Zone Resources:** only the
   one target zone (never "All zones").
4. **Expiry:** set an **End date ~1 week out** — enough to bootstrap, then it dies on its own.
5. Create → copy the token (**shown once**).

### Hand it to the agent safely — never the repo

- Provide it as a session env var: `export CLOUDFLARE_API_TOKEN=…` (Wrangler reads this),
  or a gitignored `.dev.vars`. The starter `.gitignore` already excludes `.env*`/`.dev.vars`,
  and the `clean` CI gate scans for leaked tokens as a backstop.
- **Never** commit it, paste it into a tracked file, or put it in the README.

### Assistant guardrails (non-negotiable)

1. **Scoped token only.** If the owner offers a Global API Key or their password, decline
   and ask for a custom token with the permissions above.
2. **Expiring + minimal.** Confirm the token has an end date and only the needed scopes
   before using it; if it looks over-scoped (e.g. "All zones"), say so and ask them to narrow it.
3. **Never commit the credential** — env/`.dev.vars` only; rely on `.gitignore` + the `clean` gate.
4. **Confirm before each account-modifying command** — state what it will do (create project
   `X`, deploy, add a DNS record for `Y`) and run it only on the owner's go-ahead.
5. **Revoke when done** — once the site is live, tell the owner to delete the token
   (My Profile → API Tokens → ⋯ → Delete), or let the expiry retire it. Don't leave a live
   token lying around. And never drive these changes through blind screen control.

### Commands you run (token in env)

```bash
# 1. Create the Pages project (direct-upload).
npx wrangler pages project create <project> --production-branch <main|production>

# 2. Build, then deploy the static output.
npm run build
npx wrangler pages deploy dist --project-name <project>

# 3. Custom domain: NO Wrangler command exists for Pages custom domains.
#    Attach it in the dashboard (Workers & Pages -> your project -> Custom domains ->
#    Set up a domain), OR via the Cloudflare REST API using the Zone>DNS>Edit token.
```

Ongoing deploys under (A): re-run `wrangler pages deploy dist --project-name <project>`
(wrap it in `npm run ship` if you want one command — note the stock `ship.sh` targets the
git-push model of (B), so adapting it for direct-upload is a follow-up, not assumed here).
Then continue with `search-console-setup` for GSC/Bing + Crawler Hints.

---

## B. GitHub git-integration — RECOMMENDED if the owner wants push-to-deploy and no token

One-time guided dashboard connect, then `git push` builds automatically — the model
`PUBLISHING.md` assumes. No token, but the owner does the one-time OAuth connect:

Cloudflare → **Workers & Pages → Create → Pages → Connect to Git** → pick the repo →
framework preset **Astro**, build command `npm run build`, output directory `dist`. For a
two-stage site, set **Production branch = `production`** afterwards (see new-website §4).

## C. Browser-assisted or manual walk-through — the fallback

If the owner won't mint a token and won't do the dashboard alone: drive the dashboard via
your runtime's browser automation (**Claude in Chrome** under Claude Code; the agent's own
browser tool otherwise — see `search-console-setup`), or read them the clicks one by one.
Both work; both eat time and patience — which is why **(A) is recommended for true newcomers**.
