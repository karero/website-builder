import { test, expect } from '@playwright/test';
import { decide, handle, onRequestPost, sendViaCloudflare, LIMITS, TRAP, type Env, type Message } from '../functions/api/contact';

// Guards the contact form (the website-forms skill). `astro preview` never runs a
// Cloudflare Pages Function, so the function is called directly, the way
// middleware.spec.ts calls the middleware: a request, the settings, and a stand-in
// for the mail call. One test enters through onRequestPost, the export Cloudflare
// calls, with the mail call's own fetch replaced. The browser tests then check what a
// visitor sees, with the endpoint answered by the test. No test here sends a real
// email: that one check is the owner's, once, on the deployed site (the skill's "Done
// means").
//
// This file comes with the form (install the skill's three files together), so both
// addresses below have to be set: a form without its privacy text is the case this
// spec exists to refuse.

// The page that carries <ContactForm />, e.g. '/contact'.
const PAGE = '';
// The privacy page, e.g. '/privacy' or '/datenschutz'.
const PRIVACY = '';

// Words each of the form's four sentences must contain, by language. Every sentence is
// held against all of them: it must carry its own language's words for what it says,
// and no language's words for any other sentence, so a thank-you beside a failure or an
// English sentence on a German page fails. Two languages may share the words for the
// same sentence. English and German are built in: add all four for any language added
// to the component.
const WORDS: Record<string, Record<string, RegExp>> = {
  en: { 'data-sending': /Sending/, 'data-sent': /has been sent/, 'data-invalid': /not valid/, 'data-failed': /could not be sent/ },
  de: { 'data-sending': /Wird gesendet/, 'data-sent': /wurde gesendet/, 'data-invalid': /ungültig/, 'data-failed': /konnte nicht gesendet/ },
};
const SENTENCES = ['data-sending', 'data-sent', 'data-invalid', 'data-failed'];

const ENV: Env = { CONTACT_TO: 'owner@example.com', CONTACT_FROM: 'website@example.com', CF_ACCOUNT_ID: 'acc', CF_EMAIL_TOKEN: 'tok' };
const GOOD = { name: 'Ada Lovelace', email: 'ada@example.org', message: 'Hello, do you have time in May?', [TRAP]: '', lang: 'en' };
const SITE_ORIGIN = 'https://site.example';

function post(fields: Record<string, string>, headers: Record<string, string | null> = {}) {
  const all: Record<string, string | null> = { accept: 'application/json', origin: SITE_ORIGIN, ...headers };
  const sent = Object.fromEntries(Object.entries(all).filter((entry): entry is [string, string] => entry[1] !== null));
  return new Request(`${SITE_ORIGIN}/api/contact`, { method: 'POST', headers: sent, body: new URLSearchParams(fields) });
}
// A stand-in for the mail call that records what it was asked to send.
function recorder(result: boolean | Error = true) {
  const sent: Message[] = [];
  const send = async (message: Message) => {
    sent.push(message);
    if (result instanceof Error) throw result;
    return result;
  };
  return { sent, send };
}
// What the function writes to its log while `run` executes: the owner's only way to
// learn why a message did not go out.
async function logged(run: () => Promise<unknown>): Promise<string> {
  const lines: string[] = [];
  const keep = { error: console.error, log: console.log };
  console.error = (...args: unknown[]) => { lines.push(args.map(String).join(' ')); };
  console.log = (...args: unknown[]) => { lines.push(args.map(String).join(' ')); };
  try {
    await run();
  } finally {
    console.error = keep.error;
    console.log = keep.log;
  }
  return lines.join('\n');
}

test('contact — the install is complete: the form\'s page and the privacy page are named', () => {
  expect(PAGE, 'set PAGE in tests/forms.spec.ts to the page that carries <ContactForm />').not.toBe('');
  expect(PRIVACY, 'set PRIVACY in tests/forms.spec.ts to the privacy page').not.toBe('');
});

test('contact — a good message reaches the owner, who can answer the visitor directly', async () => {
  const { sent, send } = recorder();
  let res!: Response;
  const log = await logged(async () => { res = await handle(post(GOOD), ENV, send); });
  expect(res.status).toBe(200);
  expect(await res.json()).toEqual({ ok: true });
  expect(sent).toHaveLength(1);
  // A sent message leaves no line in the log: the skill reads "no line" that way.
  expect(log).toBe('');
  expect(sent[0]).toMatchObject({ to: 'owner@example.com', from: 'website@example.com', reply_to: 'ada@example.org' });
  expect(sent[0].subject).toContain('Ada Lovelace');
  expect(sent[0].text).toContain('Hello, do you have time in May?');
  expect(sent[0].text).toContain('ada@example.org');
  // Addresses a browser accepts must not be refused here: an apostrophe is ordinary.
  const again = recorder();
  expect((await handle(post({ ...GOOD, email: "sean.o'brien@example.ie" }), ENV, again.send)).status).toBe(200);
  expect(again.sent[0].reply_to).toBe("sean.o'brien@example.ie");
});

test('contact — the entry point Cloudflare calls sends through the real mail call', async () => {
  // Every other test hands the function a stand-in for the mail call. This one enters
  // the way a deployment does: onRequestPost, the settings, and the mail call itself.
  // Only the fetch underneath is replaced, so that nothing leaves the machine.
  const real = globalThis.fetch;
  const calls: { url: string; init: RequestInit }[] = [];
  let status = 200;
  globalThis.fetch = (async (url: RequestInfo | URL, init?: RequestInit) => {
    calls.push({ url: String(url), init: init ?? {} });
    const body = status === 200 ? { success: true, result: { delivered: ['owner@example.com'] } } : { success: false, errors: [{ code: 10102 }] };
    return new Response(JSON.stringify(body), { status });
  }) as typeof fetch;
  try {
    const sent = await onRequestPost({ request: post(GOOD), env: ENV });
    expect(sent.status).toBe(200);
    expect(calls).toHaveLength(1);
    expect(calls[0].url).toBe('https://api.cloudflare.com/client/v4/accounts/acc/email/sending/send');
    expect((calls[0].init.headers as Record<string, string>).Authorization).toBe('Bearer tok');
    expect(JSON.parse(String(calls[0].init.body))).toMatchObject({ to: 'owner@example.com', reply_to: 'ada@example.org' });
    // Cloudflare says no: the visitor is told, through the same entry point.
    status = 403;
    let answer!: Response;
    await logged(async () => { answer = await onRequestPost({ request: post(GOOD), env: ENV }); });
    expect(answer.status).toBe(502);
    expect(await answer.json()).toEqual({ ok: false, error: 'send_failed' });
    expect(calls).toHaveLength(2);
    // Without its settings the entry point calls nobody.
    const log = await logged(async () => { answer = await onRequestPost({ request: post(GOOD), env: {} }); });
    expect(answer.status).toBe(503);
    expect(log).toContain('not set on this deployment');
    expect(calls).toHaveLength(2);
  } finally {
    globalThis.fetch = real;
  }
});

test('contact — a missing or malformed field is refused and nothing is sent', async () => {
  const cases: [Record<string, string>, Record<string, string>][] = [
    [{ ...GOOD, message: '   ' }, { message: 'required' }],
    [{ ...GOOD, name: '' }, { name: 'required' }],
    [{ ...GOOD, name: '\u200B\u200B' }, { name: 'required' }],
    [{ ...GOOD, name: '\u034F\uFE0F' }, { name: 'required' }],
    [{ ...GOOD, name: '\u3164\u2800' }, { name: 'required' }],
    [{ ...GOOD, message: '\u200B \u00A0' }, { message: 'required' }],
    [{ ...GOOD, message: '\uFE0F\u034F' }, { message: 'required' }],
    [{ ...GOOD, email: '' }, { email: 'required' }],
    [{ ...GOOD, email: 'ada@example' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada@example.org, eve@example.net' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada@example.org\nBcc: eve@example.net' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada\u0000@example.org' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada\u0085@example.org' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada\u200B@example.org' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada@exam\u202Eple.org' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada\u3164@example.org' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada\u2800@example.org' }, { email: 'invalid' }],
    [{ ...GOOD, name: 'x'.repeat(LIMITS.name + 1) }, { name: 'too_long' }],
    [{ ...GOOD, message: 'x'.repeat(LIMITS.message + 1) }, { message: 'too_long' }],
    [{ name: '', email: 'nope', message: '', [TRAP]: '', lang: 'en' }, { name: 'required', email: 'invalid', message: 'required' }],
  ];
  for (const [fields, expected] of cases) {
    const { sent, send } = recorder();
    const res = await handle(post(fields), ENV, send);
    expect(res.status, JSON.stringify(expected)).toBe(400);
    expect(await res.json()).toEqual({ ok: false, error: 'invalid', fields: expected });
    expect(sent, 'nothing may be sent').toHaveLength(0);
  }
  // A file uploaded under a field's name is not text: the field counts as empty.
  const upload = new FormData();
  for (const [key, value] of Object.entries(GOOD)) upload.set(key, value);
  upload.set('name', new File(['x'], 'name.txt'));
  const filed = recorder();
  const asFile = await handle(new Request(`${SITE_ORIGIN}/api/contact`, { method: 'POST', headers: { accept: 'application/json', origin: SITE_ORIGIN }, body: upload }), ENV, filed.send);
  expect(await asFile.json()).toEqual({ ok: false, error: 'invalid', fields: { name: 'required' } });
  expect(filed.sent).toHaveLength(0);
  // A post that declares far more than a message can be is refused unread.
  const huge = recorder();
  const tooLarge = await handle(post(GOOD, { 'content-length': '200000' }), ENV, huge.send);
  expect(tooLarge.status).toBe(400);
  expect(await tooLarge.json()).toEqual({ ok: false, error: 'invalid', fields: { form: 'too_large' } });
  expect(huge.sent).toHaveLength(0);
  // A message at the limit, with the CRLF line breaks a browser sends, is not too long.
  const paragraphs = Array.from({ length: 100 }, () => 'x'.repeat(49)).join('\r\n');
  expect(paragraphs.replace(/\r\n/g, '\n')).toHaveLength(LIMITS.message - 1);
  const { sent, send } = recorder();
  expect((await handle(post({ ...GOOD, message: paragraphs }), ENV, send)).status, 'CRLF counts once').toBe(200);
  expect(sent).toHaveLength(1);
});

test('contact — a line break in the name cannot start a new mail header', async () => {
  const { sent, send } = recorder();
  await handle(post({ ...GOOD, name: 'Ada\r\nBcc: eve@example.net' }), ENV, send);
  await handle(post({ ...GOOD, name: 'Ada\u0000\u0007 Love\tlace\u007F\u0085\u009F\u2028Bcc: eve\u2029x\u202A\u202B\u202C\u202D\u202Ey\u2066\u2067\u2068\u2069z' }), ENV, send);
  expect(sent).toHaveLength(2);
  for (const message of sent) {
    expect(message.subject).not.toMatch(/[\p{Cc}\p{Zl}\p{Zp}\u202A-\u202E\u2066-\u2069]/u);
    expect(message.text.split('\n')[0], 'the name line of the mail').not.toMatch(/[\p{Cc}\p{Zl}\p{Zp}\u202A-\u202E\u2066-\u2069]/u);
  }
  // Each run of such characters became one space, wherever it stood in the name.
  expect(sent[1].subject).toBe('Website message from Ada  Love lace Bcc: eve x y z');
  // A name made of nothing else is no name.
  const none = recorder();
  expect((await handle(post({ ...GOOD, name: '\u0000\u0001' }), ENV, none.send)).status).toBe(400);
  expect(none.sent).toHaveLength(0);
  // A long name with a two-unit character at the cut is not split in half.
  const long = recorder();
  // 21 characters of prefix and 98 of name put the two-unit character exactly on the cut.
  await handle(post({ ...GOOD, name: 'x'.repeat(98) + '😀' }), ENV, long.send);
  expect(long.sent[0].subject).not.toMatch(/[\uD800-\uDBFF]$/);
});

test('contact — a bot that fills the hidden field gets a thank-you and nothing is sent', async () => {
  const { sent, send } = recorder();
  let res!: Response;
  const log = await logged(async () => { res = await handle(post({ ...GOOD, [TRAP]: 'https://spam.example' }), ENV, send); });
  expect(res.status).toBe(200);
  expect(await res.json()).toEqual({ ok: true });
  expect(sent).toHaveLength(0);
  // Logged, so an owner who suspects lost messages can see drops; without the text.
  expect(log).toContain('dropped a submission');
  expect(log).not.toContain('spam.example');
  expect(log).not.toContain('Ada');
  // The trap's name sent twice, empty first: the filled one still counts. So does a file.
  const twice = new URLSearchParams(GOOD);
  twice.append(TRAP, 'https://spam.example');
  const withFile = new FormData();
  for (const [key, value] of Object.entries(GOOD)) withFile.set(key, value);
  withFile.set(TRAP, new File(['x'], 'spam.txt'));
  for (const body of [twice, withFile]) {
    const again = recorder();
    let answer!: Response;
    const dropped = await logged(async () => {
      answer = await handle(new Request(`${SITE_ORIGIN}/api/contact`, { method: 'POST', headers: { accept: 'application/json', origin: SITE_ORIGIN }, body }), ENV, again.send);
    });
    expect(await answer.json()).toEqual({ ok: true });
    expect(again.sent, 'nothing is sent').toHaveLength(0);
    expect(dropped).toContain('dropped a submission');
  }
});

test('contact — when the mail service refuses or breaks, the visitor is told', async () => {
  // An error that repeats what was sent. A runtime really writes such texts: a token
  // with a line break in it comes back inside the "invalid header value" error.
  const timeout = new Error('"Bearer tok" is an invalid header value; gave up sending "Hello, do you have time in May?" for ada@example.org');
  timeout.name = 'TimeoutError';
  const aborted = new Error('x');
  aborted.name = 'AbortError';
  // An error's name is text too: one outside the function's short list is not repeated.
  const named = new Error('x');
  named.name = 'Bearer tok refused for ada@example.org';
  // Nor is a name that reads as a known kind the first time and as something else the next.
  const shifty = new Error('x');
  let reads = 0;
  Object.defineProperty(shifty, 'name', { get: () => (reads++ === 0 ? 'TypeError' : 'Bearer tok for ada@example.org') });
  for (const result of [false, timeout, aborted, named, shifty]) {
    const { send } = recorder(result);
    let res!: Response;
    const log = await logged(async () => { res = await handle(post(GOOD), ENV, send); });
    expect(res.status).toBe(502);
    expect(await res.json()).toEqual({ ok: false, error: 'send_failed' });
    // The log says what kind of error it was, and never what the visitor wrote.
    if (result === timeout) expect(log).toContain('the mail call failed before an answer came: TimeoutError');
    if (result === aborted) expect(log).toContain('the mail call failed before an answer came: AbortError');
    if (result === named) expect(log).toContain('the mail call failed before an answer came: another error');
    if (result === shifty) expect(log).toContain('the mail call failed before an answer came: TypeError');
    expect(log).not.toContain('time in May');
    expect(log).not.toContain('ada@example.org');
    expect(log).not.toContain('Bearer');
  }
});

test('contact — a deployment without its settings says so, and its log names what is missing', async () => {
  for (const missing of ['CONTACT_TO', 'CONTACT_FROM', 'CF_ACCOUNT_ID', 'CF_EMAIL_TOKEN'] as const) {
    const { sent, send } = recorder();
    let res!: Response;
    const log = await logged(async () => { res = await handle(post(GOOD), { ...ENV, [missing]: undefined }, send); });
    expect(res.status, `${missing} missing`).toBe(503);
    expect(await res.json()).toEqual({ ok: false, error: 'not_configured' });
    expect(sent).toHaveLength(0);
    expect(log).toContain(`not set on this deployment: ${missing}`);
  }
});

test('contact — a post that names another origin is refused, one that names none is let through', async () => {
  for (const origin of ['https://elsewhere.example', 'http://site.example', 'https://site.example.evil.example', 'null']) {
    const { sent, send } = recorder();
    let res!: Response;
    const log = await logged(async () => { res = await handle(post(GOOD, { origin }), ENV, send); });
    expect(res.status, `Origin: ${origin}`).toBe(403);
    expect(sent, `Origin: ${origin}`).toHaveLength(0);
    // The owner's form says "could not be sent" here too, so the log has to say why.
    expect(log, `Origin: ${origin}`).toContain('refused a post that names another origin');
    expect(log, `Origin: ${origin}`).not.toContain(origin);
  }
  // No Origin header at all is let through, on purpose (the function says why). These
  // are header values handed to the function: which browsers send which was not measured.
  const { sent, send } = recorder();
  expect((await handle(post(GOOD, { origin: null }), ENV, send)).status).toBe(200);
  expect(sent).toHaveLength(1);
});

test('contact — without JavaScript the visitor gets a small page in the form\'s language', async () => {
  const { send } = recorder();
  const ok = await handle(post({ ...GOOD, lang: 'de-AT' }, { accept: 'text/html' }), ENV, send);
  expect(ok.headers.get('content-type')).toContain('text/html');
  expect(ok.headers.get('x-content-type-options')).toBe('nosniff');
  const html = await ok.text();
  expect(html).toContain('<html lang="de">');
  expect(html).toContain('Danke.');
  // Each answer is the sentence for what happened and no other, in every language listed
  // in WORDS: one that is listed there and missing from the function gets an English page.
  for (const lang of Object.keys(WORDS)) {
    expect(Object.keys(WORDS[lang]).sort(), `WORDS.${lang} lists all four sentences`).toEqual([...SENTENCES].sort());
    const pages: Record<string, string> = {
      'data-sent': await (await handle(post({ ...GOOD, lang }, { accept: 'text/html' }), ENV, recorder().send)).text(),
      'data-invalid': await (await handle(post({ ...GOOD, lang, email: 'nope' }, { accept: 'text/html' }), ENV, recorder().send)).text(),
      'data-failed': await (await handle(post({ ...GOOD, lang }, { accept: 'text/html' }), ENV, recorder(false).send)).text(),
    };
    for (const [is, answerPage] of Object.entries(pages)) {
      expect(answerPage, `${lang}: the ${is} page`).toContain(`<html lang="${lang}">`);
      for (const [wordsOf, byOutcome] of Object.entries(WORDS)) {
        for (const [name, words] of Object.entries(byOutcome)) {
          if (name === is && wordsOf !== lang) continue;
          expect(words.test(answerPage), `${lang}: the ${is} page and the ${wordsOf} words for ${name}`).toBe(name === is);
        }
      }
    }
  }
  // A language the page does not know, or a word that names something built in.
  for (const lang of ['xx', 'constructor', '__proto__']) {
    const bad = await handle(post({ ...GOOD, email: 'nope', lang }, { accept: 'text/html' }), ENV, send);
    expect(bad.status).toBe(400);
    const page = await bad.text();
    expect(page, lang).toContain('<html lang="en">');
    expect(page, lang).not.toContain('undefined');
  }
  // A failure sends the visitor back to the form, where the address to write to is shown.
  const failed = await handle(post(GOOD, { accept: 'text/html', referer: `${SITE_ORIGIN}/contact?from="x"&a=1` }), ENV, recorder(false).send);
  const failedPage = await failed.text();
  expect(failed.status).toBe(502);
  expect(failedPage).toContain('address to write to');
  expect(failedPage).toContain(`<a href="${SITE_ORIGIN}/contact?from=%22x%22&amp;a=1">Back to the website</a>`);
  // No usable Referer (another site, none, or an address that only looks like this
  // site's): the home page.
  for (const referer of ['https://elsewhere.example/page', null, `blob:${SITE_ORIGIN}/0b1c2d3e`]) {
    const elsewhere = await handle(post(GOOD, { accept: 'text/html', referer }), ENV, recorder(false).send);
    expect(await elsewhere.text(), `Referer: ${referer}`).toContain('<a href="/">Back to the website</a>');
  }
  // A path on this site that a browser would read as another site, were it linked alone.
  for (const referer of [`${SITE_ORIGIN}//elsewhere.example/contact`, `${SITE_ORIGIN}/\\elsewhere.example/contact`]) {
    const tricky = await (await handle(post(GOOD, { accept: 'text/html', referer }), ENV, recorder(false).send)).text();
    const href = tricky.match(/<a href="([^"]*)">/)?.[1] ?? '';
    expect(href, 'the page has a link').not.toBe('');
    expect(new URL(href, `${SITE_ORIGIN}/api/contact`).origin, `the back link for ${referer} stays on this site`).toBe(SITE_ORIGIN);
  }
  const { outcome } = await decide(post({ ...GOOD, email: 'nope' }), ENV, send);
  expect(outcome.body.fields).toEqual({ email: 'invalid' });
});

test('contact — the mail call asks Cloudflare the right way, believes only a real yes, and logs a refusal', async () => {
  const message: Message = { to: 'owner@example.com', from: 'website@example.com', reply_to: 'ada@example.org', subject: 's', text: 'the visitor wrote this' };
  const env = { CONTACT_TO: 'owner@example.com', CONTACT_FROM: 'website@example.com', CF_ACCOUNT_ID: 'acc-1', CF_EMAIL_TOKEN: 'tok-1' };
  const calls: { url: string; init: RequestInit }[] = [];
  const answer = (status: number, body: unknown) => (async (url: RequestInfo | URL, init?: RequestInit) => {
    calls.push({ url: String(url), init: init ?? {} });
    return new Response(typeof body === 'string' ? body : JSON.stringify(body), { status });
  }) as typeof fetch;

  let yes = false;
  const quiet = await logged(async () => { yes = await sendViaCloudflare(message, env, answer(200, { success: true, result: { delivered: ['owner@example.com'], queued: [], permanent_bounces: [] } })); });
  expect(yes).toBe(true);
  expect(quiet, 'a yes leaves no line').toBe('');
  expect(calls[0].url).toBe('https://api.cloudflare.com/client/v4/accounts/acc-1/email/sending/send');
  expect(calls[0].init.method).toBe('POST');
  expect((calls[0].init.headers as Record<string, string>).Authorization).toBe('Bearer tok-1');
  expect(JSON.parse(String(calls[0].init.body))).toEqual(message);
  expect(calls[0].init.signal, 'the call gives up after a while instead of hanging').toBeInstanceOf(AbortSignal);

  expect(await sendViaCloudflare(message, env, answer(200, { success: true, result: { delivered: [], queued: ['owner@example.com'] } })), 'queued counts').toBe(true);
  const refusals: [string, number, unknown][] = [
    ['a bounce is not a yes', 200, { success: true, result: { delivered: [], queued: [], permanent_bounces: ['owner@example.com'] } }],
    ['success: false', 200, { success: false, errors: [{ code: 10001, message: 'email.sending.error.invalid_request_schema' }], result: null }],
    ['a refused token', 403, { success: false, errors: [{ code: 10102, message: 'email.sending.error.authentication.forbidden' }] }],
    ['an error text that repeats what was sent', 400, { success: false, errors: [{ code: 10001, message: 'bad token tok-1 for "the visitor wrote this" from ada@example.org' }] }],
    ['errors in a shape nobody documented', 400, { success: false, errors: 'tok-1 the visitor wrote this' }],
    ['a bounce list that is not a list', 200, { success: false, result: { permanent_bounces: { length: 'tok-1 the visitor wrote this ada@example.org' } } }],
    ['"delivered" as a text, not a list of addresses', 200, { success: true, result: { delivered: 'owner@example.com' } }],
    ['an error status is never a yes', 500, { success: true, result: { delivered: ['owner@example.com'] } }],
    ['an answer that cannot be read', 200, 'not json'],
  ];
  for (const [why, status, body] of refusals) {
    let ok = true;
    const log = await logged(async () => { ok = await sendViaCloudflare(message, env, answer(status, body)); });
    expect(ok, why).toBe(false);
    // What the owner reads when a message does not arrive: Cloudflare's status and
    // its numeric error codes. Never the token, never the visitor's words or address,
    // and so none of Cloudflare's error text either.
    expect(log, why).toContain(`"status":${status}`);
    expect(log, why).not.toContain('tok-1');
    expect(log, why).not.toContain('the visitor wrote this');
    expect(log, why).not.toContain('ada@example.org');
  }
  const refused = await logged(async () => { await sendViaCloudflare(message, env, answer(403, { success: false, errors: [{ code: 10102, message: 'email.sending.error.authentication.forbidden' }] })); });
  expect(refused).toContain('"errors":1');
  expect(refused).toContain('"codes":[10102]');
  expect(refused).not.toContain('authentication.forbidden');
  // A code that arrives as digits in a text is still a code. One that is not is counted,
  // so "no code" can be told from "no error".
  const texts = await logged(async () => { await sendViaCloudflare(message, env, answer(400, { success: false, errors: [{ code: '10001' }, { code: 'E_tok-1' }] })); });
  expect(texts).toContain('"errors":2');
  expect(texts).toContain('"codes":[10001]');
  expect(texts).not.toContain('tok-1');
});

test('contact — every field has a label, and the bot trap is out of everyone\'s way', async ({ page }) => {
  test.skip(!PAGE, 'PAGE is not set');
  await page.goto(PAGE);
  const form = page.locator('#contact-form');
  await expect(form).toHaveCount(1);
  for (const id of ['contact-name', 'contact-email', 'contact-message']) {
    await expect(page.locator(`label[for="${id}"]`), `a visible label for #${id}`).toBeVisible();
    await expect(page.locator(`#${id}`)).toHaveAttribute('required', '');
  }
  // The sentences the form's script chooses from are all there and all different: the
  // outcome tests below take the expected sentence from these same attributes.
  const sentences = await Promise.all(SENTENCES.map((name) => form.getAttribute(name)));
  expect(sentences.every((sentence) => sentence && sentence.trim() !== ''), 'four sentences').toBe(true);
  expect(new Set(sentences).size, 'four different sentences').toBe(4);
  // The form's link leads to the privacy page this spec checks.
  await expect(form.locator('.contact-form-note a'), `the form's privacy link (the component's default, or privacy="…") is ${PRIVACY}`).toHaveAttribute('href', PRIVACY);
  // The form speaks the language of its page, and that language's words are listed above.
  const language = (await form.locator('input[name="lang"]').getAttribute('value')) ?? '';
  const pageLanguage = ((await page.locator('html').getAttribute('lang')) ?? '').toLowerCase().split('-')[0];
  expect(language, 'the form is in the language of its page').toBe(pageLanguage);
  expect(Object.hasOwn(WORDS, language), `the words of the form's language ("${language}") are in WORDS`).toBe(true);
  for (const attribute of SENTENCES) {
    const sentence = (await form.getAttribute(attribute)) ?? '';
    for (const [wordsOf, byOutcome] of Object.entries(WORDS)) {
      for (const [name, words] of Object.entries(byOutcome)) {
        if (name === attribute && wordsOf !== language) continue;
        expect(words.test(sentence), `${attribute} and the ${wordsOf} words for ${name}`).toBe(name === attribute);
      }
    }
  }
  const trap = page.locator(`[name="${TRAP}"]`);
  await expect(trap).toHaveCount(1);
  await expect(page.locator('.contact-form-trap')).toHaveAttribute('aria-hidden', 'true');
  await expect(trap).not.toBeInViewport();
  // By keyboard: name, email, message, then on past the trap. Focus never lands on it.
  await page.focus('#contact-name');
  const visited: (string | null)[] = [];
  for (let i = 0; i < 4; i += 1) {
    await page.keyboard.press('Tab');
    visited.push(await page.evaluate(() => document.activeElement?.id || document.activeElement?.tagName || null));
  }
  expect(visited.slice(0, 2)).toEqual(['contact-email', 'contact-message']);
  expect(visited, 'the trap is not reachable by Tab').not.toContain('contact-leave-empty');
});

// `says` names the form's data attribute that holds the sentence the visitor must get.
// `answer` is what the endpoint returns; "lost" is a post that gets no answer: it never
// arrived, or the answer was lost after the function had done its work. The browser
// cannot tell the two apart, and says "could not be sent" for both.
for (const [name, answer, says] of [
  ['sent', { status: 200, body: { ok: true } }, 'data-sent'],
  ['not sent', { status: 502, body: { ok: false, error: 'send_failed' } }, 'data-failed'],
  ['refused by the function', { status: 400, body: { ok: false, error: 'invalid', fields: { email: 'invalid' } } }, 'data-invalid'],
  ['answered with something that is not an answer', { status: 200, body: null }, 'data-failed'],
  ['lost on the way', 'lost', 'data-failed'],
] as const) {
  test(`contact — the status line and the fallback address when the message is ${name}`, async ({ page }) => {
    test.skip(!PAGE, 'PAGE is not set');
    let posted: string | null = null;
    await page.route('**/api/contact', async (route) => {
      posted = route.request().postData();
      if (answer === 'lost') await route.abort('failed');
      else await route.fulfill({ status: answer.status, contentType: 'application/json', body: JSON.stringify(answer.body) });
    });
    await page.goto(PAGE);
    await page.fill('#contact-name', 'Ada Lovelace');
    await page.fill('#contact-email', 'ada@example.org');
    await page.fill('#contact-message', 'Hello, do you have time in May?');
    await page.click('#contact-form button[type="submit"]');
    // The right sentence ends up in the role="status" line: the one a screen reader is
    // told to read out. That it is spoken is not checked here; no test listens.
    const sentence = await page.locator('#contact-form').getAttribute(says);
    expect(sentence, `the form carries ${says}`).toBeTruthy();
    await expect(page.locator('#contact-form [role="status"]')).toHaveText(sentence!);
    // Another way to reach the owner is there whatever happened.
    const direct = page.locator('[data-contact-direct]');
    await expect(direct).toBeVisible();
    await expect(direct.locator('a')).toHaveCount(1);
    await expect(page.locator('#contact-message')).toHaveValue(says === 'data-sent' ? '' : 'Hello, do you have time in May?');
    await expect(page.locator('#contact-form button[type="submit"]')).toBeEnabled();
    expect(posted, 'the form posted to the endpoint').toContain('Ada Lovelace');
  });
}

test('contact — an empty form is stopped in the browser, before anything is posted', async ({ page }) => {
  test.skip(!PAGE, 'PAGE is not set');
  let posts = 0;
  await page.route('**/api/contact', async (route) => { posts += 1; await route.fulfill({ status: 200, contentType: 'application/json', body: '{"ok":true}' }); });
  await page.goto(PAGE);
  await page.click('#contact-form button[type="submit"]');
  await expect(page.locator('#contact-name:invalid')).toHaveCount(1);
  // The form's script writes "Sending…" the moment a submission starts: it never did.
  await expect(page.locator('#contact-form [role="status"]')).toBeEmpty();
  expect(posts).toBe(0);
});

test('contact — a visitor without JavaScript is shown the address to write to', async ({ browser, baseURL }) => {
  test.skip(!PAGE, 'PAGE is not set');
  // A browser that runs no script at all: nothing can reveal anything, so the address
  // has to be on the page as served, in a form a person can read ("name [at] …").
  const context = await browser.newContext({ javaScriptEnabled: false, baseURL });
  const page = await context.newPage();
  await page.goto(PAGE);
  const direct = page.locator('#contact-form [data-contact-direct]');
  await expect(direct).toBeVisible();
  await expect(direct.locator('a')).toHaveText(/\S+ \[[a-z]+\] \S+/);
  await context.close();
});

test('contact — the privacy page says what happens to a message sent through the form', async ({ page }) => {
  test.skip(!PRIVACY, 'PRIVACY is not set');
  await page.goto(PRIVACY);
  const marked = page.locator('[data-privacy-contact-form]');
  await expect(
    marked,
    `${PRIVACY} has a contact form to answer for: add the sentences from the website-forms skill, marked data-privacy-contact-form`,
  ).toHaveCount(1);
  const text = ((await marked.textContent()) ?? '').trim();
  expect(text.split(/\s+/).length, 'the marked text says something').toBeGreaterThanOrEqual(15);
  expect(text, 'it names who delivers the message').toContain('Cloudflare');
});
