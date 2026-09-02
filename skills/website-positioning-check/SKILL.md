---
name: website-positioning-check
description: >
  Give an existing website a fast, fresh-eyes positioning check. Use when the
  user asks whether a site's offer is clear, differentiated, outcome-led, too
  technical, or consistent across its homepage and offer pages. Read only and
  concise: return a one-screen verdict and the three highest-leverage fixes.
  Do not use for developing positioning from scratch (use website-positioning),
  a full copy rewrite, SEO audit, or pre-launch website review.
---

# Website positioning check

Answer one question: **can the right buyer quickly understand why this is for
them, what result they can buy, and why they should believe it?**

This is a diagnostic, not a workshop. Stay under 250 words unless the user asks
for depth. Do not edit files unless the user explicitly asks for implementation.

## Inspect

Read like an unfamiliar buyer before adopting the site's internal vocabulary.
Inspect, in this order:

1. The rendered homepage, or its source if it cannot be rendered.
2. `POSITIONING.md` and `CONTENT_GUIDE.md` when present.
3. The primary services, product, or offer page linked from the homepage.

Stop there unless a contradiction requires one more page. Do not turn a quick
check into a site-wide audit or competitor study.

## Check

After the hero and first offer section, can the target buyer answer:

1. **Is this for me?** The audience or buying situation is recognizable.
2. **What result can I buy?** Customer change leads; tools, agents, frameworks,
   process, and deliverables support it rather than replace it.
3. **Why this instead of the current alternative?** The difference is concrete,
   not an adjective or a generic claim every competitor could make.
4. **Why believe it?** Proof, experience, a mechanism, or an honest constraint
   supports the promise.
5. **What happens next?** The offer and CTA continue the same promise.

Then check consistency: title, description, H1, hero, offer names, and CTA should
sell the same category and outcome. Offer options should map to distinct customer
starting situations, not read like an overlapping capability list. If the site
promises enablement or transformation, show how the client's team will work
differently and continue without permanent dependence.

Do not score with fake precision. Use these verdicts:

- **Clear**: the five answers are immediate and the surfaces agree.
- **Blurred**: a credible offer exists, but the buyer must decode it.
- **Broken**: surfaces sell different things, or the mechanism has replaced the
  customer outcome.

Distinguish observation from inference. Flag missing evidence; never invent it.
Bold copy may be good. Unsupported certainty is not.

## Return exactly this shape

**Verdict:** Clear / Blurred / Broken

**Current position:** One plain sentence describing what the site actually says,
not what its strategy document intended to say.

**Strongest element:** The one thing to preserve.

**Primary blur:** The single issue doing the most commercial damage.

**Three fixes:** Three ranked, specific changes. Name the affected surface.

**Core line:** One replacement positioning line only when the existing line is
part of the problem. Keep it faithful to available evidence.

Omit the Core line when no replacement is needed. Do not append a long checklist,
page-by-page inventory, or generic marketing advice.

## Handoff

If the user asks to fix the findings, update the positioning source of truth with
`website-positioning`, then use `copywriting` for page copy. Run the site's normal
tests and `website-review` after consequential changes.
