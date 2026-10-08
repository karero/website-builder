// The mail-app contact form (the website-contact-form skill), installed as
// public/js/mail-form.js and loaded by src/components/MailForm.astro. A file of the
// site's own, not an inline script, so a strict Content-Security-Policy
// (script-src 'self') lets it run. Plain JavaScript: it is served exactly as written.
//
// It shows the form (hidden without JavaScript, where it could do nothing), and on
// the button builds a mailto: link from the fields and opens it. Nothing leaves the
// visitor's browser except through their own email program.
(function () {
  'use strict';

  document.querySelectorAll('form[data-mail-form]').forEach(function (form) {
    var status = form.querySelector('[data-mail-form-status]');
    form.hidden = false;

    form.addEventListener('submit', function (event) {
      // The browser has already checked the required fields: an empty one stops it
      // before this runs.
      event.preventDefault();

      // The address, decoded as EmailLink decodes it (src/lib/obfuscate.ts).
      var to;
      try {
        to = atob(form.dataset.to).split('').reverse().join('');
      } catch (e) {
        return;
      }

      // The message is the letter itself. Every other field the visitor filled in
      // follows as "Label: value", so a field the owner adds later is sent too. A
      // ticked checkbox or radio button follows as its label alone.
      var details = [];
      Array.prototype.forEach.call(form.elements, function (field) {
        if (!field.name || field.name === 'message' || field.type === 'submit' || field.type === 'button') return;
        var label = field.labels && field.labels[0] ? field.labels[0].textContent.trim() : field.name;
        if (field.type === 'checkbox' || field.type === 'radio') {
          if (field.checked) details.push(label);
          return;
        }
        var value = field.tagName === 'SELECT'
          ? (field.selectedOptions[0] ? field.selectedOptions[0].text : '')
          : field.value;
        value = value.trim();
        if (value) details.push(label + ': ' + value);
      });
      var message = form.elements.message ? form.elements.message.value.trim() : '';
      var lines = [form.dataset.greeting, '', message];
      if (details.length) lines.push('', details.join('\n'));
      var body = lines.join('\n');

      // RFC 6068: a line break in a mailto: body is %0D%0A.
      var href = 'mailto:' + to
        + '?subject=' + encodeURIComponent(form.dataset.subject)
        + '&body=' + encodeURIComponent(body.replace(/\r?\n/g, '\r\n'));

      // Said before the mail program opens: whether it did, and whether the visitor
      // pressed Send there, the site never learns.
      if (status) status.textContent = status.dataset.opened;
      window.location.href = href;
    });
  });
})();
