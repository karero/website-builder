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

`main` is a **private preview** (search engines ignore it); `production` is the **live**
site. You can push freely to `main` — nothing goes public until you publish.

**Every time you change the site:**

```bash
# 1. Save your changes (a snapshot + a short description)
git add -A
git commit -m "describe what you changed, e.g. update opening hours"

# 2. Upload them — this builds your PRIVATE PREVIEW (not live yet)
git push

# 3. Look at the preview. Open the preview link from Cloudflare
#    (stable address: main.<your-project>.pages.dev) and check it's right.

# 4. Happy? Publish it to the live site — ONE command:
npm run ship
```

`npm run ship` does the "merge `main` into `production` and upload" step for you, safely —
you never have to run the branch commands by hand. A few seconds after it finishes,
Cloudflare builds the live site.

> **Nothing is public until step 4.** Steps 1–3 only ever touch the preview.

---

## Single-stage (simplest) — "push = live"

One branch, `main`, and it **is** the live site. There's no preview — every upload goes
straight online. Simple, but there's no safety net, so check locally first (`npm run dev`).

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
- **`git push` says "rejected"?** Someone/something updated the cloud copy — run
  `git pull` first, then `git push` again.

When in doubt, ask before you `npm run ship` / `git push` — those are the only two commands
that change what the public sees.
