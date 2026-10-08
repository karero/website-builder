// The mail-app contact form (the website-contact-form skill), installed as
// tests/mail-form.spec.ts. Set PAGE and TO below; the spec fails while either is empty.
// One copy guards one form: a site with the form on pages in two languages gets two
// copies (tests/mail-form.de.spec.ts), each with its own PAGE.
//
// Every test enters the way a visitor does: the page as built, the real button. The
// mail program itself is out of reach of a test; what is checked is the mailto: link
// the browser is asked to open, which is everything the mail program receives.
//
// It imports `toneViolations` from tests/_helpers.ts, the tone rules the site's pages
// are held to. A site made from an older starter lacks it: see the skill, §1.
import { test, expect, type Page } from '@playwright/test';
import { LIMITS, TEXT, hasText } from '../src/components/mail-form-text';
import { toneViolations } from './_helpers';

const PAGE = '';    // the page with the form, e.g. '/contact'
const TO = '';      // the address given to <MailForm to="…">
const SUBJECT = ''; // only if the page passes subject="…": that subject

// The mailto: link the button asks the browser to open. The browser hands it to the
// mail program; Playwright sees it as a request.
async function pressSend(page: Page): Promise<string> {
  const lang = await formLanguage(page);
  const asked = page.waitForRequest((r) => r.url().startsWith('mailto:'), { timeout: 5000 });
  await page.getByRole('button', { name: TEXT[lang].send }).click();
  return (await asked).url();
}

// The link's parts, each decoded once. Not URLSearchParams: it reads "+" as a space.
function parse(mailto: string) {
  const [address, query = ''] = mailto.slice('mailto:'.length).split('?');
  const params = Object.fromEntries(query.split('&').map((pair) => {
    const [key, value = ''] = pair.split('=');
    return [key, decodeURIComponent(value)];
  }));
  return { address, query, params };
}

async function formLanguage(page: Page) {
  const lang = (await page.locator('form[data-mail-form]').getAttribute('lang')) ?? '';
  expect(hasText(lang), `the form speaks "${lang}", which has no texts in mail-form-text.ts`).toBe(true);
  return lang as keyof typeof TEXT;
}

test('mail form — the install is complete: the form\'s page and its address are named', () => {
  expect(PAGE, 'set PAGE in tests/mail-form.spec.ts to the page with the form').not.toBe('');
  expect(TO, 'set TO in tests/mail-form.spec.ts to the address given to <MailForm to="…">').not.toBe('');
});

test('mail form — the button opens a mail to the owner with everything the visitor wrote', async ({ page }) => {
  await page.goto(PAGE);
  const lang = await formLanguage(page);
  // Characters that break a link unless each is encoded: & ? # % + = and a line break,
  // and letters outside ASCII.
  const name = 'Ada Lovelace & Co';
  const message = 'Is 100% possible? Price #1 + extras = fine.\nZweite Zeile: Grüße, ça va';
  await page.getByLabel(TEXT[lang].name).fill(name);
  await page.getByLabel(TEXT[lang].message).fill(message);
  const mailto = await pressSend(page);
  const { address, query, params } = parse(mailto);

  expect(address, 'the mail goes to TO: the address was decoded right').toBe(TO);
  expect(Object.keys(params).sort(), 'a subject and a body, nothing else').toEqual(['body', 'subject']);
  expect(params.subject).toBe(SUBJECT || TEXT[lang].subject);
  // Every character outside the few a link may carry as they are arrives encoded, so
  // nothing the visitor typed can end the subject early or start a new part.
  expect(query, 'the subject and body are URL-encoded').toMatch(/^subject=[A-Za-z0-9\-_.!~*'()%]*&body=[A-Za-z0-9\-_.!~*'()%]*$/);
  expect(query, 'a line break is %0D%0A (RFC 6068), never a bare %0A').not.toMatch(/(?<!%0D)%0A/);
  expect(params.body).toBe(`${TEXT[lang].greeting}\r\n\r\n${message.replace(/\n/g, '\r\n')}\r\n\r\n${TEXT[lang].name}: ${name}`);

  // The site cannot know whether the mail program opened, so it says what to do next.
  await expect(page.getByRole('status')).toHaveText(TEXT[lang].opened);
});

test('mail form — a field the owner adds goes into the mail by its label; one left empty does not', async ({ page }) => {
  await page.goto(PAGE);
  const lang = await formLanguage(page);
  await page.locator('form[data-mail-form] button[type="submit"]').evaluate((button) => {
    for (const [id, label] of [['added-phone', 'Phone'], ['added-company', 'Company']]) {
      const p = document.createElement('p');
      p.innerHTML = `<label for="${id}">${label}</label><input id="${id}" name="${id}" type="text">`;
      button.closest('p')!.before(p);
    }
  });
  await page.getByLabel(TEXT[lang].name).fill('Ada');
  await page.getByLabel(TEXT[lang].message).fill('Hello there');
  await page.getByLabel('Phone').fill('+49 30 1234');
  const { params } = parse(await pressSend(page));
  expect(params.body).toContain(`${TEXT[lang].name}: Ada\r\nPhone: +49 30 1234`);
  expect(params.body).not.toContain('Company');
});

test('mail form — an empty field stops the browser, and no mail opens', async ({ page }) => {
  await page.goto(PAGE);
  const lang = await formLanguage(page);
  let opened = false;
  page.on('request', (r) => { if (r.url().startsWith('mailto:')) opened = true; });
  await page.getByLabel(TEXT[lang].message).fill('A message without a name');
  await page.getByRole('button', { name: TEXT[lang].send }).click();
  await page.waitForTimeout(500);
  expect(opened, 'no mail opened without a name').toBe(false);
  await expect(page.getByLabel(TEXT[lang].name)).toBeFocused();
  await expect(page.getByRole('status')).toHaveText('');
});

test('mail form — the fields take no more than the limits', async ({ page }) => {
  await page.goto(PAGE);
  const lang = await formLanguage(page);
  await expect(page.getByLabel(TEXT[lang].name)).toHaveAttribute('maxlength', String(LIMITS.name));
  await expect(page.getByLabel(TEXT[lang].message)).toHaveAttribute('maxlength', String(LIMITS.message));
});

test('mail form — every field has a label, and Tab goes from field to field to the button', async ({ page }) => {
  await page.goto(PAGE);
  const lang = await formLanguage(page);
  const order = [page.getByLabel(TEXT[lang].name), page.getByLabel(TEXT[lang].message), page.getByRole('button', { name: TEXT[lang].send })];
  // Every control in the form is one of these: none without a label slipped in.
  await expect(page.locator('form[data-mail-form] :is(input, textarea, select, button)')).toHaveCount(order.length);
  await order[0].focus();
  for (const next of order.slice(1)) {
    await page.keyboard.press('Tab');
    await expect(next).toBeFocused();
  }
});

test('mail form — the plain address shows under the form, ready to copy and to click', async ({ page }) => {
  await page.goto(PAGE);
  const lang = await formLanguage(page);
  const direct = page.locator('.mail-form-direct');
  await expect(direct).toContainText(TEXT[lang].direct);
  const link = direct.getByRole('link');
  await expect(link).toHaveText(TO);
  await expect(link).toHaveAttribute('href', new RegExp(`^mailto:${TO.replace(/[.+]/g, '\\$&')}\\?subject=`));
});

test('mail form — without JavaScript the form stays hidden and the address is shown', async ({ browser, baseURL }) => {
  const context = await browser.newContext({ javaScriptEnabled: false, baseURL });
  const page = await context.newPage();
  const response = await page.goto(PAGE);
  const html = await response!.text();
  expect(html.includes(TO), 'the address is never in the HTML as plain text').toBe(false);
  // A form that cannot open a mail program is not shown at all.
  await expect(page.locator('form[data-mail-form]')).toBeHidden();
  const [user, domain] = TO.split('@');
  await expect(page.locator('.mail-form-direct')).toBeVisible();
  await expect(page.locator('.mail-form-direct')).toContainText(`${user} [at] ${domain.split('.')[0]}`);
  await context.close();
});

test('mail form — it works under a strict Content-Security-Policy that allows the site\'s own scripts only', async ({ page }) => {
  await page.route(`**${PAGE}`, async (route) => {
    const response = await route.fetch();
    await route.fulfill({ response, headers: { ...response.headers(), 'content-security-policy': "script-src 'self'" } });
  });
  await page.goto(PAGE);
  const lang = await formLanguage(page);
  await expect(page.locator('form[data-mail-form]')).toBeVisible();
  await page.getByLabel(TEXT[lang].name).fill('Ada');
  await page.getByLabel(TEXT[lang].message).fill('Hello');
  expect(parse(await pressSend(page)).address).toBe(TO);
});

test('mail form — every text of the form keeps to the site\'s tone rules, in every language', () => {
  const found = Object.entries(TEXT).flatMap(([lang, texts]) =>
    Object.entries(texts).flatMap(([key, text]) => toneViolations(text, lang).map((v: string) => `  • ${lang}.${key}: ${v}`)));
  expect(found, `texts in src/components/mail-form-text.ts break the tone rules:\n${found.join('\n')}`).toEqual([]);
});
