#!/usr/bin/env node
// `npm run verify` — the one check before a pull request, and what the pre-push hook runs.
// Same checks as CI (.github/workflows/ci.yml), in one command, with short output:
//  1. `npm ci`, only when package-lock.json is new or changed since the last run here
//     (a hash in node_modules/.verify-lock-hash). Every other run keeps node_modules.
//  2. `npm run check` (astro check). Its output is shown only when it fails.
//  3. `npm test` with Playwright's dot reporter: one dot per passed test, the warnings the
//     tests print (placeholders, positioning), then each failure in full and a summary.
//     Playwright builds the site itself (webServer in playwright.config.ts), so nothing
//     here runs `npm run build` separately: one build per run, not two.
// Exit 0 only when every step is green. The pre-push hook calls this file directly
// (`node scripts/verify.mjs`), so the hook works even where package.json has no
// "verify" line; `npm run verify` needs "verify": "node scripts/verify.mjs" there.
//
// Why a Node script and not a line in package.json: npm hands a script line to sh on
// macOS and Linux and to cmd.exe on Windows, and the conditional install in step 1 is not
// something both read the same way.
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

// The site is the folder that holds scripts/, wherever this was started from.
const site = join(dirname(fileURLToPath(import.meta.url)), '..');

// Run through npm (`npm run verify`), npm_execpath names npm's own JS entry: start that
// with this node, no shell. Started directly (the hook), use the npm on PATH; on Windows
// that is npm.cmd, which Node starts only through a shell.
function npm(args, capture) {
  const opts = { cwd: site, encoding: 'utf8', stdio: capture ? ['ignore', 'pipe', 'pipe'] : 'inherit' };
  const entry = process.env.npm_execpath;
  return entry && /\.c?js$/.test(entry)
    ? spawnSync(process.execPath, [entry, ...args], opts)
    : spawnSync('npm', args, { ...opts, shell: process.platform === 'win32' });
}

// Print what a captured step wrote (it stayed hidden while the step ran), then stop.
// astro check colours its output even into a pipe; read by an assistant or a log, the
// colour codes are only noise, so they go unless a person is watching a terminal.
const plain = (text) => (process.stdout.isTTY ? text : text.replace(/\x1b\[[0-9;]*m/g, ''));
function fail(what, res, after = ' Nothing after it ran.') {
  if (res?.error) console.error(String(res.error.message || res.error));
  if (res?.stdout) process.stdout.write(plain(res.stdout));
  if (res?.stderr) process.stderr.write(plain(res.stderr));
  console.error(`✗ verify: ${what} failed (output above).${after}`);
  process.exit(1);
}

// 1. Packages. CI installs with `npm ci` from the committed lockfile, so this does too,
// but only when the lockfile differs from the one the last install here used.
const lock = join(site, 'package-lock.json');
if (!existsSync(lock)) {
  console.error('✗ verify: no package-lock.json. CI installs with `npm ci`, which needs it: run `npm install` and commit the file.');
  process.exit(1);
}
const modules = join(site, 'node_modules');
const stamp = join(modules, '.verify-lock-hash');
const want = createHash('sha256').update(readFileSync(lock)).digest('hex');
const have = existsSync(stamp) ? readFileSync(stamp, 'utf8').trim() : '';
if (want !== have) {
  console.log('▶ verify: installing the exact packages (package-lock.json is new or changed)…');
  const res = npm(['ci', '--no-audit', '--no-fund', '--loglevel=error'], true);
  if (res.error || res.status !== 0) fail('npm ci', res);
  mkdirSync(modules, { recursive: true });
  writeFileSync(stamp, want + '\n');
}

// 2. Types and templates.
const check = npm(['run', '--silent', 'check'], true);
if (check.error || check.status !== 0) fail('npm run check (astro check)', check);
console.log('✓ verify: npm run check');

// 3. Build and tests, streamed: a run takes a while and the dots show it is moving.
console.log('▶ verify: build and tests…');
const test = npm(['run', '--silent', 'test', '--', '--reporter=dot'], false);
if (test.error || test.status !== 0) fail('npm test', test.error ? test : null, '');
console.log('✓ verify: all green');
