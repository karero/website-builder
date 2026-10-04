// Contact form endpoint: POST /api/contact (a Cloudflare Pages Function, installed
// by the website-forms skill as functions/api/contact.ts).
//
// What it does: checks the three fields, drops what a bot sends, and mails the
// message to the site owner through Cloudflare's Email Service, with the visitor's
// address as Reply-To so the owner answers from their own mailbox. It stores nothing.
//
// Why the REST API and a token: Cloudflare's documentation lists no email binding for
// Pages Functions (Workers have one). The call needs four settings on the Pages
// project (Settings → Variables and Secrets), all of them the owner's to create:
//   CONTACT_TO      where messages go. A verified destination address of the account:
//                   sending to those is free on every plan.
//   CONTACT_FROM    the sender, on the site's own domain, which must be onboarded for
//                   Email Sending (that needs the domain's DNS at Cloudflare).
//   CF_ACCOUNT_ID   the Cloudflare account id.
//   CF_EMAIL_TOKEN  an API token with the permission "Email Sending: Edit". A SECRET.
// One of them missing → the visitor is told the message did not go out (503), never
// a silent success, and the log names what is missing.
//
// The call follows Cloudflare's REST reference as read on 2026-10-04
// (https://developers.cloudflare.com/email-service/api/send-emails/rest-api/). It was
// not run against a real account when this was written: the first real message on a
// deployed site is the proof (the skill's §5), and the log line below is what to read
// if that message does not arrive.
//
// Typed with minimal local interfaces, like functions/_middleware.ts, so it compiles
// under the project's strict tsconfig without @cloudflare/workers-types.
export interface Env {
  CONTACT_TO?: string;
  CONTACT_FROM?: string;
  CF_ACCOUNT_ID?: string;
  CF_EMAIL_TOKEN?: string;
}
export type Message = { to: string; from: string; reply_to: string; subject: string; text: string };
export type Send = (message: Message, env: Required<Env>) => Promise<boolean>;

export const LIMITS = { name: 100, email: 254, message: 5000 };
// The hidden field's name. Deliberately not "website", "url" or "company": a browser
// or a password manager may fill those for a real visitor, whose message would then be
// dropped. Keep it in step with ContactForm.astro.
export const TRAP = 'leave_empty';
const SETTINGS = ['CONTACT_TO', 'CONTACT_FROM', 'CF_ACCOUNT_ID', 'CF_EMAIL_TOKEN'] as const;
const TIMEOUT_MS = 10_000;
// The kinds of error the log may name when the mail call throws.
const KINDS = ['TimeoutError', 'AbortError', 'TypeError'];
// A message of the allowed length is a few tens of kilobytes, however it is encoded.
const MAX_BODY_BYTES = 100_000;
// One address, nothing that could start a second header or a second recipient. An
// apostrophe is allowed (o'brien@…): the address travels as a JSON value, not a header line.
const EMAIL = /^[^\s@<>",;:\\()[\]]+@[^\s@<>",;:\\()[\]]+\.[^\s@<>",;:\\()[\]]{2,}$/;
// Characters nobody sees: control characters and invisible format characters have no
// place in an address. (A few domain names carry a joiner, one of the format
// characters, in their Unicode spelling. An address typed that way is refused too, and
// its visitor is shown the address to write to.)
const UNSEEN = /[\p{Cc}\p{Cf}]/u;
// Whether a text holds anything a person can see: a name or a message made of spaces
// and invisible characters only is an empty one.
const visible = (text: string) => /[^\p{Cc}\p{Cf}\p{Z}]/u.test(text);

// The mail goes out through Cloudflare's own API. true only when Cloudflare says it
// delivered or queued the message. Any other answer counts as a failure and is logged:
// the HTTP status, how many errors Cloudflare named and their numeric codes, how many
// addresses bounced, and whether the answer could be read. Numbers and a yes or no,
// nothing the answer spells out: its error texts are left out on purpose, because
// nothing guarantees they never repeat part of what was sent, and the log must not
// carry the token or the visitor's words.
export async function sendViaCloudflare(message: Message, env: Required<Env>, fetcher: typeof fetch = fetch): Promise<boolean> {
  const res = await fetcher(`https://api.cloudflare.com/client/v4/accounts/${env.CF_ACCOUNT_ID}/email/sending/send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${env.CF_EMAIL_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(message),
    // Give up after ten seconds. A runtime that cannot do that sends without a time limit.
    signal: typeof AbortSignal.timeout === 'function' ? AbortSignal.timeout(TIMEOUT_MS) : undefined,
  });
  const body = (await res.json().catch(() => null)) as
    | { success?: unknown; errors?: unknown; result?: { delivered?: unknown; queued?: unknown; permanent_bounces?: unknown } | null }
    | null;
  // Only a real list has a length to believe, or to log.
  const count = (list: unknown) => (Array.isArray(list) ? list.length : 0);
  const accepted = count(body?.result?.delivered) + count(body?.result?.queued);
  if (res.ok && body?.success === true && accepted > 0) return true;
  // A code is a number, or digits in a text; anything else is counted, not repeated.
  const errors: unknown[] = Array.isArray(body?.errors) ? body.errors : [];
  const codes = errors
    .slice(0, 10)
    .map((error) => (error as { code?: unknown } | null)?.code)
    .filter((code): code is number | string => typeof code === 'number' || (typeof code === 'string' && /^\d{1,10}$/.test(code)))
    .map(Number);
  console.error(
    'contact form: Cloudflare did not accept the message: ' +
      JSON.stringify({ status: res.status, errors: errors.length, codes, bounced: count(body?.result?.permanent_bounces), readable: body !== null }),
  );
  return false;
}

type Outcome = { status: number; body: { ok: boolean; error?: 'forbidden' | 'invalid' | 'not_configured' | 'send_failed'; fields?: Record<string, string> } };

// The decision, apart from how it is phrased back to the visitor.
export async function decide(request: Request, env: Env, send: Send = sendViaCloudflare): Promise<{ outcome: Outcome; lang: string }> {
  // A post that declares far more than a message can be is refused unread. One that
  // declares nothing is still read: Cloudflare's own limits are what bound it. Whether
  // Cloudflare hands this header to the function was not observed; if it does not, this
  // check never fires there.
  if (Number(request.headers.get('content-length') ?? 0) > MAX_BODY_BYTES) {
    return { outcome: { status: 400, body: { ok: false, error: 'invalid', fields: { form: 'too_large' } } }, lang: 'en' };
  }
  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return { outcome: { status: 400, body: { ok: false, error: 'invalid', fields: { form: 'unreadable' } } }, lang: 'en' };
  }
  // Text fields only: an uploaded file under a field's name counts as an empty field.
  const field = (name: string) => {
    const value = form.get(name);
    return typeof value === 'string' ? value.trim() : '';
  };
  const lang = field('lang').toLowerCase().split('-')[0] || 'en';

  // A browser names the page a form post comes from. One that is not this site
  // (another site, another scheme, or the opaque "null") is refused. A request with no
  // Origin at all is let through, on purpose: an older browser or a privacy tool may
  // leave the header out, and its visitor's message should not be lost. Which browsers
  // do so was not measured, and a script can claim any origin anyway. This check keeps
  // other websites from posting here through their visitors' browsers where the browser
  // names the origin; it is not what stops a script (nothing here does, see the skill's §6).
  const origin = request.headers.get('origin');
  if (origin !== null && origin !== new URL(request.url).origin) {
    // Logged, without the header's value: the form says "could not be sent" for this
    // too, and an owner testing their own form needs to see why.
    console.error('contact form: refused a post that names another origin');
    return { outcome: { status: 403, body: { ok: false, error: 'forbidden' } }, lang };
  }

  // The hidden field: people never see it, simple bots fill it. Same answer as a real
  // success, so the bot learns nothing, and nothing is sent. Logged without any of the
  // submitted text, so an owner who suspects lost messages can see that drops happen.
  if (form.getAll(TRAP).some((value) => typeof value !== 'string' || value.trim() !== '')) {
    console.log('contact form: dropped a submission that filled the hidden field');
    return { outcome: { status: 200, body: { ok: true } }, lang };
  }

  // The name goes into the subject line: a line break of any kind, any other control
  // character, and the characters that turn the direction of the text around become a
  // space. Other format characters stay: some names are written with joiners.
  const name = field('name').replace(/[\p{Cc}\p{Zl}\p{Zp}\u202A-\u202E\u2066-\u2069]+/gu, ' ').trim();
  const email = field('email');
  // Browsers send a textarea's line breaks as CRLF; count them as the one character
  // the visitor typed, or a long message with many paragraphs fails the limit.
  const message = field('message').replace(/\r\n/g, '\n');
  const fields: Record<string, string> = {};
  if (!visible(name)) fields.name = 'required';
  else if (name.length > LIMITS.name) fields.name = 'too_long';
  if (!email) fields.email = 'required';
  else if (email.length > LIMITS.email || !EMAIL.test(email) || UNSEEN.test(email)) fields.email = 'invalid';
  if (!visible(message)) fields.message = 'required';
  else if (message.length > LIMITS.message) fields.message = 'too_long';
  if (Object.keys(fields).length) return { outcome: { status: 400, body: { ok: false, error: 'invalid', fields } }, lang };

  const missing = SETTINGS.filter((key) => !env[key]);
  const { CONTACT_TO, CONTACT_FROM, CF_ACCOUNT_ID, CF_EMAIL_TOKEN } = env;
  if (!CONTACT_TO || !CONTACT_FROM || !CF_ACCOUNT_ID || !CF_EMAIL_TOKEN) {
    console.error(`contact form: not set on this deployment: ${missing.join(', ')}`);
    return { outcome: { status: 503, body: { ok: false, error: 'not_configured' } }, lang };
  }
  let sent = false;
  try {
    sent = await send(
      {
        to: CONTACT_TO,
        from: CONTACT_FROM,
        reply_to: email,
        // By characters, not code units, so a name cannot be cut in the middle of one.
        subject: Array.from(`Website message from ${name}`).slice(0, 120).join(''),
        text: `Name: ${name}\nEmail: ${email}\n\n${message}\n`,
      },
      { CONTACT_TO, CONTACT_FROM, CF_ACCOUNT_ID, CF_EMAIL_TOKEN },
    );
  } catch (err) {
    // The kind of error, and only one from the short list above (TimeoutError: no answer
    // in time). Never its text, and never a name outside the list: either can repeat
    // what was sent, as Cloudflare's error texts can. The name is read once, and what
    // is logged is the list's own entry, not what the error said.
    const thrown: unknown = err instanceof Error ? err.name : null;
    const kind = KINDS.find((known) => known === thrown) ?? 'another error';
    console.error('contact form: the mail call failed before an answer came: ' + kind);
  }
  return { outcome: sent ? { status: 200, body: { ok: true } } : { status: 502, body: { ok: false, error: 'send_failed' } }, lang };
}

// What a visitor without JavaScript reads after sending. No form of address, so it
// fits a "du" site and a "Sie" site alike. On a failure it sends them back to the
// form, where the address to write to is always shown, and by the browser's own Back
// button: the link under the sentence loads the page afresh.
const PLAIN: Record<string, { title: string; sent: string; invalid: string; failed: string; back: string }> = {
  en: {
    title: 'Contact',
    sent: 'Thank you. The message has been sent.',
    invalid: 'Some details are missing or not valid. Please use the Back button of the browser and check them.',
    failed: 'The message could not be sent. Please use the Back button of the browser: the address to write to is shown with the form.',
    back: 'Back to the website',
  },
  de: {
    title: 'Kontakt',
    sent: 'Danke. Die Nachricht wurde gesendet.',
    invalid: 'Einige Angaben fehlen oder sind ungültig. Bitte mit der Zurück-Taste des Browsers zurückgehen und prüfen.',
    failed: 'Die Nachricht konnte nicht gesendet werden. Bitte mit der Zurück-Taste des Browsers zurückgehen: Die Adresse für eine direkte Nachricht steht beim Formular.',
    back: 'Zurück zur Website',
  },
};

const escapeHtml = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

// Where the link on that page leads: the page the form was on, if the browser says so
// and it is this site (same scheme, same host), else the home page. The whole address,
// not only its path: a path that starts with two slashes
// (https://this-site//other-site/…) would send the browser to the other site.
function backTo(request: Request): string {
  try {
    const here = new URL(request.url);
    const from = new URL(request.headers.get('referer') ?? '');
    if (from.protocol === here.protocol && from.host === here.host) return from.origin + from.pathname + from.search;
  } catch {
    // no usable Referer
  }
  return '/';
}

export async function handle(request: Request, env: Env, send: Send = sendViaCloudflare): Promise<Response> {
  const { outcome, lang } = await decide(request, env, send);
  const headers = { 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' };
  // The form's own script asks for JSON; a plain form post gets a small page.
  if ((request.headers.get('accept') ?? '').includes('application/json')) {
    return new Response(JSON.stringify(outcome.body), { status: outcome.status, headers: { ...headers, 'content-type': 'application/json; charset=utf-8' } });
  }
  const known = Object.hasOwn(PLAIN, lang) ? lang : 'en';
  const t = PLAIN[known];
  const line = outcome.body.ok ? t.sent : outcome.body.error === 'invalid' ? t.invalid : t.failed;
  const page =
    `<!doctype html><html lang="${known}"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">` +
    `<meta name="robots" content="noindex"><title>${t.title}</title><main><p>${line}</p>` +
    `<p><a href="${escapeHtml(backTo(request))}">${t.back}</a></p></main></html>`;
  return new Response(page, { status: outcome.status, headers: { ...headers, 'content-type': 'text/html; charset=utf-8' } });
}

export const onRequestPost = (context: { request: Request; env: Env }): Promise<Response> => handle(context.request, context.env);
