// The contact form's words and limits (the website-forms skill), installed as
// src/components/contact-form.ts. One file for both sides: the form
// (src/components/ContactForm.astro) and the endpoint (functions/api/contact.ts)
// import it, so a language is added, or a sentence changed, here and nowhere else.
// Cloudflare bundles whatever the function imports, this file included. Keep it plain
// TypeScript: no Astro imports, nothing from the site's config.
//
// tests/forms.spec.ts checks these texts against words of its own (WORDS). That list
// stays in the spec on purpose: it is an independent check, a few words per sentence,
// that catches a sentence left in another language or swapped with another. It does
// not read for meaning or tone.

// The longest name, address and message the form takes. The form's fields stop there
// and the function refuses anything longer.
export const LIMITS = { name: 100, email: 254, message: 5000 };

// The mail the owner receives: its subject starts with `subject`, its text starts with
// the name and address under these two labels. In the owner's language, which need not
// be the visitor's. The subject is cut at 120 characters; keep `subject` to 90 at most,
// so a name still fits. The spec checks a new one as it stands, and fails above 90.
export const MAIL = { subject: 'Website message from ', name: 'Name', email: 'Email' };

// Everything a visitor reads, by language. tests/forms.spec.ts holds every text here to
// the site's tone rules (tests/_helpers.ts): no long dash, and in English no contraction.
// In German they address nobody, so the form fits a "du" site and a "Sie" site alike. `page` is what a visitor without JavaScript reads
// after sending: on a failure it sends them back to the form, where the address to
// write to is always shown, by the browser's own Back button (the link under the
// sentence loads the page afresh). A language that leaves one of these out fails
// `npm run check`.
type Texts = {
  name: string; email: string; message: string; send: string;
  note: string; privacyLink: string; privacy: string; trap: string;
  sending: string; sent: string; invalid: string; failed: string; direct: string;
  page: { title: string; sent: string; invalid: string; failed: string; back: string };
};
export const TEXT = {
  en: {
    name: 'Name', email: 'Email address', message: 'Message', send: 'Send message',
    note: 'What you enter here is sent to us by email and used only to answer you.',
    privacyLink: 'Privacy policy', privacy: '/privacy',
    trap: 'Leave this field empty',
    sending: 'Sending…',
    sent: 'Thank you. The message has been sent.',
    invalid: 'Some details are missing or not valid. Please check the fields.',
    failed: 'The message could not be sent. Please write to the address shown below.',
    direct: 'Or write to us directly:',
    page: {
      title: 'Contact',
      sent: 'Thank you. The message has been sent.',
      invalid: 'Some details are missing or not valid. Please use the Back button of the browser and check them.',
      failed: 'The message could not be sent. Please use the Back button of the browser: the address to write to is shown with the form.',
      back: 'Back to the website',
    },
  },
  de: {
    name: 'Name', email: 'E-Mail-Adresse', message: 'Nachricht', send: 'Nachricht senden',
    note: 'Die Angaben werden per E-Mail an uns gesendet und nur für die Antwort verwendet.',
    privacyLink: 'Datenschutzerklärung', privacy: '/datenschutz',
    trap: 'Dieses Feld bitte leer lassen',
    sending: 'Wird gesendet…',
    sent: 'Danke. Die Nachricht wurde gesendet.',
    invalid: 'Einige Angaben fehlen oder sind ungültig. Bitte die Felder prüfen.',
    failed: 'Die Nachricht konnte nicht gesendet werden. Bitte an die unten stehende Adresse schreiben.',
    direct: 'Oder direkt per E-Mail schreiben:',
    page: {
      title: 'Kontakt',
      sent: 'Danke. Die Nachricht wurde gesendet.',
      invalid: 'Einige Angaben fehlen oder sind ungültig. Bitte mit der Zurück-Taste des Browsers zurückgehen und prüfen.',
      failed: 'Die Nachricht konnte nicht gesendet werden. Bitte mit der Zurück-Taste des Browsers zurückgehen: Die Adresse für eine direkte Nachricht steht beim Formular.',
      back: 'Zurück zur Website',
    },
  },
} satisfies Record<string, Texts>;

export type Language = keyof typeof TEXT;

// Whether there are texts for a language. Own keys only: "constructor" or "__proto__"
// sent as a language is not one.
export const hasText = (lang: string): lang is Language => Object.hasOwn(TEXT, lang);
