import { test, expect } from '@playwright/test';
import { decide, handle, sendViaCloudflare, LIMITS, type Env, type Message } from '../functions/api/contact';

// Guards the contact form (the website-forms skill). `astro preview` never runs a
// Cloudflare Pages Function, so the function is called directly, the way
// middleware.spec.ts calls the middleware: a request, the settings, and a stand-in
// for the mail call. The browser tests then check what a visitor sees, with the
// endpoint answered by the test. No test here sends a real email: that one check is
// the owner's, once, on the deployed site (the skill's "Done means").

// The page that carries <ContactForm />, e.g. '/contact'. Empty = the browser tests skip.
const PAGE = '';
// The privacy page, e.g. '/privacy' or '/datenschutz'. Empty = that test skips.
const PRIVACY = '';

const ENV: Env = { CONTACT_TO: 'owner@example.com', CONTACT_FROM: 'website@example.com', CF_ACCOUNT_ID: 'acc', CF_EMAIL_TOKEN: 'tok' };
const GOOD = { name: 'Ada Lovelace', email: 'ada@example.org', message: 'Hello, do you have time in May?', website: '', lang: 'en' };

function post(fields: Record<string, string>, headers: Record<string, string> = {}) {
  return new Request('https://site.example/api/contact', {
    method: 'POST',
    headers: { accept: 'application/json', origin: 'https://site.example', ...headers },
    body: new URLSearchParams(fields),
  });
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

test('contact — a good message reaches the owner, who can answer the visitor directly', async () => {
  const { sent, send } = recorder();
  const res = await handle(post(GOOD), ENV, send);
  expect(res.status).toBe(200);
  expect(await res.json()).toEqual({ ok: true });
  expect(sent).toHaveLength(1);
  expect(sent[0]).toMatchObject({ to: 'owner@example.com', from: 'website@example.com', reply_to: 'ada@example.org' });
  expect(sent[0].subject).toContain('Ada Lovelace');
  expect(sent[0].text).toContain('Hello, do you have time in May?');
  expect(sent[0].text).toContain('ada@example.org');
});

test('contact — a missing or malformed field is refused and nothing is sent', async () => {
  const cases: [Record<string, string>, Record<string, string>][] = [
    [{ ...GOOD, message: '   ' }, { message: 'required' }],
    [{ ...GOOD, name: '' }, { name: 'required' }],
    [{ ...GOOD, email: '' }, { email: 'required' }],
    [{ ...GOOD, email: 'ada@example' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada@example.org, eve@example.net' }, { email: 'invalid' }],
    [{ ...GOOD, email: 'ada@example.org\nBcc: eve@example.net' }, { email: 'invalid' }],
    [{ ...GOOD, name: 'x'.repeat(LIMITS.name + 1) }, { name: 'too_long' }],
    [{ ...GOOD, message: 'x'.repeat(LIMITS.message + 1) }, { message: 'too_long' }],
    [{ name: '', email: 'nope', message: '', website: '', lang: 'en' }, { name: 'required', email: 'invalid', message: 'required' }],
  ];
  for (const [fields, expected] of cases) {
    const { sent, send } = recorder();
    const res = await handle(post(fields), ENV, send);
    expect(res.status, JSON.stringify(expected)).toBe(400);
    expect(await res.json()).toEqual({ ok: false, error: 'invalid', fields: expected });
    expect(sent, 'nothing may be sent').toHaveLength(0);
  }
});

test('contact — a line break in the name cannot start a new mail header', async () => {
  const { sent, send } = recorder();
  await handle(post({ ...GOOD, name: 'Ada\r\nBcc: eve@example.net' }), ENV, send);
  expect(sent).toHaveLength(1);
  expect(sent[0].subject).not.toMatch(/[\r\n]/);
});

test('contact — a bot that fills the hidden field gets a thank-you and nothing is sent', async () => {
  const { sent, send } = recorder();
  const res = await handle(post({ ...GOOD, website: 'https://spam.example' }), ENV, send);
  expect(res.status).toBe(200);
  expect(await res.json()).toEqual({ ok: true });
  expect(sent).toHaveLength(0);
});

test('contact — when the mail service refuses or breaks, the visitor is told', async () => {
  for (const result of [false, new Error('network down')]) {
    const { send } = recorder(result);
    const res = await handle(post(GOOD), ENV, send);
    expect(res.status).toBe(502);
    expect(await res.json()).toEqual({ ok: false, error: 'send_failed' });
  }
});

test('contact — a deployment without its settings says so instead of pretending', async () => {
  for (const missing of ['CONTACT_TO', 'CONTACT_FROM', 'CF_ACCOUNT_ID', 'CF_EMAIL_TOKEN'] as const) {
    const { sent, send } = recorder();
    const res = await handle(post(GOOD), { ...ENV, [missing]: undefined }, send);
    expect(res.status, `${missing} missing`).toBe(503);
    expect(await res.json()).toEqual({ ok: false, error: 'not_configured' });
    expect(sent).toHaveLength(0);
  }
});

test('contact — a form on another site may not post here', async () => {
  const { sent, send } = recorder();
  const res = await handle(post(GOOD, { origin: 'https://elsewhere.example' }), ENV, send);
  expect(res.status).toBe(403);
  expect(sent).toHaveLength(0);
});

test('contact — without JavaScript the visitor gets a small page in the form\'s language', async () => {
  const { send } = recorder();
  const ok = await handle(post({ ...GOOD, lang: 'de-AT' }, { accept: 'text/html' }), ENV, send);
  expect(ok.headers.get('content-type')).toContain('text/html');
  const html = await ok.text();
  expect(html).toContain('<html lang="de">');
  expect(html).toContain('Danke.');
  const bad = await handle(post({ ...GOOD, email: 'nope', lang: 'xx' }, { accept: 'text/html' }), ENV, send);
  expect(bad.status).toBe(400);
  expect(await bad.text()).toContain('<html lang="en">');
  const { outcome } = await decide(post({ ...GOOD, email: 'nope' }), ENV, send);
  expect(outcome.body.fields).toEqual({ email: 'invalid' });
});

test('contact — the mail call asks Cloudflare the right way and believes only a real yes', async () => {
  const message: Message = { to: 'owner@example.com', from: 'website@example.com', reply_to: 'ada@example.org', subject: 's', text: 't' };
  const env = { CONTACT_TO: 'owner@example.com', CONTACT_FROM: 'website@example.com', CF_ACCOUNT_ID: 'acc-1', CF_EMAIL_TOKEN: 'tok-1' };
  const calls: { url: string; init: RequestInit }[] = [];
  const answer = (status: number, body: unknown) => (async (url: RequestInfo | URL, init?: RequestInit) => {
    calls.push({ url: String(url), init: init ?? {} });
    return new Response(typeof body === 'string' ? body : JSON.stringify(body), { status });
  }) as typeof fetch;

  expect(await sendViaCloudflare(message, env, answer(200, { success: true, result: { delivered: ['owner@example.com'], queued: [], permanent_bounces: [] } }))).toBe(true);
  expect(calls[0].url).toBe('https://api.cloudflare.com/client/v4/accounts/acc-1/email/sending/send');
  expect(calls[0].init.method).toBe('POST');
  expect((calls[0].init.headers as Record<string, string>).Authorization).toBe('Bearer tok-1');
  expect(JSON.parse(String(calls[0].init.body))).toEqual(message);

  expect(await sendViaCloudflare(message, env, answer(200, { success: true, result: { delivered: [], queued: ['owner@example.com'] } })), 'queued counts').toBe(true);
  expect(await sendViaCloudflare(message, env, answer(200, { success: true, result: { delivered: [], queued: [], permanent_bounces: ['owner@example.com'] } })), 'a bounce is not a yes').toBe(false);
  expect(await sendViaCloudflare(message, env, answer(200, { success: false, errors: [{ code: 10001 }], result: null })), 'success: false').toBe(false);
  expect(await sendViaCloudflare(message, env, answer(403, { success: false })), 'a refused token').toBe(false);
  expect(await sendViaCloudflare(message, env, answer(500, { success: true, result: { delivered: ['owner@example.com'] } })), 'an error status is never a yes').toBe(false);
  expect(await sendViaCloudflare(message, env, answer(200, 'not json')), 'an answer that cannot be read').toBe(false);
});

test('contact — the form can be filled by keyboard and by screen reader', async ({ page }) => {
  test.skip(!PAGE, 'PAGE is not set: name the page that carries <ContactForm />');
  await page.goto(PAGE);
  const form = page.locator('#contact-form');
  await expect(form).toHaveCount(1);
  for (const label of ['#contact-name', '#contact-email', '#contact-message']) {
    await expect(page.locator(`label[for="${label.slice(1)}"]`), `a visible label for ${label}`).toBeVisible();
    await expect(page.locator(label)).toHaveAttribute('required', '');
  }
  // The bot trap must stay out of everyone's way.
  const trap = page.locator('#contact-website');
  await expect(trap).toHaveAttribute('tabindex', '-1');
  await expect(page.locator('.contact-form-trap')).toHaveAttribute('aria-hidden', 'true');
  await expect(trap).not.toBeInViewport();
});

for (const [name, answer, expectSent] of [
  ['sent', { status: 200, body: { ok: true } }, true],
  ['not sent', { status: 502, body: { ok: false, error: 'send_failed' } }, false],
] as const) {
  test(`contact — what the visitor sees when the message is ${name}`, async ({ page }) => {
    test.skip(!PAGE, 'PAGE is not set: name the page that carries <ContactForm />');
    let posted: string | null = null;
    await page.route('**/api/contact', async (route) => {
      posted = route.request().postData();
      await route.fulfill({ status: answer.status, contentType: 'application/json', body: JSON.stringify(answer.body) });
    });
    await page.goto(PAGE);
    await page.fill('#contact-name', 'Ada Lovelace');
    await page.fill('#contact-email', 'ada@example.org');
    await page.fill('#contact-message', 'Hello, do you have time in May?');
    await page.click('#contact-form button[type="submit"]');
    const status = page.locator('[data-contact-status]');
    const failed = page.locator('[data-contact-failed]');
    if (expectSent) {
      await expect(status).not.toBeEmpty();
      await expect(failed).toBeHidden();
      await expect(page.locator('#contact-message'), 'the form is cleared after sending').toHaveValue('');
    } else {
      await expect(failed, 'the visitor is told, and given another way').toBeVisible();
      await expect(failed.locator('a')).toHaveCount(1);
      await expect(page.locator('#contact-message'), 'what was typed is kept').toHaveValue('Hello, do you have time in May?');
    }
    expect(posted, 'the form posted to the endpoint').toContain('Ada Lovelace');
  });
}

test('contact — an empty form is stopped in the browser, before anything is posted', async ({ page }) => {
  test.skip(!PAGE, 'PAGE is not set: name the page that carries <ContactForm />');
  let posts = 0;
  await page.route('**/api/contact', async (route) => { posts += 1; await route.fulfill({ status: 200, contentType: 'application/json', body: '{"ok":true}' }); });
  await page.goto(PAGE);
  await page.click('#contact-form button[type="submit"]');
  await expect(page.locator('#contact-name:invalid')).toHaveCount(1);
  expect(posts).toBe(0);
});

test('contact — the privacy page says what happens to a message', async ({ page }) => {
  test.skip(!PRIVACY, 'PRIVACY is not set: name the privacy page');
  await page.goto(PRIVACY);
  await expect(
    page.locator('[data-privacy-contact-form]'),
    `${PRIVACY} has a contact form to answer for: add the paragraph from the website-forms skill (marked data-privacy-contact-form)`,
  ).toHaveCount(1);
});
