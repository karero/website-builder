---
name: website-content-guide
description: >
  Create and maintain a new site's CONTENT_GUIDE.md and BRAND.md — Tone of Voice
  and EEAT (Experience/Expertise/Authoritativeness/Trust) signals — so every page
  hangs off one source of truth for HOW it says it. Reads positioning from
  POSITIONING.md (owned by website-positioning, which runs first); it does not
  redefine positioning. Use at the start of a new site (step 3 of the new-website
  pipeline, after website-positioning), before writing page copy, and whenever
  reviewing/editing copy for voice. Pairs with the tone test (tests/tone.spec.ts)
  which hard-enforces the voice rules. Trigger phrases: "content guide", "tone of
  voice", "brand voice", "is this on brand", "EEAT", "E-E-A-T", "write the content
  guide", "set up the brand doc", "review the copy", "does this sound like AI".
---

# Website content guide & voice

Owns the **how it says it** layer of a new site: tone of voice and EEAT signals,
captured in the per-site docs that everything downstream reads. **Positioning**
(what you offer, for whom, the market category) is owned by `website-positioning`
and worked out first; this guide reads it from `POSITIONING.md` and must stay
consistent with it — it does not redefine it.

## Outputs

- **`CONTENT_GUIDE.md`** (from `~/.claude/skills/new-website/templates/content-guide.md`)
  — ToV rules, EEAT checklist, page inventory with target titles, per-page-type
  copy templates, new-page checklist. Reads positioning/audience from `POSITIONING.md`.
- **`POSITIONING.md`** is owned by `website-positioning`; this guide consumes it
  and must not restate the positioning (single source of truth).
- **`BRAND.md`** is owned by `website-design-system`, but its positioning line
  comes from `POSITIONING.md` — keep them consistent.

## How to use

1. Positioning comes first: `website-positioning` has already produced
   `POSITIONING.md` (what you offer, for whom, the market category). Read it and
   build the voice on top of it. Then pull insights: run `customer-research` for
   ICP + voice-of-customer, and `content-strategy` if topic planning is needed.
   Feed the findings in.
2. Copy the template to `CONTENT_GUIDE.md` and fill every `[BRACKET]`.
3. For actual page copy, hand off wording to `copywriting`, then apply the voice
   rules below and run the tone test.

## Tone of voice — the hard rules (enforced by the tone test)

These mirror the tone guards proven on earlier production sites. The test is the source of
truth; the guide explains the *why*.
- **No em dashes (—).** Comma, period, or colon instead.
- **No contractions.** Long form: "cannot", "it is", "you are", "we are".
- **No buzzwords:** supercharge, world-class, leverage, unlock, seamless, robust,
  cutting-edge, empower, holistic, revolutionary, synergy, next-level (trim/extend
  per brand).
- Active voice; speak to the reader as "you"; proof over claims.
- **Exempt:** genuinely quoted customer/human voice — wrap in `<blockquote>`,
  `<q>`, or add `data-tov-exempt`. Do not use this to smuggle brand copy past the
  rules.

## EEAT — build it in from the start

Search and AI answer engines reward Experience, Expertise, Authoritativeness,
Trust. Ship the signals, not just claims:
- **Experience/Expertise:** named authors with a real bio and a stable schema
  `@id`; first-hand specifics and dates; inline citations on claim-heavy copy.
- **Authoritativeness:** `sameAs` profiles that actually resolve (LinkedIn,
  GitHub, public register); Organization schema; corroborating external mentions.
- **Trust:** imprint/legal entity page, clear contact, privacy page, last-updated
  timestamps, HTTPS, zero broken links.

The author/Organization/`sameAs` plumbing lives in `website-seo-geo` (schema) and
`config.ts`/`SAME_AS`; this skill decides *what* those signals should be.

## Done means

`CONTENT_GUIDE.md` filled, voice consistent with `POSITIONING.md` and `BRAND.md`,
and the tone test green after any copy change (`npm test` runs `tone.spec.ts`).
