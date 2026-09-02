# Onboarding — the agent runs this wizard on first use

**When invoked and the user is NOT yet connected** (no token at
`~/.config/gsc-insights/token.json`), do **not** dump commands. Walk the user through
it like a friendly wizard, in the order below. Assume a non-technical site owner who
has never heard of an "API". Do the heavy lifting yourself; clearly flag which steps
only they can do.

### Step 1 — Sell the benefit FIRST (before asking for anything)
In 3–4 plain sentences, tell them what they get and why ~10 minutes is worth it:
- *"Google Search Console is **free** and shows the **real** words people typed into
  Google to find your site, exactly where you rank for each, and how often you get
  clicked — data no guesswork keyword tool has."*
- *"Once connected, I can tell you in seconds: the keywords you're **almost** on page 1
  for (your fastest wins), the pages that get seen but not clicked (a quick title fix),
  and — with a free add-on — who's beating you in the Top 10."*
- *"It's **read-only** and free. The one-time setup is ~10 minutes — I do most of it;
  you do three clicks inside Google's console that I'm not allowed to do for you."*

Then ask **"Want to connect it now?"** and only continue on a yes.

### Step 2 — Check what's already done; ask only for what's missing
So a returning user is never re-onboarded:
- token at `~/.config/gsc-insights/token.json` → **already connected**, skip to Step 5.
- `~/.config/gsc-insights/client_secret.json` exists → creds done; just venv + first run.
- venv at `~/.config/gsc-insights/venv` exists → deps done.

### Step 3 — The human-only steps ( 🧑 **you do this** )
You cannot click inside Google's console. Hand these over **one at a time** and wait —
do not paste all five at once. Reassure them it's one-time. **Console UI labels are
localized** — if the owner's Google account language isn't English, translate the
quoted labels for them (German: *APIs und Dienste → Bibliothek*, *Anmeldedaten →
Anmeldedaten erstellen → OAuth-Client-ID*, *Computeranwendung*, *Testnutzer*):
- 🧑 a. Open https://console.cloud.google.com → create or pick any project.
- 🧑 b. **APIs & Services → Library** → search & **enable "Google Search Console API"**.
- 🧑 c. **APIs & Services → Google Auth Platform → Audience** → add your Google email
       as a **Test user** (the "OAuth consent screen" was renamed Google Auth Platform).
- 🧑 d. **APIs & Services → Credentials → Create credentials → OAuth client ID →
       Desktop app → Create → Download JSON**.
- 🧑 e. Tell me where it downloaded (usually `~/Downloads`).

### Step 4 — Your steps ( 🤖 **I do this** )
- 🤖 Move their JSON to `~/.config/gsc-insights/client_secret.json`.
- 🤖 Build the venv + install deps (see SKILL.md's "One-time setup").
- 🤖 Run `gsc_query.py` once — **a browser opens for their single consent click**, then
  the token caches and every future run is silent.

### Step 5 — Confirm the connection in plain words
After the first successful run: *"✅ Connected — Google confirms you own `<site>`
(access: `<permissionLevel>`)."* If the property is freshly verified and the report is
near-empty, **say so honestly** — data accrues over days; that's not a failure.

### Step 6 — THEN teach them how to use it (SKILL.md's "Once connected"). Don't skip this.

### Step 7 — Ask about weekly tracking, for THIS site specifically
Every ad-hoc run now quietly builds position history on its own (Phase 1 auto-appends
to the history CSV), but that still only happens when someone remembers to ask. On
macOS, check `bash scripts/schedule_tracking.sh status <site>` (exact match for this
one domain — not `list`, whose sanitized labels can collide between different domains);
on Linux there's nothing to query (no systemd/cron integration here), so just ask
directly whether they already have a recurring job for this site. If it's not
scheduled, close onboarding by actually asking, not just mentioning it in passing:
*"Want me to also schedule this to check automatically once a week, so you don't have
to remember to ask? Takes one command, and it's specific to `<site>` — nothing else
changes."* Wait for a real yes before running `schedule_tracking.sh install` (SKILL.md's
"Weekly auto-tracking" — never auto-install). A no is a fine, complete answer; don't
re-ask later in the same session. This is a per-site decision — connecting a second
site later means asking again for that one, not assuming the first answer carries over.
The same check applies outside onboarding too: any ranking check on an already-connected
site that comes back "not scheduled" is a prompt to ask, not just a first-connection
step (see SKILL.md's "Once connected — how to use it").
