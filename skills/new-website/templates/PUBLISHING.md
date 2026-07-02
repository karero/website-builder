# Publishing your site — a plain-English guide

This explains how your changes get onto the internet. **No prior git knowledge needed** —
read the glossary once, then follow the steps for your site's model.

---

## The five words you'll see (in plain English)

| Word | What it actually means |
|---|---|
| **commit** | **Save a snapshot** of your changes on your own computer, with a short note describing them. Nothing is online yet — it's like saving a document. |
| **push** | **Upload** your saved snapshots to GitHub (the cloud). This is what triggers a build. |
| **branch** | A **named line of work**. Your site has up to two: `main` and (sometimes) `production`. Think of them as "the draft" and "the published version." |
| **checkout** | **Switch** which branch you're looking at / working on. `git checkout main` = "show me the draft." |
| **merge** | **Copy the changes** from one branch into another — e.g. take everything in `main` and bring it into `production` to publish. |

A normal edit is always the same three moves: **commit** (save) → **push** (upload) →
the site rebuilds automatically. The only question is *which branch* you push to, and that's
what your model below decides.

---

## Which model is your site? (check your README)

Your site uses **one** of these. If you're not sure, your README's "Deploy" section says
which, or just look at your branches: only `main` = single-stage; `main` **and**
`production` = two-stage.

---

## Two-stage (recommended) — "preview first, then publish"

`main` is an **unlisted, noindexed preview**; `production` is the **live** site. You can
push freely to `main` — nothing reaches your live domain until you publish. (Search engines
are told to ignore the preview, but it isn't password-protected: **anyone who has the preview
URL can open it.** Don't put confidential content on a preview unless the project is behind
Cloudflare Access or similar.)

**Every time you change the site:**

```bash
# 1. Save your changes (a snapshot + a short description)
git add -A
git commit -m "describe what you changed, e.g. update opening hours"

# 2. Upload them — this builds your NOINDEXED PREVIEW (not on the live domain yet)
git push

# 3. Look at the preview. Open the preview link from Cloudflare
#    (stable address: main.<your-project>.pages.dev) and check it's right.

# 4. Happy? Publish it to the live site — ONE command:
npm run ship
```

`npm run ship` uploads `main` to the live (`production`) branch for you — you never run the
branch commands by hand. Then it **waits and verifies** that the live site really serves the
new version (every build stamps its id into `/build.txt`; ship polls for it, up to 4 min).
"✓ LIVE — verified" means it's truly online; a warning means Cloudflare didn't build — the
message tells you exactly what to click. Never assume a push went live without that check.

> **Each upload may run a quick self-check** (it builds the site and runs the tests before
> uploading — so does `npm run ship`, which uploads too). It can take a minute, and **if
> something is broken it stops the upload and tells you** rather than publishing a broken
> page. To skip the check on a *manual* `git push` you've already verified:
> `git push --no-verify`. If **`npm run ship`** stops partway, don't force it — ask for help.

> **Nothing reaches the live domain until step 4.** Steps 1–3 only update the noindexed preview.

---

## Single-stage (simplest) — "push = live"

One branch, `main`, and it **is** the live site. There's no preview — every upload goes
straight online. Simple, but there's no safety net, so check locally first (`npm run dev`).

> **"Push = live" is a promise, not a fact.** Cloudflare can silently stop building (it
> happened in production: green pushes, no deploy). After an important upload, confirm the
> change is really online — `curl https://your-site/build.txt` shows which build is serving
> (compare with `git rev-parse HEAD`). If it's stale: Cloudflare dashboard → your project →
> Deployments (retry the failed build, or re-connect GitHub under Settings → Builds).

> **You need a custom domain for Google to see the site.** A bare Cloudflare
> `*.pages.dev` URL is **noindexed by design** (so stray preview URLs never get indexed).
> Until you attach your real domain in Cloudflare, the live site works but search engines
> ignore it.

**Every time you change the site:**

```bash
# 1. (Optional but wise) preview locally first
npm run dev        # opens a local copy in your browser; Ctrl-C to stop

# 2. Save your changes
git add -A
git commit -m "describe what you changed"

# 3. Upload — this goes LIVE within a minute
git push
```

---

## If something goes wrong

- **Mistake already live?** Don't panic — in the **Cloudflare dashboard → your Pages
  project → Deployments**, every past version is listed; click an older one →
  **Rollback** to restore it instantly.
- **Made a typo in the last save (not pushed yet)?** Re-edit, then
  `git add -A && git commit -m "fix typo"` again.
- **`git push` says "rejected"?** (on `main`) Someone/something updated the cloud copy — run
  `git pull` first, then `git push` again.

When in doubt, ask before you `npm run ship` / `git push` — those are the only two commands
that change what the public sees.
