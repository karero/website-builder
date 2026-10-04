// Contact form endpoint: POST /api/contact (a Cloudflare Pages Function, installed
// by the website-forms skill as functions/api/contact.ts).
//
// What it does: checks the three fields, drops what a bot sends, and mails the
// message to the site owner through Cloudflare's Email Service, with the visitor's
// address as Reply-To so the owner answers from their own mailbox. It stores nothing.
//
// Why the REST API and a token: Pages Functions have no email binding (Workers do).
// The call needs four settings on the Pages project (Settings → Variables and
// Secrets), all of them the owner's to create:
//   CONTACT_TO      where messages go. A verified destination address of the account:
//                   sending to those is free on every plan.
//   CONTACT_FROM    the sender, on the site's own domain, which must be onboarded for
//                   Email Sending (that needs the domain's DNS at Cloudflare).
//   CF_ACCOUNT_ID   the Cloudflare account id.
//   CF_EMAIL_TOKEN  an API token with the permission "Email Sending: Edit". A SECRET.
// One of them missing → the visitor is told the message did not go out (503), never
// a silent success.
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
// One address, nothing that could start a second header or a second recipient.
const EMAIL = /^[^\s@<>"',;:\\()[\]]+@[^\s@<>"',;:\\()[\]]+\.[^\s@<>"',;:\\()[\]]{2,}$/;

// The mail goes out through Cloudflare's own API. true only when Cloudflare says it
// delivered or queued the message; any other answer is a failure the visitor hears about.
export async function sendViaCloudflare(message: Message, env: Required<Env>, fetcher: typeof fetch = fetch): Promise<boolean> {
  const res = await fetcher(`https://api.cloudflare.com/client/v4/accounts/${env.CF_ACCOUNT_ID}/email/sending/send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${env.CF_EMAIL_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(message),
  });
  if (!res.ok) return false;
  const body = (await res.json().catch(() => null)) as { success?: boolean; result?: { delivered?: unknown[]; queued?: unknown[] } } | null;
  const accepted = (body?.result?.delivered?.length ?? 0) + (body?.result?.queued?.length ?? 0);
  return body?.success === true && accepted > 0;
}

type Outcome = { status: number; body: { ok: boolean; error?: 'forbidden' | 'invalid' | 'not_configured' | 'send_failed'; fields?: Record<string, string> } };

// The decision, apart from how it is phrased back to the visitor.
export async function decide(request: Request, env: Env, send: Send = sendViaCloudflare): Promise<{ outcome: Outcome; lang: string }> {
  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return { outcome: { status: 400, body: { ok: false, error: 'invalid', fields: { form: 'unreadable' } } }, lang: 'en' };
  }
  const field = (name: string) => String(form.get(name) ?? '').trim();
  const lang = field('lang').toLowerCase().split('-')[0] || 'en';

  // A form on another site may not post here.
  const origin = request.headers.get('origin');
  if (origin && origin !== 'null' && safeHost(origin) !== new URL(request.url).host) {
    return { outcome: { status: 403, body: { ok: false, error: 'forbidden' } }, lang };
  }

  // The hidden field: people never see it, bots fill it. Same answer as a real
  // success, so the bot learns nothing, and nothing is sent.
  if (field('website') !== '') return { outcome: { status: 200, body: { ok: true } }, lang };

  const name = field('name').replace(/[\r\n]+/g, ' ');
  const email = field('email');
  const message = field('message');
  const fields: Record<string, string> = {};
  if (!name) fields.name = 'required';
  else if (name.length > LIMITS.name) fields.name = 'too_long';
  if (!email) fields.email = 'required';
  else if (email.length > LIMITS.email || !EMAIL.test(email)) fields.email = 'invalid';
  if (!message) fields.message = 'required';
  else if (message.length > LIMITS.message) fields.message = 'too_long';
  if (Object.keys(fields).length) return { outcome: { status: 400, body: { ok: false, error: 'invalid', fields } }, lang };

  const { CONTACT_TO, CONTACT_FROM, CF_ACCOUNT_ID, CF_EMAIL_TOKEN } = env;
  if (!CONTACT_TO || !CONTACT_FROM || !CF_ACCOUNT_ID || !CF_EMAIL_TOKEN) {
    console.error('contact form: CONTACT_TO, CONTACT_FROM, CF_ACCOUNT_ID or CF_EMAIL_TOKEN is not set on this deployment');
    return { outcome: { status: 503, body: { ok: false, error: 'not_configured' } }, lang };
  }
  let sent = false;
  try {
    sent = await send(
      {
        to: CONTACT_TO,
        from: CONTACT_FROM,
        reply_to: email,
        subject: `Website message from ${name}`.slice(0, 120),
        text: `Name: ${name}\nEmail: ${email}\n\n${message}\n`,
      },
      { CONTACT_TO, CONTACT_FROM, CF_ACCOUNT_ID, CF_EMAIL_TOKEN },
    );
  } catch (err) {
    console.error('contact form: the email call threw', err);
  }
  return { outcome: sent ? { status: 200, body: { ok: true } } : { status: 502, body: { ok: false, error: 'send_failed' } }, lang };
}

function safeHost(origin: string): string {
  try {
    return new URL(origin).host;
  } catch {
    return '';
  }
}

// What a visitor without JavaScript reads after sending. No form of address, so it
// fits a "du" site and a "Sie" site alike.
const PLAIN: Record<string, { title: string; sent: string; invalid: string; failed: string; back: string }> = {
  en: {
    title: 'Contact',
    sent: 'Thank you. The message has been sent.',
    invalid: 'Some details are missing or not valid. Please go back and check them.',
    failed: 'The message could not be sent. Please use the contact details on the website.',
    back: 'Back to the website',
  },
  de: {
    title: 'Kontakt',
    sent: 'Danke. Die Nachricht wurde gesendet.',
    invalid: 'Einige Angaben fehlen oder sind ungültig. Bitte zurückgehen und prüfen.',
    failed: 'Die Nachricht konnte nicht gesendet werden. Bitte die Kontaktdaten auf der Website nutzen.',
    back: 'Zurück zur Website',
  },
};

export async function handle(request: Request, env: Env, send: Send = sendViaCloudflare): Promise<Response> {
  const { outcome, lang } = await decide(request, env, send);
  // The form's own script asks for JSON; a plain form post gets a small page.
  if ((request.headers.get('accept') ?? '').includes('application/json')) {
    return new Response(JSON.stringify(outcome.body), { status: outcome.status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } });
  }
  const t = PLAIN[lang] ?? PLAIN.en;
  const line = outcome.body.ok ? t.sent : outcome.body.error === 'invalid' ? t.invalid : t.failed;
  const page = `<!doctype html><html lang="${PLAIN[lang] ? lang : 'en'}"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex"><title>${t.title}</title><main><p>${line}</p><p><a href="/">${t.back}</a></p></main></html>`;
  return new Response(page, { status: outcome.status, headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store' } });
}

export const onRequestPost = (context: { request: Request; env: Env }): Promise<Response> => handle(context.request, context.env);
