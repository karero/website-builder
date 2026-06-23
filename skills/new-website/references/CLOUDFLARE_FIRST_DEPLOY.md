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
create the project and deploy — **no dashboard for the deploy itself**. Two doc facts to
know (confirmed against current Cloudflare docs, June 2026):
- **Custom domain:** Wrangler has *no* Pages custom-domain command
  ([workers-sdk#11772](https://github.com/cloudflare/workers-sdk/issues/11772) is open),
  but the **Pages REST API can attach it with the same Pages-Edit token** — so the token
  *does* cover this, just not via the Wrangler CLI.
- **Crawler Hints / IndexNow:** [no API at all](https://community.cloudflare.com/t/how-do-i-enable-crawler-hints-through-the-api/384104) —
  it's the one dashboard toggle in `search-console-setup`, whatever deploy path you pick.

So this is the fastest path to "my site is live"; IndexNow is a short dashboard visit
afterwards (or the browser-assisted path in C).

**Tradeoff — state this up front:** this uses Wrangler's **direct-upload** deploy model.
Ongoing deploys are then `wrangler pages deploy`, **not** Cloudflare's git-push auto-build
that `PUBLISHING.md` assumes. A direct-upload project and a Git-connected project are
*different Pages project types* — pick (A) **or** (B), not both. If the owner wants
push-to-deploy afterwards, prefer (B). (A) is the right call when the priority is getting
live fast with zero dashboard time.

### The token — least-privilege, never the Global API Key

1. Dashboard → **My Profile → API Tokens → Create Token → Create Custom Token**.
2. **Permissions** — add only what the chosen steps need:
   - **Account › Cloudflare Pages › Edit** (a.k.a. `Pages Write`) — create the project,
     deploy, **and** attach a custom domain via the Pages REST API
     (`POST /accounts/{id}/pages/projects/{name}/domains`). *(required — and it's all the
     happy path needs.)*
   - **Zone › DNS › Edit**, scoped to the **one** zone — **only** if the flow also creates
     or changes DNS records itself. Attaching the custom domain does **not** need this on
     its own; skip it unless you're scripting DNS. *(optional)*
   - *(There is no Crawler Hints permission — it has no API. Enable IndexNow via the single
     dashboard toggle in `search-console-setup`, whichever deploy path you pick.)*
3. **Account Resources:** include only the owner's account. **Zone Resources:** only the
   one target zone (never "All zones").
4. **Expiry:** set an **End date ~1 week out** — enough to bootstrap, then it dies on its own.
5. Create → copy the token (**shown once**).

### Hand it to the agent safely — never the repo

- Provide it as a session env var: `export CLOUDFLARE_API_TOKEN=…` (Wrangler reads this),
  or a gitignored `.dev.vars` (also Wrangler-recognised). The starter `.gitignore` excludes
  `.env*` and `.dev.vars`, so it's the **primary** leak protection in a generated site.
  *(This suite repo additionally runs a `clean` CI gate that scans the distributed skill
  package for stray tokens — that gate does **not** run in generated sites.)*
- **Never** commit it, paste it into a tracked file, or put it in the README.

### Assistant guardrails (non-negotiable)

1. **Scoped token only.** If the owner offers a Global API Key or their password, decline
   and ask for a custom token with the permissions above.
2. **Expiring + minimal.** Confirm the token has an end date and only the needed scopes
   before using it; if it looks over-scoped (e.g. "All zones"), say so and ask them to narrow it.
3. **Never commit the credential** — env var or gitignored `.dev.vars` only; the starter
   `.gitignore` is the backstop.
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
#    Set up a domain), OR via the Pages REST API with the SAME Pages-Edit token:
#    POST /accounts/{id}/pages/projects/{project}/domains  {"name":"<domain>"}
#    (Zone>DNS>Edit is only needed if you also script the DNS record itself.)
```

> **`pages deploy`, not plain `deploy` — or you get a `workers.dev` URL.** These are static
> **Pages** sites: every command above is `wrangler pages …` and the deploy must print a
> **`<project>.pages.dev`** URL. A bare `wrangler deploy` (no `pages`) publishes a **Worker**
> and hands back a `*.workers.dev` URL instead — a real mistake we've seen on an older kit
> version. If you see `workers.dev`, stop: you deployed the wrong project type. Delete the
> stray Worker and re-run `wrangler pages deploy`.

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

---

## Going live: moving an existing domain's DNS to Cloudflare — verify twice

When the site replaces a domain that already serves mail and a live site elsewhere (a
rebuild migrating its DNS to Cloudflare), the cutover is the **single riskiest moment** — a
wrong or wrongly-proxied record silently breaks email or the site right when it goes live.
Treat it as a checklist *with* the owner, never a fire-and-forget edit:

1. **Import, then check every record twice.** When Cloudflare scans the existing zone it
   often misses records. Compare the imported set against the old DNS provider's export
   **entry by entry, twice** — A/AAAA, CNAME, **all MX**, and every TXT (SPF, DKIM, DMARC,
   verification tokens). A missing MX or SPF record = broken mail.
2. **Get a screenshot and double-check it.** Have the owner screenshot the final Cloudflare
   DNS table and pass it back so you can review it against the old zone before they flip the
   nameservers. A second pair of eyes catches the record that was dropped or mistyped.
3. **Know which records must NOT be proxied (grey cloud, DNS-only).** Cloudflare's orange
   "proxy" cloud only makes sense for the **HTTP(S) hosts you actually serve through
   Cloudflare** (apex + `www`). Everything else must stay **DNS-only**, or it breaks:
   - **MX records and the mail hostnames they point to** — proxying mail destroys delivery.
   - **SPF / DKIM / DMARC** and other **TXT** records (they aren't HTTP; proxy doesn't apply).
   - `autodiscover` / `autoconfig` / `_dmarc` / mail-subdomains.
   - Any record that must resolve to its **real origin IP** (e.g. a service expecting the
     true address, not Cloudflare's edge).
   Make sure the owner *understands* this distinction — don't just set it silently.
4. **Disable DNSSEC at the registrar before touching nameservers.** Check whether DNSSEC is
   enabled at the old provider/registrar; if it is, **turn it off first** (or follow
   Cloudflare's DNSSEC migration path). Flipping nameservers while the old DS record is still
   live leaves a signature chain Cloudflare can't satisfy — resolvers then return
   `SERVFAIL` and the domain goes dark. Re-enable DNSSEC in Cloudflare afterwards if wanted.
5. **Only after the passes agree and DNSSEC is handled**, change the nameservers / flip the
   apex. Then confirm the site loads on the live domain **and** send a test email both
   directions.

> Drive these changes *with* the owner, not through blind screen control — same guardrail as
> the bootstrap token steps above.
