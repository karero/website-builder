---
name: website-forms
description: >
  Add a contact form to a new-website site: a form component, one Cloudflare Pages
  Function (functions/api/contact.ts) that mails each message to the owner through
  Cloudflare's Email Service with the visitor as Reply-To, a privacy paragraph in
  English and German, and tests/forms.spec.ts with a submission test. Stores
  nothing; a hidden field drops bots; a failed send tells the visitor and shows
  another way to reach the owner. Works without JavaScript. Run when new-website
  Q2 = "a form that emails you", or later when the owner asks for a form. Needs the
  domain's DNS at Cloudflare and four settings only the owner can create. Trigger
  phrases: "contact form", "add a form", "enquiry form", "form that emails me",
  "visitors should be able to write to us", "kontaktformular". Not for newsletter
  sign-up, file uploads, or anything that has to be stored.
---

# Website forms — a contact form that mails the owner

A contact form is the one piece of server work most small sites want. This skill adds
it without a third company in the middle: the site's own Cloudflare account delivers
the message to the owner's mailbox, and the site stores nothing.

> **Human-in-the-loop.** Everything in §2 happens in the owner's Cloudflare dashboard
> and is the owner's to do: onboarding the domain, confirming the mailbox, creating the
> token, entering the four settings. You explain each step and what it is for, and you
> read back what they report. You never ask for the token, never paste it anywhere,
> and never drive the dashboard yourself.

> **Not exercised on a real account by the author of this skill.** The function's
> behaviour is pinned by tests that stand in for Cloudflare's mail call, and §2 follows
> Cloudflare's documentation as read on 2026-10-04 (Email Sending was in beta then).
> The first real message, in §5, is the proof for each site. If the dashboard or the
> API differs from what is written here, stop, say so, and check Cloudflare's current
> documentation before going on.

## 0. Is this the right tool? (ask before installing)

1. **Does the domain's DNS sit at Cloudflare?** Email Sending needs it. A site that
   only points a CNAME at Cloudflare Pages from another DNS host cannot use it.
2. **Is one mailbox enough?** Sending to a mailbox the owner has confirmed in their
   Cloudflare account is free on every plan. Mail to anyone else, such as an automatic
   confirmation to the visitor, needs Cloudflare's paid Workers plan. This skill sends to
   the owner only.
3. **Is a form needed at all?** For a handful of enquiries a year, an email link
   (`<EmailLink>`) does the job with nothing to run. Say so.

No to 1 or 2: say plainly that this skill does not fit, and offer the two alternatives
from `new-website/references/WEBSITE_ARCHITECTURE.md` Tier 1: the email link, or a hosted
form service (a third party then handles visitor messages and must be named on the
privacy page). Neither is built by this skill.

## 1. What it adds to the site

| File | From this skill's `templates/` | What it is |
|---|---|---|
| `functions/api/contact.ts` | `contact.ts` | the endpoint `POST /api/contact`: checks, bot trap, the mail call |
| `src/components/ContactForm.astro` | `ContactForm.astro` | the form; English and German built in |
| `tests/forms.spec.ts` | `forms.spec.ts` | the function's behaviour, what the visitor sees, the privacy paragraph |

The templates are at `~/.claude/skills/website-forms/templates/` (Codex:
`~/.agents/skills/…`), or in the site's own bundled copy on a handed-off repo. Install all
three: the test imports the function.

## 2. The owner's four settings (their Cloudflare dashboard)

Explain what each one is for before asking for it. In order:

1. **Onboard the domain for Email Sending** (Cloudflare dashboard → Email Service).
   Cloudflare adds the DNS records that let it send mail for the domain; they can take
   up to a day to be known everywhere.
2. **Confirm the mailbox that should receive the messages** as a destination address.
   Cloudflare sends a confirmation mail to it; the owner clicks the link.
3. **Create an API token** with the single permission *Email Sending: Edit*. It is a
   password for sending mail in the owner's name: it goes into step 4 and nowhere else.
4. **Enter four values** on the Pages project → Settings → Variables and Secrets, for
   **Production** (and for **Preview** too if the form should work on preview addresses):

   | Name | Value | Kind |
   |---|---|---|
   | `CONTACT_TO` | the confirmed mailbox from step 2 | text |
   | `CONTACT_FROM` | a sender on the site's domain, e.g. `website@<domain>` | text |
   | `CF_ACCOUNT_ID` | the account id (shown in the dashboard) | text |
   | `CF_EMAIL_TOKEN` | the token from step 3 | **secret** |

   A new deployment picks them up; an empty commit is enough to trigger one, as for
   `CANONICAL_URL` (`new-website/references/CLOUDFLARE_FIRST_DEPLOY.md`).

Until all four are set the form answers every visitor with "could not be sent" and the
address to write to instead. It never pretends.

## 3. Install (on a branch, as a pull request: `AGENTS.md` §2)

1. Copy the three files to the places in §1 (`mkdir -p functions/api` first).
2. Put the form on a page, inside that page's `<Base>`:
   ```astro
   ---
   import ContactForm from '../components/ContactForm.astro';
   ---
   <ContactForm fallback="<the address visitors may write to>" />
   ```
   `fallback` is shown, through `EmailLink`, when a message cannot be sent. Ask the owner
   for it; it is usually the mailbox from §2. A **new** `/contact` page is a new page:
   work through `AGENTS.md` §6 (`PAGES`, `llms.txt`, share card, a link to it).
3. Language: the form speaks the site's language (`SITE.locale`), or on a site with
   several languages the page's (`Astro.currentLocale`); `lang="de"` overrides. English
   and German are built in, with no form of address in German, so it fits a "du" site
   and a "Sie" site. Another language: add it to `TEXT` in the component and to `PLAIN`
   in the function. The tone rules apply (`tests/tone.spec.ts`).
4. **Privacy page.** Add the paragraph from §4. A site with a contact form has to say
   what happens to a message; `forms.spec.ts` fails without it.
5. In `tests/forms.spec.ts` set `PAGE` (the page with the form) and `PRIVACY` (the
   privacy page).
6. `npm run check && npm test`. Say in the pull request that it adds a file under
   `functions/` (`AGENTS.md` §5).

`npm run dev` and `astro preview` do not run Pages Functions, so the form cannot send
from a local machine: there the tests stand in for the endpoint. The real check is §5.

## 4. The privacy paragraph

A baseline, not legal advice, like the kit's other legal drafts. Keep the
`data-privacy-contact-form` marker: the test looks for it. Adapt the wording to what the
owner really does with messages (who reads them, how long they are kept).

English, for `privacy.astro`:

```astro
<section class="wrap" data-privacy-contact-form>
  <h2>Contact form</h2>
  <p>
    When you send us a message through the contact form, we process your name, your
    email address and the message itself in order to answer you (Art. 6(1)(b) GDPR
    where your request concerns a contract or steps before one, otherwise
    Art. 6(1)(f) GDPR: our interest in answering enquiries). The message is delivered
    to our mailbox by Cloudflare, Inc., which acts as our processor. The website itself
    does not store it. We keep the message for as long as answering it requires and
    delete it afterwards, unless the law obliges us to keep it longer.
  </p>
</section>
```

German, for `datenschutz.astro`:

```astro
<section class="wrap" data-privacy-contact-form>
  <h2>Kontaktformular</h2>
  <p>
    Wenn Sie uns über das Kontaktformular schreiben, verarbeiten wir Ihren Namen, Ihre
    E-Mail-Adresse und Ihre Nachricht, um die Anfrage zu beantworten (Art. 6 Abs. 1
    lit. b DSGVO, soweit die Anfrage einen Vertrag oder dessen Anbahnung betrifft, sonst
    Art. 6 Abs. 1 lit. f DSGVO: unser Interesse, Anfragen zu beantworten). Die Nachricht
    wird von Cloudflare, Inc. als unserem Auftragsverarbeiter an unser Postfach
    zugestellt. Die Website selbst speichert sie nicht. Wir bewahren die Nachricht so
    lange auf, wie es für die Bearbeitung erforderlich ist, und löschen sie danach,
    sofern keine gesetzlichen Aufbewahrungspflichten bestehen.
  </p>
</section>
```

## 5. The first real message (the owner, on the deployed site)

Nothing in the test suite sends a real email. After the pull request is merged and the
site is deployed with the four settings:

1. The owner opens the form on the deployed address, preview or live (say which), and
   sends a message from an address that is **not** the destination mailbox.
2. It arrives in the mailbox within a minute or two; pressing Reply addresses the
   visitor's address. Spam folder checked if it does not.
3. It does not arrive, or the form says "could not be sent": have the owner open the
   function's log for that deployment in the Cloudflare dashboard. A line ending "…is
   not set on this deployment" names a missing setting from §2. Otherwise report Cloudflare's answer to
   the owner as it is; do not guess.

Only then is the form done.

## 6. What it does not do

- **No copy to the visitor, no auto-reply.** That needs Cloudflare's paid plan (§0).
- **No storage, no list of past messages.** The mailbox is the record.
- **One hidden field against bots, nothing more.** If spam gets through, the next step
  is Cloudflare Turnstile on the form and a rate-limiting rule on `/api/contact`.
  Neither is built here: say so when the owner reports spam.
- **No file uploads, no newsletter sign-up.** Different problems (size limits, consent
  records); do not bend this form into them.

## Boundaries (do not duplicate)

- Which hosting tier a site needs: `new-website` §1 Q2 and
  `references/WEBSITE_ARCHITECTURE.md`.
- Getting the suite green, and what else to test on a new feature: `website-qa` §1b.
- The privacy page as a whole: the starter's `privacy.astro` and `_datenschutz.astro`.

## Done means

The owner chose the form over a plain email link knowing what it needs; the four
settings are in place, entered by the owner; the form is on its page in the site's
language; the privacy page carries the paragraph; `npm test` is green with `PAGE` and
`PRIVACY` set; and one real message from the deployed site reached the mailbox and
could be answered with Reply.
