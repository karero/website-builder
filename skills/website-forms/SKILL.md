---
name: website-forms
description: >
  Add a contact form to a new-website site: a form component, one Cloudflare Pages
  Function (functions/api/contact.ts) that mails each message to the owner through
  Cloudflare's Email Service with the visitor as Reply-To, the privacy sentences in
  English and German, and tests/forms.spec.ts with a submission test. Stores
  nothing; a hidden field drops bots; a failed send tells the visitor, and the
  owner's address is always shown under the form. Works without JavaScript. Run when new-website
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
| `tests/forms.spec.ts` | `forms.spec.ts` | the function's behaviour, what the visitor is shown (including the line a screen reader is told to read out), the privacy text |

The templates are at `~/.claude/skills/website-forms/templates/` (Codex:
`~/.agents/skills/…`), or in the site's own bundled copy on a handed-off repo. Install all
three: the test imports the function.

## 2. The owner's four settings (their Cloudflare dashboard)

Explain what each one is for before asking for it. In order:

0. **Does this domain already send or receive mail** (a mailbox at the same domain, a
   newsletter tool, an office suite)? Then its DNS already carries mail records, and
   the next step adds more. Have the owner read the records Cloudflare proposes before
   accepting them, and if anything about their existing mail is unclear, stop and let
   whoever runs that mail look first: a wrong record here can make their ordinary mail
   bounce. Have them write down the domain's current MX and TXT records before they
   start, so there is something to go back to. Which records Cloudflare adds, and
   whether it shows them before it writes them, was not checked when this skill was
   written.
1. **Onboard the domain for Email Sending** (in the Cloudflare dashboard, under Email
   Service). Cloudflare adds the DNS records that let it send mail for the domain; they
   can take up to a day to be known everywhere.
2. **Confirm the mailbox that should receive the messages** as a destination address.
   Cloudflare sends a confirmation mail to it; the owner clicks the link.
3. **Create an API token** with the single permission *Email Sending: Edit* and no
   other. It is a password for sending mail in the owner's name: it goes into step 4 and
   nowhere else, not into the repo, not into a chat. If it was ever shown to anyone, the
   owner deletes it and creates a new one.
4. **Enter four values** on the Pages project → Settings → Variables and Secrets, for
   **Production**. Only add them for **Preview** as well if the form has to work on
   preview addresses: the code of every branch deployment can then read the token, so
   everyone who can push a branch can take it and send mail with it.

   | Name | Value | Kind |
   |---|---|---|
   | `CONTACT_TO` | the confirmed mailbox from step 2 | text |
   | `CONTACT_FROM` | a sender on the site's domain, e.g. `website@<domain>` | text |
   | `CF_ACCOUNT_ID` | the account id (shown in the dashboard) | text |
   | `CF_EMAIL_TOKEN` | the token from step 3 | **secret** |

   A new deployment picks them up; an empty commit is enough to trigger one, as for
   `CANONICAL_URL` (`new-website/references/CLOUDFLARE_FIRST_DEPLOY.md`).

Until all four are set the form answers every visitor with "could not be sent" and
points to the address under the form. It never pretends. The same is true of every
deployment the settings were not entered for: with Production only, the form on a
preview address cannot send, and says so.

## 3. Install (on a branch, as a pull request: `AGENTS.md` §2)

1. Copy the three files to the places in §1 (`mkdir -p functions/api` first).
2. Put the form on a page, inside that page's `<Base>`:
   ```astro
   ---
   import ContactForm from '../components/ContactForm.astro';
   ---
   <ContactForm fallback="<the address visitors may write to>" />
   ```
   `fallback` is always shown under the form, through `EmailLink`: a visitor has
   another way to write whatever happens to the form (a failed send, a script that did
   not load, a browser without JavaScript). Ask the owner for it; it is usually the
   mailbox from §2. A **new** `/contact` page is a new page: work through `AGENTS.md`
   §6 (`PAGES`, `llms.txt`, share card, a link to it).
3. Language: the form speaks the site's language (`SITE.locale`), or on a site with
   several languages the page's (`Astro.currentLocale`); `lang="de"` overrides. English
   and German are built in, with no form of address in German, so it fits a "du" site
   and a "Sie" site. Another language: add it to `TEXT` in the component, to `PLAIN`
   in the function and to `WORDS` in the spec. The tone rules apply
   (`tests/tone.spec.ts`). The mail the owner receives is in English ("Website message
   from …", "Name:", "Email:"): two strings in the function, to change if the owner
   wants them in another language. Two checks in the spec's test "a line break in the
   name cannot start a new mail header" then need the same change: the exact subject,
   and the cut at 120 characters, which counts on the 21 characters of the English
   prefix.
   - **Several languages** (`astro-i18n-setup`): pass `privacy="…"` with the privacy
     page of that page's language (`/de/privacy`, not `/datenschutz`). The component
     stops the build if it is missing there, because it cannot know the site's routes.
   - **A page in another language than the site's**, built with `<Base lang="de">`:
     pass `lang="de"` (and `privacy`), or the form on it is in the site's language. No
     build error reminds you on such a page. Give it its own copy of the spec (step 5):
     that copy fails while the form is not in its page's language.
4. **Privacy page.** Add the sentences from §4. A site with a contact form has to say
   what happens to a message.
5. In `tests/forms.spec.ts` set `PAGE` (the page with the form) and `PRIVACY` (the
   privacy page). Both are required: the spec fails while either is empty, and fails
   when the privacy page lacks the marked text or that text does not name Cloudflare.
   One copy of the spec guards one form and one privacy page: on a site with several
   languages, copy it once per language (`tests/forms.de.spec.ts`), each with that
   language's `PAGE` and `PRIVACY`. The same when a language is added later: the
   form's build error for a missing `privacy` says so too.
6. `npm run check && npm test`. Say in the pull request that it adds a file under
   `functions/` (`AGENTS.md` §5).

`npm run dev` and `astro preview` do not run Pages Functions, so the form cannot send
from a local machine: there the tests stand in for the endpoint. The real check is §5.

## 4. The privacy text

A baseline, not legal advice, like the kit's other legal drafts. The starter's privacy
page already has a section on contact by email (name, address, message, legal basis, how
long it is kept). Do not add a second section beside it: **extend that one** with what is
new about a form, and mark the added paragraph with `data-privacy-contact-form` (the test
looks for it). Adapt the wording to what the owner really does with messages.

English, in `privacy.astro`, at the end of "4. Contact by email":

```astro
<p data-privacy-contact-form>
  Messages sent through the contact form on this website are delivered to our mailbox
  by Cloudflare, Inc., which acts as our processor. The website itself does not store
  them.
</p>
```

German, in the German privacy page (the starter's `_datenschutz.astro`, served as
`datenschutz.astro` once the site adopted it), at the end of "4. Kontakt per E-Mail":

```astro
<p data-privacy-contact-form>
  Nachrichten, die Sie über das Kontaktformular dieser Website senden, werden von
  Cloudflare, Inc. als unserem Auftragsverarbeiter an unser Postfach zugestellt. Die
  Website selbst speichert sie nicht.
</p>
```

The German sentence says "Sie" because the starter's German privacy draft does; the form
itself uses no form of address. A site whose privacy page has no such section (it was
rewritten, or contact by email was removed): write the full statement first, covering
what is processed, why, the legal basis and how long it is kept, then add this paragraph.

## 5. The first real message (the owner, on the deployed site)

Nothing in the test suite sends a real email. The first real message is sent where the
four settings are. With Production only (§2 step 4) that is the **live** address: on a
single-stage site once the pull request is merged, on a two-stage site after
`npm run ship`, on a site that is published by a deploy command after that command
(`new-website/references/CLOUDFLARE_FIRST_DEPLOY.md` §A). A preview address then
answers "could not be sent" and its log names all four settings. That is expected, not
a fault, and no reason to enter the token for Preview.

1. The owner opens the form on that address (say which it is) and sends a message from
   an address that is **not** the destination mailbox.
2. It arrives in the mailbox within a minute or two; pressing Reply addresses the
   visitor's address. Spam folder checked if it does not.
3. It does not arrive, or the form says "could not be sent": look in the mailbox first.
   The form says "could not be sent" whenever it did not get a clear yes, and the
   message can have gone out all the same. Then have the owner open the function's log
   for that deployment in the Cloudflare dashboard and **send the message again** (the
   dashboard shows a function's log lines as they happen; start it first). Read the
   line that appears literally. None of the function's lines carries the token or
   anything the visitor entered: only the names of settings, the status, numeric codes
   and counts, and the kind of error from a short fixed list.

   | The log says | Which means | Do this |
   |---|---|---|
   | "not set on this deployment: …" | the settings it names are missing on this deployment | enter them (§2) and redeploy. On a preview address with Production-only settings this is expected |
   | "Cloudflare did not accept the message: …" | Cloudflare's answer was not a clear yes. The line gives the HTTP status, how many errors Cloudflare named and their numeric codes, how many addresses bounced, and whether the answer could be read as an answer at all | report the status and the codes to the owner as they are and look them up in Cloudflare's documentation; do not guess. If the line says `"readable":false`, whether the message went out is not known: look in the mailbox. A status from 200 to 299 with no errors, nothing bounced and `"readable":true`: Cloudflare answered in a shape the function does not take for a yes. The message may have gone out: look in the mailbox, then hold Cloudflare's current REST reference against `sendViaCloudflare` in the function. `bounced` above 0: Cloudflare reports the destination address as bouncing; check `CONTACT_TO` and that the address was confirmed (§2 step 2) |
   | "the mail call failed before an answer came: …" | the call to Cloudflare ended in an error, not an answer; whether the message went out is not known. The word after the colon is a hint, named as the test runner names such errors (Cloudflare's runtime was not observed): `TimeoutError` or `AbortError` for no answer within ten seconds, `TypeError` for a request that could not be made or a connection that failed, "another error" for anything else | look in the mailbox, then try once more a little later. The same line again: look at Cloudflare's status page and tell the owner what the line says. A timeout every time says nothing about the token: the call took longer than the function waits (ten seconds, `TIMEOUT_MS` in the function). Tell the owner, and do not change the settings for it. For the other kinds, with a status page that shows nothing, one thing worth trying is to enter the four settings afresh with a new token and redeploy: in the test runner a line break inside the token gives this line |
   | "refused a post that names another origin" | the browser said the form was posted from another address than the function's | open the form on the address being tested. For visitors without JavaScript the site's referrer policy can cause this (§6) |
   | "dropped a submission that filled the hidden field" | something filled the field no person sees. The form answered "sent" and nothing was sent | send again from another browser or a private window (§6) |
   | no line at all | the function wrote nothing. Either the post did not reach it, or the message went out (a sent message leaves no line), or a field was missing or not valid, which the form reports in a sentence of its own | look in the mailbox, then check that `functions/api/contact.ts` is in the deployed commit |
   | any other line | it is not one of the function's own | report it as it is |
4. The form said "sent" and nothing arrived: look in the spam folder and check that the
   destination address was confirmed (§2 step 2). Then open the log and send again. No
   line means Cloudflare accepted the message. The "dropped a submission" line means
   the owner's own browser or password manager filled the hidden field: see the table.

Only then is the form done.

## 6. What it does not do

- **No copy to the visitor, no auto-reply.** That needs Cloudflare's paid plan (§0).
- **No storage, no list of past messages.** The mailbox is the record.
- **One hidden field against bots, nothing more.** It stops bots that fill in every
  field of a page. A script that posts straight to `/api/contact` never sees the field
  and is not stopped by it, nor by the check that refuses a post naming another
  website as its origin. If spam gets through, the next step is Cloudflare Turnstile on
  the form and a rate-limiting rule on `/api/contact`. Neither is built here: say so
  when the owner reports spam. A real visitor whose browser or password manager fills
  the hidden field is dropped the same way: its name and `autocomplete="off"` give
  them no reason to, but that was not measured. So each dropped submission leaves a
  line in the function's log, without its text. The dashboard shows log lines only
  while the log is open: an owner who suspects lost messages opens it and sends again
  from the browser in question.
- **Without JavaScript, the answer is a page of its own.** Reloading that page makes
  the browser ask whether to send the form again.
- **Not with `Referrer-Policy: no-referrer`.** Under that policy a browser posts a plain
  form with `Origin: null` (seen in Chromium), which the function refuses, so visitors
  without JavaScript could not send. The starter's policy
  (`strict-origin-when-cross-origin`) is fine; on a site that changed it, look at
  `public/_headers` and for a `<meta name="referrer">` in the layout.
- **This repo's CI builds the English form only.** The German texts were read against
  the tone rules by hand; a site in German runs them through its own suite.
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
