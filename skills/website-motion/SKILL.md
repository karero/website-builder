---
name: website-motion
description: >
  OPTIONAL polish layer: two motion effects that make a long marketing page feel
  authored rather than dumped — a count-up on hero stat numbers, and a 12px
  rise-and-fade reveal on section headings — plus the reduced-motion contract,
  the a11y gate change, and the motion.spec.ts that keep them from silently
  costing a visitor access to content. Not part of the default new-website
  build: add it only when a site has a long scrolling homepage and real numbers
  worth reading. Also carries the one-line hero-height check (a binding
  min-height:100vh hides the next section at every screen height). Trigger
  phrases: "add some motion", "scroll reveal", "fade in on scroll", "animate the
  stats", "count-up numbers", "animated counter", "the page feels flat", "eye
  candy", "make the homepage less static", "prefers-reduced-motion", "does the
  animation break accessibility".
---

# Website motion

Two effects, deliberately. Motion is where a site starts looking machine-made:
applied to every card and paragraph it reads as a template, and it is the single
easiest way to lose content to an accessibility bug nobody notices. This skill
ships the two that earn their place, and — more importantly — the contract that
makes them safe.

**Only add this when the page is actually long.** On a three-section site a
reveal is noise. The count-up needs numbers a visitor should stop and read
(attendee counts, years running, projects shipped), not decoration.

**Prerequisite:** `website-qa` green first. This adds a test file to that suite
and changes how the a11y gate runs.

---

## 0. The one-line check that is not motion

Before adding anything, measure the hero:

```js
const h = document.querySelector('.hero');
({ vh: innerHeight, heroHeight: h.getBoundingClientRect().height,
   nextSectionVisible: innerHeight - h.nextElementSibling.getBoundingClientRect().top })
```

If `min-height: 100vh` is *binding* — the hero's own content is shorter than the
viewport — the next section starts exactly at the fold and the page reads as a
splash screen. Trim the floor until the next section peeks over the edge.

**Do not copy a number from another site.** The right value is a function of the
hero's content height. If the content already exceeds the viewport, changing
`min-height` does nothing at all on that screen size, and the real lever is
cutting a paragraph out of the hero. Measure, then decide.

---

## 1. The contract

Everything below exists to keep one promise: **no effect may leave content
unreachable.** Three rules, in priority order.

1. **Hidden state is added by JS, never authored in HTML.** A visitor with no JS,
   or one landing mid-page, must see the finished page. The script adds the
   hiding class itself, and only to elements currently below the fold.
2. **`prefers-reduced-motion: reduce` ends with everything visible and nothing
   moving** — including animations that predate this skill.
3. **Print is a third state.** It never scrolls, so `IntersectionObserver` never
   fires and a revealed heading prints blank.

---

## 2. Scroll reveal — section headings only

```css
@media (prefers-reduced-motion: no-preference) {
  /* No transition on the hidden state. `reveal` is added after first paint, so a
     transition here makes an already-drawn heading fade OUT for half a second
     before it can fade in — visible to anyone scrolling straight after load.
     With the transition on the visible state, hiding snaps and only the reveal
     animates. */
  .reveal { opacity: 0; transform: translateY(12px); }
  .reveal.is-visible {
    opacity: 1; transform: none;
    transition: opacity 0.55s ease-out, transform 0.55s ease-out;
  }
  /* Same specificity as the rule above and LATER in the sheet, so the shorthand
     there cannot reset the delay to zero. */
  .reveal-delay.is-visible { transition-delay: 0.09s; }
}
/* Printing never scrolls, so the observer never fires. */
@media print { .reveal { opacity: 1 !important; transform: none !important; } }
```

```js
(function () {
  if (!('IntersectionObserver' in window)) return;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  function partnerOf(heading) {
    var next = heading.nextElementSibling;
    return next && next.matches('.section-subtitle') ? next : null;
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      io.unobserve(entry.target);
      entry.target.classList.add('is-visible');
      var partner = partnerOf(entry.target);
      if (partner) partner.classList.add('is-visible');
    });
  }, { threshold: 0.15 });

  document.querySelectorAll('.section-title').forEach(function (heading) {
    // Anything already on screen is left alone — hiding it now would make it
    // flash out and fade back in on load.
    if (heading.getBoundingClientRect().top < window.innerHeight) return;
    heading.classList.add('reveal');
    var partner = partnerOf(heading);
    if (partner) partner.classList.add('reveal', 'reveal-delay');
    io.observe(heading);
  });
})();
```

**Headings only.** The subtitle rides along one beat behind so the pair reads as
one movement — that is what "staggered" should mean here. Applying this to cards,
list items and paragraphs is the AI-generated-site tell.

---

## 3. Hero stat count-up

```js
(function () {
  var nums = document.querySelectorAll('.hero-stat-number');
  if (!nums.length || !('IntersectionObserver' in window)) return;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  function countUp(el) {
    var finalText = el.textContent.trim();
    // Integers only, optional thousands separators and a trailing "+". These are
    // public claims; a decimal like "4.9" would strip to 49 and animate up to a
    // number the site does not actually claim.
    if (!/^\d+(?:,\d{3})*\+?$/.test(finalText)) return;
    var target = parseInt(finalText.replace(/[^0-9]/g, ''), 10);
    var suffix = finalText.replace(/[0-9,]/g, '');
    // Freeze the box first. "0+" is far narrower than "1,200+", and the stat is
    // usually sized by its number rather than its label, so an unfrozen count
    // shoves the whole row sideways every frame.
    el.style.minWidth = el.getBoundingClientRect().width + 'px';
    var started = performance.now();
    function frame(now) {
      var t = Math.min((now - started) / 1400, 1);
      el.textContent = Math.round(target * (1 - Math.pow(1 - t, 3)))
        .toLocaleString('en-US') + suffix;
      if (t < 1) requestAnimationFrame(frame);
      else { el.textContent = finalText; el.style.minWidth = ''; }
    }
    requestAnimationFrame(frame);
  }

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      io.unobserve(entry.target);
      countUp(entry.target);
    });
  }, { threshold: 0.6 });
  nums.forEach(function (n) { io.observe(n); });
})();
```

The final values stay in the HTML, so no-JS visitors and crawlers see the real
numbers and the animation only ever replaces them temporarily.

**`min-width` only works on a block box.** If the stat number computes to
`display: inline`, the freeze is a silent no-op and the row still jumps. Check
the computed value, or set `display: inline-block`.

---

## 4. The a11y gate has to change, or it gets quietly weaker

This is the part that is easy to miss, and it is the reason this skill exists
rather than a snippet in `website-design-system`.

**A reveal leaves headings at `opacity: 0` while axe runs, and axe skips elements
it considers invisible.** Their colour contrast silently stops being checked. The
suite stays green and the gate is weaker than it was the day before.

Force reduced motion in `a11y.spec.ts` so axe always sees the finished page:

```ts
for (const path of PAGES) {
  test(`a11y: ${path}`, async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(path, { waitUntil: 'load' });
    // …unchanged
```

> **`test.use({ reducedMotion: 'reduce' })` is not a substitute.** Measured on
> Playwright 1.60 against the toolkit's config: the `test.use` form was accepted
> without complaint and the page's `matchMedia` still reported `no-preference`,
> while `page.emulateMedia` and `browser.newContext` both worked in the same run.
> That contradicts how the option is documented and the mechanism was not
> established — so treat it as a measurement, not a rule, and **re-measure
> `matchMedia` before trusting either form.** A gate that silently does nothing
> is worse than no gate.

---

## 5. `motion.spec.ts` — the test that makes the contract real

Copy this skill's `templates/motion.spec.ts` into the site's `tests/`. It lives
here rather than in the `new-website` Astro overlay on purpose: that overlay is
copied into every scaffold, and this spec asserts an effect a fresh site does
not have — it would fail on day one of every new project.

It asserts the four things the contract promises, and each one has already caught
a real bug:

| assertion | the bug it catches |
|---|---|
| No heading is invisible after a full scroll-through | the whole failure mode this skill guards against |
| Under reduced motion nothing is hidden **and no animation is running** | an override placed *before* the rule it overrides — same specificity, so the original wins and the fix is a no-op |
| Stat numbers settle on their published values | someone editing the figures in HTML |
| The effect actually engages at load | the effect silently dying while every other spec still passes |

**A "nothing animates" test must cover the page's other animations too** — an
ambient hero glow, `scroll-behavior: smooth`. Asserting only your own effect
makes the test's name a lie.

**The count-up assertion is a content snapshot, not an animation test.** The
final frame restores the authored string, so it passes with the animation dead.
Say so in the comment rather than implying coverage it does not have; sampling a
1.4s rAF animation from the test side is timing-dependent and not worth a flaky
gate.

---

## 6. Gotchas that cost real debugging time

- **A reduced-motion override must come AFTER the rule it overrides.** Same
  specificity means later wins. Placed up beside the original declaration it
  reads more naturally and does nothing.
- **A marquee-style strip cannot be hovered or clicked by Playwright.** It waits
  for the element to stop moving and a looping element never does. Drive the
  mouse by coordinate (`page.mouse.move`) instead.
- **Sampling a looping animation flakes at the wrap.** A single before/after pair
  across a 90s loop fails roughly one run in ninety when the window straddles the
  restart. Sample several intervals and take a majority.
- **Adding a heading changes heading order.** A new section heading between the
  last content heading and the footer's can skip a level. `heading-order` is an
  axe *best-practice* rule, so a WCAG-tagged gate will not catch it — check it
  by hand once, or accept that it is ungated and say so.
- **A preview pane may report `visibilityState: "hidden"`.** Where it does,
  `IntersectionObserver` never fires, CSS transitions freeze at their start
  value, and deep-scroll screenshots come back blank. None of this reproduces a
  real browser. Verify motion with Playwright, and use `locator.screenshot()` —
  it captures a single element and sidesteps the blank-capture problem.

---

## Boundaries

- Owns motion only. Layout, images and theme tokens stay in
  `website-design-system`; the QA suite stays in `website-qa`.
- Never a default. `new-website` does not run this; a human asks for it.
